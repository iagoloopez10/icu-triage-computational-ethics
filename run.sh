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
        SEED=$(grep -oP '"lottery_seed"\s*:\s*\K\d+' "$JSON_FILE" || echo "42")
    else
        SEED=42
    fi
fi

OUTPUT=$(clingo --opt-mode=optN --models 0 engine/rules.lp "$CASE_FILE") || true

echo "=== Engine output ==="
echo "$OUTPUT"
echo

OPTIMAL=$(echo "$OUTPUT" | grep -oP 'Optimal\s*:\s*\K\d+' || echo "")
if [ -z "$OPTIMAL" ]; then
    if echo "$OUTPUT" | grep -q "OPTIMUM FOUND"; then
        OPTIMAL=1
    else
        echo "No optimum found." >&2
        exit 3
    fi
fi

# Extract every "Answer:" block's payload (concatenated until "Optimization:")
MODELS=$(echo "$OUTPUT" | awk '
    /^Answer:/ { capture=1; payload=""; next }
    /^Optimization:/ { if (capture) { print payload; capture=0 } next }
    capture { payload = payload " " $0 }
')

# Take the last $OPTIMAL models (those sharing the final optimum)
OPTIMAL_MODELS=$(echo "$MODELS" | tail -n "$OPTIMAL")

# Seeded random selection via Python (more reliable than shuf for seeding)
SELECTED=$(echo "$OPTIMAL_MODELS" | python3 -c "
import sys, random
models = [l.strip() for l in sys.stdin if l.strip()]
random.seed($SEED)
print(random.choice(models))
")

echo "=== Lottery (seed=$SEED, $OPTIMAL tied model(s)) ==="
echo "Selected: $SELECTED"
