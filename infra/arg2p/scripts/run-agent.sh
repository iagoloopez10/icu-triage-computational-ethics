#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LESSON_ROOT="$(dirname "$SCRIPT_DIR")"

PROGRAM="${1:-examples/01-conflicting-duties.arg2p}"
shift || true
EXTRA_ARGS=("$@")

cd "$LESSON_ROOT"

docker compose run --rm kotlin "$PROGRAM" "${EXTRA_ARGS[@]}"
