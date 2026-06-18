#!/usr/bin/env bash
# Usage: ./run_layer2.sh cases/<case>.lp
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <case.lp>" >&2
    exit 2
fi

CASE_FILE="$1"
CASE_ID=$(basename "${CASE_FILE%.lp}")
LAYER1_JSON="results/${CASE_ID}_layer1.json"

if [ ! -f "$CASE_FILE" ]; then
    echo "Case file not found: $CASE_FILE" >&2
    exit 2
fi
if [ ! -f "$LAYER1_JSON" ]; then
    echo "Layer 1 result not found: $LAYER1_JSON" >&2
    echo "Run ./run.sh $CASE_FILE first." >&2
    exit 2
fi

python3 layer2_inject.py "$CASE_FILE" "$LAYER1_JSON"
