#!/usr/bin/env bash
set -euo pipefail
for case in cases/case_*.lp; do
    echo "=== $case ==="
    ./run.sh "$case"
done
