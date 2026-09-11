#!/bin/bash

# =============================================================================
# REMOVE SIMILAR DUPLICATE BOOKS (same book, different formats/versions)
# Keeps the largest/best quality version
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PHILOSOPHY_DIR="$PROJECT_ROOT/libraria/philosophy"
TRASH_DIR="$PROJECT_ROOT/_trash/philosophy_duplicates"

mkdir -p "$TRASH_DIR"

echo "=========================================="
echo "REMOVING SIMILAR DUPLICATE BOOKS"
echo "=========================================="
echo ""

# Function to extract book identifier
get_book_id() {
    local filename="$1"
    # Remove extension and normalize
    echo "$filename" | \
        sed 's/\.[^.]*$//' | \
        sed 's/_[Pp][Dd][Ff]$//' | \
        sed 's/_[Ee][Pp][Uu][Bb]$//' | \
        sed 's/_librivox$//' | \
        sed 's/_gutenberg$//' | \
        sed 's/-/ /g' | \
        sed 's/_/ /g' | \
        sed 's/  */ /g' | \
        tr '[:upper:]' '[:lower:]'
}

cd "$PHILOSOPHY_DIR"

declare -A BOOKS_BY_ID
duplicates=0

echo "Analyzing books..."

for file in *; do
    [ -f "$file" ] || continue

    book_id=$(get_book_id "$file")
    filesize=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")

    if [ -n "${BOOKS_BY_ID[$book_id]}" ]; then
        # Found similar book
        existing_file="${BOOKS_BY_ID[$book_id]}"
        existing_size=$(stat -c%s "$existing_file" 2>/dev/null || stat -f%z "$existing_file" 2>/dev/null || echo "0")

        if [ "$filesize" -lt "$existing_size" ]; then
            echo "[SIMILAR] $file (smaller: $((filesize/1024))KB)"
            echo "  -> Keeping: $existing_file ($((existing_size/1024))KB)"
            mv "$file" "$TRASH_DIR/$file"
            duplicates=$((duplicates + 1))
        else
            echo "[SIMILAR] $existing_file (smaller: $((existing_size/1024))KB)"
            echo "  -> Keeping: $file ($((filesize/1024))KB)"
            mv "$existing_file" "$TRASH_DIR/$existing_file"
            BOOKS_BY_ID["$book_id"]="$file"
            duplicates=$((duplicates + 1))
        fi
    else
        BOOKS_BY_ID["$book_id"]="$file"
    fi
done

echo ""
echo "=========================================="
echo "CLEANUP COMPLETE"
echo "=========================================="
echo "Similar duplicates moved: $duplicates"
echo "Files remaining: $(ls -1 "$PHILOSOPHY_DIR" | wc -l)"
echo ""
echo "Total size remaining:"
du -sh "$PHILOSOPHY_DIR"
