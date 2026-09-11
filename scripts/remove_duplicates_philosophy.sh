#!/bin/bash

# =============================================================================
# REMOVE DUPLICATE PHILOSOPHY BOOKS
# Finds and moves duplicate files to _trash folder
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PHILOSOPHY_DIR="$PROJECT_ROOT/libraria/philosophy"
TRASH_DIR="$PROJECT_ROOT/_trash"

mkdir -p "$TRASH_DIR"

echo "=========================================="
echo "REMOVING DUPLICATE PHILOSOPHY BOOKS"
echo "=========================================="
echo "Source: $PHILOSOPHY_DIR"
echo "Trash: $TRASH_DIR"
echo ""

# Create associative arrays to track files by size and name pattern
declare -A SEEN_BY_SIZE
declare -A SEEN_BY_NAME
total_files=0
duplicates=0
unique=0

# Function to normalize filename for comparison
normalize_name() {
    echo "$1" | sed 's/[^a-zA-Z0-9]//g' | tr '[:upper:]' '[:lower:]'
}

# Function to extract core book name (remove format suffix, author prefix)
extract_core_name() {
    local filename="$1"
    # Remove extension
    local name=$(basename "$filename" | sed 's/\.[^.]*$//')
    # Remove common prefixes like "Author_Name_"
    local core=$(echo "$name" | sed 's/^[A-Z][a-z]*_[A-Z][a-z]*_//' | sed 's/^[A-Z][a-z]*_//')
    echo "$core"
}

echo "Scanning files..."
echo ""

# Process all files in philosophy directory
for file in "$PHILOSOPHY_DIR"/*; do
    [ -f "$file" ] || continue

    total_files=$((total_files + 1))
    filename=$(basename "$file")
    filesize=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0")

    # Normalize for comparison
    normalized=$(normalize_name "$filename")
    core_name=$(extract_core_name "$filename")

    # Check for duplicates by size + normalized name
    key="${filesize}_${normalized}"

    if [ -n "${SEEN_BY_SIZE[$key]}" ]; then
        # Duplicate found - move to trash
        echo "[DUPLICATE] $filename"
        echo "  -> Similar to: ${SEEN_BY_SIZE[$key]}"
        mv "$file" "$TRASH_DIR/$filename"
        duplicates=$((duplicates + 1))
    else
        # Check by core name similarity
        is_duplicate=0
        for existing_core in "${SEEN_BY_NAME[@]}"; do
            if [ "$core_name" = "$existing_core" ]; then
                # Same core name, different format - keep the larger one
                existing_file="${SEEN_BY_NAME_FILE[$existing_core]}"
                existing_size=$(stat -c%s "$existing_file" 2>/dev/null || stat -f%z "$existing_file" 2>/dev/null || echo "0")

                if [ "$filesize" -lt "$existing_size" ]; then
                    echo "[DUPLICATE] $filename (smaller)"
                    echo "  -> Similar to: $existing_file"
                    mv "$file" "$TRASH_DIR/$filename"
                    duplicates=$((duplicates + 1))
                    is_duplicate=1
                    break
                else
                    echo "[DUPLICATE] $existing_file (smaller)"
                    echo "  -> Similar to: $filename"
                    mv "$existing_file" "$TRASH_DIR/$(basename "$existing_file")"
                    duplicates=$((duplicates + 1))
                    SEEN_BY_NAME["$existing_core"]="$core_name"
                    SEEN_BY_NAME_FILE["$existing_core"]="$file"
                    is_duplicate=1
                    break
                fi
            fi
        done

        if [ "$is_duplicate" -eq 0 ]; then
            SEEN_BY_SIZE["$key"]="$filename"
            SEEN_BY_NAME["$core_name"]="$core_name"
            SEEN_BY_NAME_FILE["$core_name"]="$file"
            unique=$((unique + 1))
        fi
    fi
done

echo ""
echo "=========================================="
echo "CLEANUP COMPLETE"
echo "=========================================="
echo "Total files scanned: $total_files"
echo "Duplicates moved to trash: $duplicates"
echo "Unique files remaining: $unique"
echo ""
echo "Files remaining in philosophy:"
ls -1 "$PHILOSOPHY_DIR" 2>/dev/null | wc -l
echo ""
echo "Files moved to trash:"
ls -1 "$TRASH_DIR" 2>/dev/null | wc -l

# Regenerate JSON catalog
echo ""
echo "Regenerating book catalog..."
"$SCRIPT_DIR/generate_books_json.sh"
