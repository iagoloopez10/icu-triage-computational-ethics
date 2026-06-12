#!/bin/bash

# Get the lesson root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LESSON_ROOT="$(dirname "$SCRIPT_DIR")"

# Default program
PROGRAM=("examples/01-utility-choice.lp")
EXTRA_ARGS=()
PROGRAM_SET=false

# Parse command line arguments
for arg in "$@"; do
    if [[ "$arg" == -* ]]; then
        EXTRA_ARGS+=("$arg")
    else
        if [[ "$PROGRAM_SET" == false ]]; then
            PROGRAM=("$arg")
            PROGRAM_SET=true
        else
            EXTRA_ARGS+=("$arg")
        fi
    fi
done

# Change to lesson directory
cd "$LESSON_ROOT"

docker compose run --rm clingo "${PROGRAM[@]}" --opt-mode=optN -n 0 "${EXTRA_ARGS[@]}" 
