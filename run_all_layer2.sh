#!/usr/bin/env bash
set -euo pipefail
for case in cases/case_0{1,2,3,4,5,6}_*.lp; do
    echo "=== $case ==="
    ./run_layer2.sh "$case"
done
