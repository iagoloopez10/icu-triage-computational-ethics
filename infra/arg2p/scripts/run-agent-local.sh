#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LESSON_ROOT="$(dirname "$SCRIPT_DIR")"

PROGRAM="${1:-examples/01-conflicting-duties.arg2p}"
shift || true
EXTRA_ARGS=("$@")

cd "$LESSON_ROOT"

if ! command -v gradle >/dev/null 2>&1; then
    echo "gradle command not found. Install Gradle or use Docker runner ./scripts/run-agent.sh" >&2
    exit 127
fi

if [ ! -f "$PROGRAM" ]; then
    echo "Program not found: $PROGRAM" >&2
    exit 1
fi

RUNNER_PROGRAM="$PROGRAM"
if [[ "$RUNNER_PROGRAM" == examples/* ]]; then
    RUNNER_PROGRAM="../${RUNNER_PROGRAM#examples/}"
fi

ARGS=("$RUNNER_PROGRAM" "${EXTRA_ARGS[@]}")
ARGS_STRING=$(printf '%q ' "${ARGS[@]}")

gradle --no-daemon -p examples/runner run --args="$ARGS_STRING"
