#!/bin/bash

CREATE=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c) CREATE=1; shift ;;
        -d) DIRNAME="$2"; shift 2 ;;
        -f) FILENAME="$2"; shift 2 ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
done

if [[ -z "$DIRNAME" || -z "$FILENAME" ]]; then
    echo "Usage: $0 [-c] -d dirname -f filename"
    exit 1
fi

if [[ ! -d "$DIRNAME" ]]; then
    echo "Error: Directory '$DIRNAME' does not exist."
    exit 1
fi

if [[ $CREATE -eq 1 ]]; then
    find "$DIRNAME" -type f -exec md5sum {} + > "$FILENAME"
    echo "Hash file '$FILENAME' created successfully."
else
    if [[ ! -f "$FILENAME" ]]; then
        echo "Error: Hash file '$FILENAME' not found."
        exit 1
    fi

    echo "=== Checking modified files (md5sum) ==="
    md5sum -c "$FILENAME" --quiet

    echo "=== Checking deleted files ==="
    sed 's/^[0-9a-f]* [ \*]//' "$FILENAME" | while read -r file; do
        if [[ ! -f "$file" ]]; then
            echo "DELETED: $file"
        fi
    done

    echo "=== Checking new files ==="
    find "$DIRNAME" -type f | while read -r file; do
        if ! grep -qF "$file" "$FILENAME"; then
            if [[ "$(realpath "$file")" != "$(realpath "$FILENAME")" ]]; then
                echo "NEW FILE: $file"
            fi
        fi
    done
fi