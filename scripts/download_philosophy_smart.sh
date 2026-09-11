#!/bin/bash

# =============================================================================
# DOWNLOAD PHILOSOPHY BOOKS - INTERNET ARCHIVE (Smart Search)
# Uses Internet Archive API to find and download philosophy books
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOWNLOAD_DIR="$PROJECT_ROOT/libraria/philosophy"

mkdir -p "$DOWNLOAD_DIR"

echo "=========================================="
echo "INTERNET ARCHIVE - SMART PHILOSOPHY DOWNLOADER"
echo "=========================================="
echo "Output: $DOWNLOAD_DIR"
echo ""

download_from_archive() {
    local identifier="$1"
    local title="$2"

    # Get file list from API
    local files_url="https://archive.org/metadata/${identifier}/files"
    local files=$(curl -s "$files_url" 2>/dev/null)

    if [ -z "$files" ]; then
        return 1
    fi

    # Find PDF or EPUB
    local download_url=""

    # Try PDF first
    local pdf_file=$(echo "$files" | jq -r '.result[]? | select(.name | test("\\.pdf$")) | .name' 2>/dev/null | head -1)
    if [ -n "$pdf_file" ]; then
        download_url="https://archive.org/download/${identifier}/${pdf_file}"
    fi

    # Try EPUB if no PDF
    if [ -z "$download_url" ]; then
        local epub_file=$(echo "$files" | jq -r '.result[]? | select(.name | test("\\.epub$")) | .name' 2>/dev/null | head -1)
        if [ -n "$epub_file" ]; then
            download_url="https://archive.org/download/${identifier}/${epub_file}"
        fi
    fi

    if [ -z "$download_url" ]; then
        return 1
    fi

    # Determine extension
    local ext="pdf"
    if echo "$download_url" | grep -qi "epub"; then
        ext="epub"
    fi

    local clean_title=$(echo "$title" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g' | head -c 80)
    local filename="${clean_title}.${ext}"

    if [ -f "$DOWNLOAD_DIR/$filename" ]; then
        echo "  -> Already exists"
        return 0
    fi

    if wget -q --timeout=30 --tries=2 -O "$DOWNLOAD_DIR/$filename" "$download_url" 2>/dev/null; then
        local size=$(stat -c%s "$DOWNLOAD_DIR/$filename" 2>/dev/null || stat -f%z "$DOWNLOAD_DIR/$filename" 2>/dev/null || echo "0")
        if [ "$size" -gt 10000 ]; then
            echo "  -> OK ($(( size / 1024 ))KB)"
            return 0
        else
            rm -f "$DOWNLOAD_DIR/$filename"
            return 1
        fi
    else
        rm -f "$DOWNLOAD_DIR/$filename"
        return 1
    fi
}

# Search and download philosophy books
search_philosophy() {
    local query="$1"
    local title="$2"

    echo "Searching: $title"

    # Search Internet Archive
    local search_url="https://archive.org/advancedsearch.php?q=${query}&fl[]=identifier,title&rows=5&output=json&sort[]=downloads+desc"
    local results=$(curl -s "$search_url" 2>/dev/null)

    if [ -z "$results" ]; then
        echo "  -> No results"
        return
    fi

    # Get first result
    local identifier=$(echo "$results" | jq -r '.response.docs[0].identifier // empty' 2>/dev/null)

    if [ -z "$identifier" ]; then
        echo "  -> No identifier found"
        return
    fi

    echo "  -> Found: $identifier"
    download_from_archive "$identifier" "$title"
    sleep 2
}

# Philosophy books to search for
echo "Searching and downloading philosophy books..."
echo ""

search_philosophy "plato+republic+philosophy" "The Republic - Plato"
search_philosophy "plato+apology+socrates" "Apology of Socrates - Plato"
search_philosophy "plato+phaedo" "Phaedo - Plato"
search_philosophy "plato+symposium" "Symposium - Plato"
search_philosophy "aristotle+nicomachean+ethics" "Nicomachean Ethics - Aristotle"
search_philosophy "aristotle+politics" "Politics - Aristotle"
search_philosophy "aristotle+poetics" "Poetics - Aristotle"
search_philosophy "marcus+aurelius+meditations" "Meditations - Marcus Aurelius"
search_philosophy "seneca+letters+stoic" "Letters from a Stoic - Seneca"
search_philosophy "seneca+shortness+life" "On the Shortness of Life - Seneca"
search_philosophy "epictetus+discourses" "Discourses - Epictetus"
search_philosophy "epictetus+enchiridion" "The Enchiridion - Epictetus"
search_philosophy "cicero+friendship" "On Friendship - Cicero"
search_philosophy "cicero+duties" "On Duties - Cicero"
search_philosophy "descartes+meditations+philosophy" "Meditations - Descartes"
search_philosophy "descartes+discourse+method" "Discourse on Method - Descartes"
search_philosophy "spinoza+ethics" "Ethics - Spinoza"
search_philosophy "kant+critique+pure+reason" "Critique of Pure Reason - Kant"
search_philosophy "schopenhauer+world+will" "The World as Will - Schopenhauer"
search_philosophy "nietzsche+thus+spake" "Thus Spake Zarathustra - Nietzsche"
search_philosophy "nietzsche+beyond+good+evil" "Beyond Good and Evil - Nietzsche"
search_philosophy "nietzsche+gay+science" "The Gay Science - Nietzsche"
search_philosophy "nietzsche+twilight+idols" "Twilight of the Idols - Nietzsche"
search_philosophy "kierkegaard+fear+trembling" "Fear and Trembling - Kierkegaard"
search_philosophy "sartre+existentialism" "Existentialism is a Humanism - Sartre"
search_philosophy "camus+myth+sisyphus" "The Myth of Sisyphus - Camus"
search_philosophy "hume+enquiry+understanding" "An Enquiry Concerning Human Understanding - Hume"
search_philosophy "locke+essay+understanding" "An Essay Concerning Human Understanding - Locke"
search_philosophy "rousseau+social+contract" "The Social Contract - Rousseau"
search_philosophy "voltaire+candide" "Candide - Voltaire"
search_philosophy "mill+on+liberty" "On Liberty - Mill"
search_philosophy "mill+utilitarianism" "Utilitarianism - Mill"
search_philosophy "russell+problems+philosophy" "The Problems of Philosophy - Russell"
search_philosophy "confucius+analects" "The Analects - Confucius"
search_philosophy "lao+tzu+tao+te+ching" "Tao Te Ching - Lao Tzu"
search_philosophy "sun+tsu+art+war" "The Art of War - Sun Tzu"
search_philosophy "augustine+confessions" "Confessions - Augustine"
search_philosophy "plotinus+enneads" "The Enneads - Plotinus"
search_philosophy "hegel+phenomenology+spirit" "Phenomenology of Spirit - Hegel"

echo ""
echo "=========================================="
echo "DOWNLOAD COMPLETE"
echo ""
echo "Files in $DOWNLOAD_DIR:"
ls -lhS "$DOWNLOAD_DIR" 2>/dev/null | head -30
echo ""
echo "Total size: $(du -sh "$DOWNLOAD_DIR" 2>/dev/null | cut -f1)"
