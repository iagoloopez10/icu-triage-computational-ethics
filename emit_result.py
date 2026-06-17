#!/usr/bin/env python3
import sys
import re
import json
import random
import argparse
from pathlib import Path


def parse_atoms(line):
    assigned = []
    withdrawn = []
    for atom in line.split():
        m = re.match(r'assign\((\w+),(\w+)\)', atom)
        if m:
            assigned.append([m.group(1), m.group(2)])
        m = re.match(r'withdrawal\((\w+),(\w+)\)', atom)
        if m:
            withdrawn.append([m.group(1), m.group(2)])
    return assigned, withdrawn


def parse_clingo_output(text):
    models = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if re.match(r'^Answer:\s*\d+$', line):
            i += 1
            atoms_line = lines[i].strip() if i < len(lines) else ""
            assigned, withdrawn = parse_atoms(atoms_line)
            i += 1
            opt = None
            if i < len(lines) and lines[i].strip().startswith("Optimization:"):
                # per-model line: "Optimization: V1 V2 V3" (no space before colon)
                parts = lines[i].strip().split()
                opt = tuple(int(v) for v in parts[1:])
            else:
                i -= 1
            models.append({"assigned": assigned, "withdrawn": withdrawn, "opt": opt})
        i += 1
    return models


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--case-id", required=True)
    p.add_argument("--rules-file", required=True)
    p.add_argument("--case-file", required=True)
    p.add_argument("--seed", type=int, required=True)
    args = p.parse_args()

    text = sys.stdin.read()
    models = parse_clingo_output(text)

    # "  Optimal    : N" appears in summary only when N > 1; absent means 1
    m = re.search(r'^\s+Optimal\s*:\s*(\d+)', text, re.MULTILINE)
    n_optimal = int(m.group(1)) if m else 1

    # Summary line has a space before the colon: "Optimization : V1 V2 V3"
    # Per-model lines have no space: "Optimization: V1 V2 V3" — distinct patterns
    m = re.search(r'^Optimization\s+:\s+(.+)', text, re.MULTILINE)
    opt_vals = tuple(int(v) for v in m.group(1).split())
    # clingo internally minimizes negated maximize values; negate to recover actuals
    lives, life_years, qalys = -opt_vals[0], -opt_vals[1], -opt_vals[2]

    # Last n_optimal models are the unique tied optima from phase-2 enumeration
    tied = models[-n_optimal:]

    random.seed(args.seed)
    selected = random.choice(tied)
    selected_index = next(i for i, mdl in enumerate(tied) if mdl is selected)

    print(f"=== Lottery (seed={args.seed}, {n_optimal} tied model(s)) ===")
    print(f"Selected: {selected['assigned']}")

    result = {
        "case_id": args.case_id,
        "engine": "clingo-5.6.2",
        "rules_file": args.rules_file,
        "case_file": args.case_file,
        "seed": args.seed,
        "objective_values": {"lives": lives, "life_years": life_years, "qalys": qalys},
        "n_tied_optimal_models": n_optimal,
        "selected_model_index": selected_index,
        "assigned": selected["assigned"],
        "withdrawn": selected["withdrawn"],
        "all_tied_optimal_models": [
            {"assigned": mdl["assigned"], "withdrawn": mdl["withdrawn"]}
            for mdl in tied
        ],
    }

    out_dir = Path("results")
    out_dir.mkdir(exist_ok=True)
    out_path = out_dir / f"{args.case_id}_layer1.json"
    out_path.write_text(json.dumps(result, indent=2) + "\n")
    print(f"Written: {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
