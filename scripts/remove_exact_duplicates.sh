#!/bin/bash

# =============================================================================
# REMOVE EXACT DUPLICATE FILES (by MD5 hash)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PHILOSOPHY_DIR="$PROJECT_ROOT/libraria/philosophy"
TRASH_DIR="$PROJECT_ROOT/_trash/philosophy_duplicates"

mkdir -p "$TRASH_DIR"

echo "=========================================="
echo "REMOVING EXACT DUPLICATE FILES"
echo "=========================================="
echo ""

# Calculate MD5 for all files
echo "Calculating checksums..."
cd "$PHILOSOPHY_DIR"

declare -A MD5_MAP
duplicates=0

for file in *; do
    [ -f "$file" ] || continue

    md5=$(md5sum "$file" 2>/dev/null | cut -d' ' -f1)

    if [ -n "${MD5_MAP[$md5]}" ]; then
        echo "[EXACT DUPLICATE] $file"
        echo "  -> Same as: ${MD5_MAP[$md5]}"
        mv "$file" "$TRASH_DIR/$file"
        duplicates=$((duplicates + 1))
    else
        MD5_MAP["$md5"]="$file"
    fi
done

echo ""
echo "Exact duplicates moved: $duplicates"
echo "Files remaining: $(ls -1 "$PHILOSOPHY_DIR" | wc -l)"
