#!/usr/bin/env bash
# Usage: ./run.sh cases/<case>.lp [seed]
# Default seed: 42. Reads lottery_seed from cases/<case>.json if present
# and no seed is given on the command line.

set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <case.lp> [seed]" >&2
    exit 2
fi

CASE_FILE="$1"
if [ ! -f "$CASE_FILE" ]; then
    echo "Case file not found: $CASE_FILE" >&2
    exit 2
fi

# Resolve seed: CLI arg > JSON metadata > default 42
if [ $# -ge 2 ]; then
    SEED="$2"
else
    JSON_FILE="${CASE_FILE%.lp}.json"
    if [ -f "$JSON_FILE" ]; then
        SEED=$(python3 -c "import json; print(json.load(open('$JSON_FILE')).get('lottery_seed', 42))")
    else
        SEED=42
    fi
fi

CLINGO_EXIT=0
OUTPUT=$(clingo --opt-mode=optN --models 0 engine/rules.lp "$CASE_FILE") || CLINGO_EXIT=$?

case $CLINGO_EXIT in
    10|30) ;;
    20)
        echo "clingo: UNSATISFIABLE — no feasible assignment for $CASE_FILE" >&2
        exit 3
        ;;
    *)
        echo "clingo: unexpected exit code $CLINGO_EXIT (expected 10/20/30)" >&2
        exit 4
        ;;
esac

echo "=== Engine output ==="
echo "$OUTPUT"
echo

CASE_ID=$(basename "${CASE_FILE%.lp}")

echo "$OUTPUT" | python3 emit_result.py \
    --case-id "$CASE_ID" \
    --rules-file "engine/rules.lp" \
    --case-file "$CASE_FILE" \
    --seed "$SEED"
