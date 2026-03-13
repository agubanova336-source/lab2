#!/bin/bash

CREATE=0

if [[ "$1" == "-c" ]]; then
    CREATE=1
    FILENAME="$2"
    PROGRAMNAME="$3"
else
    FILENAME="$1"
    PROGRAMNAME="$2"
fi

if [[ -z "$FILENAME" || -z "$PROGRAMNAME" ]]; then
    echo "Usage: $0 [-c] filename programname"
    exit 1
fi

if [[ -f "$PROGRAMNAME" ]]; then
    PROG_PATH="$PROGRAMNAME"
else
    PROG_PATH=$(which "$PROGRAMNAME" 2>/dev/null)
    if [[ -z "$PROG_PATH" ]]; then
        echo "Error: Program '$PROGRAMNAME' not found in system."
        exit 1
    fi
fi

if [[ $CREATE -eq 1 ]]; then
    sha512sum "$PROG_PATH" > "$FILENAME"
    echo "Reference hash for '$PROG_PATH' saved to '$FILENAME'."
else
    if [[ ! -f "$FILENAME" ]]; then
        echo "Error: Reference hash file '$FILENAME' not found."
        exit 1
    fi

    if sha512sum -c "$FILENAME" --status; then
        echo "Integrity verified. Starting '$PROGRAMNAME'..."
        "$PROG_PATH"
    else
        echo "CRITICAL ERROR: Integrity check failed! Execution aborted."
        exit 1
    fi
fi