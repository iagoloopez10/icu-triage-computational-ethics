# ICU Triage Decision Support — Computational Ethics 2026

A hybrid decision-support system for ICU triage that combines
consequentialist optimization (ASP/Clingo) with argumentative
audit (Arg2P).

Course project for Computational Ethics 2026, Università di Bologna.
Supervisor: Prof. G. Pisano.

## Status

Work in progress.

## Project layout

- `engine/` — Core logic (ASP rules, Arg2P theory)
- `cases/` — Canonical case definitions
- `runner/` — Python orchestrator
- `infra/` — Course-provided Docker infrastructure (see attribution)
- `report/` — Project report
- `results/` — Generated outputs

## Requirements

- Docker with Compose support
- Python 3.11+

## Acknowledgements

The execution infrastructure under `infra/clingo/` and `infra/arg2p/` is
derived from materials provided by Prof. G. Pisano for the Computational
Ethics 2026 course. See `infra/README_ATTRIBUTION.md`.

