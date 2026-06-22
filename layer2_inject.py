#!/usr/bin/env python3
"""
Layer 2 runner: precomputes ground flags from case .lp + layer1 JSON,
generates a self-contained .arg2p, invokes Arg2P-KT, parses labelling,
and writes results/case_XX_layer2.json.
"""
import sys
import re
import json
import subprocess
import argparse
from pathlib import Path

# ── PREDICATES FORWARDED FROM .lp ────────────────────────────────────────────
LP_PREDICATES = {
    "disability_permanent",
    "healthcare_worker", "gestational_weeks",
    "instrumental_lives_factor", "survival_prob_pct",
    "life_expectancy_years",
}

INFRA_DIR = Path(__file__).parent / "infra" / "arg2p"
ENGINE_FILE = Path(__file__).parent / "engine" / "layer2.arg2p"
RESULTS_DIR = Path(__file__).parent / "results"


def parse_lp(text):
    """Return dict[predicate -> list[list[str]]]. Handles multiple facts per line."""
    facts = {}
    for line in text.splitlines():
        line = line.split("%")[0].strip()  # strip comments
        if not line:
            continue
        for m in re.finditer(r'(\w+)\(([^)]+)\)', line):
            pred = m.group(1)
            args = [a.strip() for a in m.group(2).split(",")]
            facts.setdefault(pred, []).append(args)
    return facts


def fact_name(pred, args):
    safe = re.sub(r'[^a-z0-9]', '_', f"{pred}_{'_'.join(args)}")
    return f"f_{safe}"


def emit_fact(pred, args):
    if args:
        atom = f"{pred}({','.join(args)})"
    else:
        atom = pred
    return f"{fact_name(pred, args)} :=> {atom}."


def compute_flags(lp_facts, layer1):
    assigned_pairs  = [(p, v) for p, v in layer1["assigned"]]
    withdrawn_pairs = [(p, v) for p, v in layer1["withdrawn"]]
    assigned_pts    = {p for p, _ in assigned_pairs}
    all_pts         = {row[0] for row in lp_facts.get("patient", [])}
    idsa_pts        = {row[0] for row in lp_facts.get("idsa_eligible", [])}

    surv    = {row[0]: int(row[1]) for row in lp_facts.get("survival_prob_pct", [])}
    life_ex = {row[0]: int(row[1]) for row in lp_facts.get("life_expectancy_years", [])}

    lines = []

    # assigned_in_layer1 / withdrawn_in_layer1
    for p, v in assigned_pairs:
        lines.append(emit_fact("assigned_in_layer1", [p, v]))
    for p, v in withdrawn_pairs:
        lines.append(emit_fact("withdrawn_in_layer1", [p, v]))

    # not_assigned_in_layer1(P)
    for p in sorted(all_pts - assigned_pts):
        lines.append(emit_fact("not_assigned_in_layer1", [p]))

    # tied_optimal_gt1  (ground atom, no args)
    if layer1.get("n_tied_optimal_models", 1) > 1:
        lines.append("f_tied_optimal_gt1 :=> tied_optimal_gt1.")

    # instrument_factor_gt1(P)
    for row in lp_facts.get("instrumental_lives_factor", []):
        if int(row[1]) > 1:
            lines.append(emit_fact("instrument_factor_gt1", [row[0]]))

    # gestational_24_plus(P)
    for row in lp_facts.get("gestational_weeks", []):
        if int(row[1]) >= 24:
            lines.append(emit_fact("gestational_24_plus", [row[0]]))

    # best_life_years_assigned(P)
    # life_years_score = survival_prob_pct * life_expectancy_years
    scores = {p: surv.get(p, 0) * life_ex.get(p, 0) for p in idsa_pts}
    max_score = max(scores.values()) if scores else 0
    for p in sorted(assigned_pts):
        if scores.get(p, 0) >= max_score:
            lines.append(emit_fact("best_life_years_assigned", [p]))

    # qaly_decisive(P): P not assigned, ∃ Q assigned with same surv+life_exp
    not_assigned = all_pts - assigned_pts
    for p in sorted(not_assigned):
        for q in sorted(assigned_pts):
            if p != q and surv.get(p) == surv.get(q) and life_ex.get(p) == life_ex.get(q):
                lines.append(emit_fact("qaly_decisive", [p]))
                break  # one match is enough per P

    return lines


def generate_arg2p(lp_facts, flag_lines):
    parts = []

    # Static engine rules
    parts.append(ENGINE_FILE.read_text())
    parts.append("")

    # LP facts relevant to Layer 2
    parts.append("% ── HECHOS DEL CASO (.lp) ──")
    for pred in sorted(LP_PREDICATES):
        for row in lp_facts.get(pred, []):
            parts.append(emit_fact(pred, row))

    parts.append("")
    parts.append("% ── FLAGS PRECOMPUTADOS ──")
    parts.extend(flag_lines)

    return "\n".join(parts) + "\n"


