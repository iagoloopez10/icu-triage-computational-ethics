# ICU Triage Decision Support — Computational Ethics 2026

A hybrid decision-support system for ICU ventilator triage that combines
consequentialist optimization (ASP/Clingo) with argumentative ethical
audit (Arg2P).

Course project for Computational Ethics 2026, Università di Bologna.

## Overview

The system is split into two independent layers:

- **Layer 1 — Operational decision (Clingo).** A lexicographic
  optimization in Answer Set Programming. Maximises lives saved, then
  life-years, then QALYs, subject to a hard IDSA clinical eligibility
  floor. Resolves remaining ties by reproducible lottery.
- **Layer 2 — Ethical audit (Arg2P).** A defeasible argumentation
  theory based on W.D. Ross's prima facie duties (non-maleficence,
  beneficence, fidelity, justice, gratitude). Audits Layer 1's
  decision and returns a verdict: `defensible`, `indefensible`, or
  `undecided`.

The two layers communicate only through a stable JSON artifact:
Layer 1 emits its decision, Layer 2 reads it and the original case
file. This preserves Layer 2's role as a genuine independent auditor
rather than a post-hoc explainer.

## Project layout

```
icu-triage-computational-ethics/
├── cases/                     # Canonical case definitions
├── engine/                    # Core logic for both layers
│   ├── rules.lp               # Layer 1 — ASP rules
│   └── layer2.arg2p           # Layer 2 — Arg2P ethical theory
├── infra/                     # Course-provided execution infrastructure
│   ├── clingo/                # Docker + scripts for Clingo
│   └── arg2p/                 # Docker + scripts + Kotlin runner for Arg2P-KT
├── report/                    # Final Project report 
├── results/                   # Generated outputs from both layers
├── run.sh                     # Layer 1 — run a single case
├── run_all.sh                 # Layer 1 — batch over all cases
├── emit_result.py             # Layer 1 — parses Clingo output, emits JSON
├── run_layer2.sh              # Layer 2 — run a single case
├── run_all_layer2.sh          # Layer 2 — batch over the six canonical cases
└── layer2_inject.py           # Layer 2 — generates dynamic .arg2p, invokes Arg2P-KT, emits JSON
```

### `cases/`

Seven canonical case definitions, each isolating a distinct ethical
conflict (withdrawal of treatment, third-party duty toward a fetus,
QALY-based disability discrimination, pure clinical tie, healthcare
worker priority, extreme scarcity, plus a smoketest). Each case has
two files: a `.lp` with the Prolog/ASP facts consumed by both layers,
and a `.json` with metadata (description, lottery seed, expected
outcomes for documentation).

### `engine/`

The intellectual core of the project. Two files, one per layer:

- **`rules.lp`** — Layer 1's ASP encoding. Contains three components:
  (1) the three-level utilitarian hierarchy that determines how to
  optimise (`@3 lives > @2 life_years > @1 QALYs`), (2) the binary
  IDSA clinical filter that excludes ineligible patients before
  optimisation, and (3) the rule that detects when Layer 1 withdraws
  ventilation from a previously assigned patient.
- **`layer2.arg2p`** — Layer 2's argumentation theory. Ten defeasible
  rules organised by Rossian duty, seven attack-bridge rules, two
  undercuts against procedural justice, and two preferences (the only
  ethical hierarchies the system commits to).

### `infra/` — Course-provided infrastructure

**This directory contains materials provided by Prof. G. Pisano for
the Computational Ethics 2026 course, reused.** It is the
only part of the repository not authored by the author (Iago Lopez Lamas). Its
purpose is to make the project runnable on any machine with Docker
without manual installation of Clingo or the JVM.

- `infra/clingo/` — Docker image and shell scripts (`run-agent.sh`,
  `run-agent-local.sh`, plus PowerShell equivalents) for running
  Clingo inside a container. Used implicitly by Layer 1.
- `infra/arg2p/` — Docker Compose definition, Kotlin Dockerfile, shell
  scripts, and the Kotlin runner that loads a `.arg2p` file and
  invokes Arg2P-KT 0.15.0 under grounded semantics. Used by Layer 2.

### `results/`

Generated artifacts. Each case produces two JSONs:

- `case_XX_layer1.json` — Layer 1's decision: assigned and withdrawn
  pairs, objective values, the full set of tied optimal models, the
  lottery seed and selected index. This is the "clinical record"
  Layer 2 audits.
- `case_XX_layer2.json` — Layer 2's ethical verdict: which duties are
  IN, OUT, or UNDEC under grounded semantics, mapped to the rules of
  Table A, plus the raw labelling for traceability.

### Top-level scripts

Two parallel pipelines, one per layer. The symmetry is deliberate —
it reflects the architectural independence of the two layers.

**Layer 1 pipeline:**

- `run.sh` — orchestrates a single case. Invokes Clingo on
  `engine/rules.lp` and the given case, captures stdout, handles
  Clingo's non-standard exit codes (10/20/30), and passes the output
  to `emit_result.py`.
- `run_all.sh` — iterates over all `cases/case_*.lp`.
- `emit_result.py` — parses Clingo's enumeration of optimal models,
  identifies the models tied at the final optimum, applies the
  reproducible lottery (`random.seed(seed); random.choice(tied)`),
  and writes the canonical Layer 1 JSON.

**Layer 2 pipeline:**

- `run_layer2.sh` — orchestrates a single case. Requires both the
  case `.lp` and the corresponding Layer 1 JSON.
- `run_all_layer2.sh` — iterates over the six canonical cases
  (`case_01` to `case_06`); the smoketest is intentionally excluded.
- `layer2_inject.py` — the heart of Layer 2's operational logic.
  Five responsibilities:
  1. Parses facts from the case `.lp`.
  2. Reads Layer 1's JSON to extract the decision.
  3. Pre-computes ground flags (`qaly_decisive`,
     `best_life_years_assigned`, `gestational_24_plus`, etc.) that
     the Arg2P-KT engine cannot compute due to its lack of
     arithmetic and negation-as-failure within rules.
  4. Concatenates the static rules from `engine/layer2.arg2p` with
     the case facts and the pre-computed flags into a self-contained
     `.arg2p` file, then invokes Arg2P-KT via Docker.
  5. Parses the labelling, maps each conclusion to its Table A rule,
     applies the verdict formula, and writes the canonical Layer 2
     JSON.

### `report/`

The final report defending the architecture, the ethical commitments,
and the design decisions of both layers.

## Requirements

- Docker with Compose support (for both Clingo and Arg2P-KT)
- Python 3.11+
- Clingo 5.6.2 on the host (used by `run.sh` natively for speed; the
  Docker image in `infra/clingo/` is available as fallback)

## How to run

Layer 1 — one case:
```bash
./run.sh cases/case_03_disability.lp
```

Layer 1 — all cases:
```bash
./run_all.sh
```

Layer 2 — one case (Layer 1 result must exist first):
```bash
./run_layer2.sh cases/case_03_disability.lp
```

Layer 2 — all six canonical cases:
```bash
./run_all_layer2.sh
```

## Acknowledgements

The execution infrastructure under `infra/clingo/` and `infra/arg2p/` is
derived from materials provided by Prof. G. Pisano for the
Computational Ethics 2026 course. The directory layout under `infra/`
follows the structure of the course's lesson examples; the runner was
relocated within `infra/arg2p/` to match the expected path of the
course-provided shell scripts, with no modification to file contents.