def parse_labelling(output):
    entries = []
    for line in output.splitlines():
        m = re.match(r"^(in|out|undec|und)\s+->\s+(.+)$", line.strip())
        if m:
            label = "undec" if m.group(1) == "und" else m.group(1)
            entries.append({"label": label, "conclusion": m.group(2)})
    return entries


# Maps positive conclusion predicate → rule ID
CONCLUSION_TO_RULE = {
    "violates_fidelity":            "F1",
    "active_harm":                  "NM1",
    "discriminatory_exclusion":     "NM2",
    "unjust_exclusion":             "J1",
    "procedural_fairness":          "J2",
    "violates_equal_consideration": "J3",
    "serves_individual_beneficence":"B1",
    "serves_aggregate_beneficence": "B2",
    "unattended_third_party":       "B3",
    "merits_gratitude":             "G1",
}

PRO_RULES    = {"B1", "B2", "G1", "J2"}
CONTRA_RULES = {"F1", "NM1", "NM2", "J1", "J3", "B3"}


def map_labelling(entries):
    rule_labels = {}  # rule_id -> label

    for e in entries:
        conc = e["conclusion"]
        # Skip bridge-rule negated conclusions: '-'(X)
        if conc.startswith("'-'(") or conc.startswith("'\\+'"):
            continue
        # Extract predicate name
        m = re.match(r"^([a-z_]+)(?:\(.*\))?$", conc)
        if not m:
            continue
        pred = m.group(1)
        rule = CONCLUSION_TO_RULE.get(pred)
        if rule is None:
            continue
        # A rule may fire for multiple patients; take the "worst" label
        # priority: in > undec > out (in beats out for contra; use in over undec)
        existing = rule_labels.get(rule)
        new_label = e["label"]
        if existing is None:
            rule_labels[rule] = new_label
        else:
            priority = {"in": 2, "undec": 1, "out": 0}
            if priority[new_label] > priority[existing]:
                rule_labels[rule] = new_label

    return rule_labels


def compute_verdict(rule_labels):
    contra_built = {r for r in CONTRA_RULES if r in rule_labels}
    contra_in    = {r for r in CONTRA_RULES if rule_labels.get(r) == "in"}
    pro_built    = {r for r in PRO_RULES    if r in rule_labels}
    pro_out      = {r for r in PRO_RULES    if rule_labels.get(r) == "out"}

    if not contra_built:
        return "defensible"
    if contra_in and pro_built.issubset(pro_out):
        return "indefensible"
    return "undecided"


def build_result(case_id, verdict, rule_labels, raw_entries):
    def ids_by_label(rule_set, label):
        return sorted(r for r in rule_set if rule_labels.get(r) == label)

    return {
        "case_id": case_id,
        "verdict": verdict,
        "semantics": "grounded",
        "pro_rules_in":    ids_by_label(PRO_RULES,    "in"),
        "pro_rules_out":   ids_by_label(PRO_RULES,    "out"),
        "pro_rules_undec": ids_by_label(PRO_RULES,    "undec"),
        "contra_rules_in":    ids_by_label(CONTRA_RULES, "in"),
        "contra_rules_out":   ids_by_label(CONTRA_RULES, "out"),
        "contra_rules_undec": ids_by_label(CONTRA_RULES, "undec"),
        "labelling_raw": raw_entries,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("case_lp")
    ap.add_argument("layer1_json")
    args = ap.parse_args()

    lp_text  = Path(args.case_lp).read_text()
    layer1   = json.loads(Path(args.layer1_json).read_text())
    case_id  = layer1["case_id"]

    lp_facts  = parse_lp(lp_text)
    flag_lines = compute_flags(lp_facts, layer1)

    arg2p_src = generate_arg2p(lp_facts, flag_lines)

    # Write generated .arg2p into infra/arg2p/examples/ for docker volume access
    gen_name = f"layer2_{case_id}.arg2p"
    gen_path = INFRA_DIR / "examples" / gen_name
    gen_path.write_text(arg2p_src)

    print(f"Generated: {gen_path}", file=sys.stderr)

    # Run Arg2P-KT via Docker
    result = subprocess.run(
        ["docker", "compose", "run", "--rm", "kotlin", f"examples/{gen_name}"],
        cwd=INFRA_DIR,
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print("Docker run failed:", result.stderr, file=sys.stderr)
        sys.exit(1)

    raw_output = result.stdout
    print(raw_output)

    raw_entries = parse_labelling(raw_output)
    rule_labels = map_labelling(raw_entries)
    verdict     = compute_verdict(rule_labels)
    out         = build_result(case_id, verdict, rule_labels, raw_entries)

    RESULTS_DIR.mkdir(exist_ok=True)
    out_path = RESULTS_DIR / f"{case_id}_layer2.json"
    out_path.write_text(json.dumps(out, indent=2) + "\n")
    print(f"Written: {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
