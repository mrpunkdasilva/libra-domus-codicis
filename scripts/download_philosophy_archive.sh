#!/bin/bash

# =============================================================================
# DOWNLOAD PHILOSOPHY BOOKS - INTERNET ARCHIVE
# Downloads classic philosophy books from Internet Archive
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOWNLOAD_DIR="$PROJECT_ROOT/libraria/philosophy"

mkdir -p "$DOWNLOAD_DIR"

echo "=========================================="
echo "INTERNET ARCHIVE - PHILOSOPHY BOOKS"
echo "=========================================="
echo "Output: $DOWNLOAD_DIR"
echo ""

# Internet Archive identifiers for classic philosophy books
declare -A BOOKS=(
    # Nietzsche
    ["Thus Spake Zarathustra - Nietzsche"]="https://archive.org/download/thusspakezarathustra00nietz_0/thusspakezarathustra00nietz_0.pdf"
    ["Beyond Good and Evil - Nietzsche"]="https://archive.org/download/beyondgoodevil00nietz_0/beyondgoodevil00nietz_0.pdf"
    ["The Genealogy of Morals - Nietzsche"]="https://archive.org/download/genealogymorals00nietz_0/genealogymorals00nietz_0.pdf"

    # Plato
    ["The Republic - Plato"]="https://archive.org/download/republicplato00platopla_0/republicplato00platopla_0.pdf"
    ["Apology of Socrates - Plato"]="https://archive.org/download/apology00platopla_0/apology00platopla_0.pdf"
    ["Phaedo - Plato"]="https://archive.org/download/phaedopla00platopla_0/phaedopla00platopla_0.pdf"
    ["Symposium - Plato"]="https://archive.org/download/symposiumplato00plato_0/symposiumplato00plato_0.pdf"

    # Aristotle
    ["Nicomachean Ethics - Aristotle"]="https://archive.org/download/nicomacheanethics00aris_0/nicomacheanethics00aris_0.pdf"
    ["Politics - Aristotle"]="https://archive.org/download/politicsaris00arisuoft_0/politicsaris00arisuoft_0.pdf"

    # Marcus Aurelius
    ["Meditations - Marcus Aurelius"]="https://archive.org/download/meditations00marcrich_0/meditations00marcrich_0.pdf"

    # Seneca
    ["Letters from a Stoic - Seneca"]="https://archive.org/download/lettersfromst00senegood/lettersfromst00senegood.pdf"
    ["On the Shortness of Life - Seneca"]="https://archive.org/download/debrevitatev00senecuoft/debrevitatev00senecuoft.pdf"

    # Epictetus
    ["Discourses - Epictetus"]="https://archive.org/download/discourses00epic_0/discourses00epic_0.pdf"

    # Descartes
    ["Meditations - Descartes"]="https://archive.org/download/meditations01desc_0/meditations01desc_0.pdf"
    ["Discourse on Method - Descartes"]="https://archive.org/download/discourseonmeth00desc_0/discourseonmeth00desc_0.pdf"

    # Spinoza
    ["Ethics - Spinoza"]="https://archive.org/download/ethicsofpinoza00spin_0/ethicsofpinoza00spin_0.pdf"

    # Kant
    ["Critique of Pure Reason - Kant"]="https://archive.org/download/critiqueofpur00kant_0/critiqueofpur00kant_0.pdf"

    # Schopenhauer
    ["The World as Will - Schopenhauer"]="https://archive.org/download/worldaswill01sche_0/worldaswill01sche_0.pdf"

    # Confucius
    ["The Analects - Confucius"]="https://archive.org/download/analects00conf_0/analects00conf_0.pdf"

    # Lao Tzu
    ["Tao Te Ching - Lao Tzu"]="https://archive.org/download/taotechinglao00laot_0/taotechinglao00laot_0.pdf"

    # Sun Tzu
    ["The Art of War - Sun Tzu"]="https://archive.org/download/artofwar00sunt_0/artofwar00sunt_0.pdf"

    # Augustine
    ["Confessions - Augustine"]="https://archive.org/download/confessionsofst00auguw_0/confessionsofst00auguw_0.pdf"

    # Voltaire
    ["Candide - Voltaire"]="https://archive.org/download/candideoroptim00volt_0/candideoroptim00volt_0.pdf"

    # Rousseau
    ["The Social Contract - Rousseau"]="https://archive.org/download/socialcontract00rous_0/socialcontract00rous_0.pdf"

    # Mill
    ["On Liberty - Mill"]="https://archive.org/download/onliberty00mill_0/onliberty00mill_0.pdf"
    ["Utilitarianism - Mill"]="https://archive.org/download/utilitarianism00mill_0/utilitarianism00mill_0.pdf"

    # Russell
    ["Problems of Philosophy - Russell"]="https://archive.org/download/problemsofphilo00russ_0/problemsofphilo00russ_0.pdf"
)

# Download all books
total=${#BOOKS[@]}
current=0
downloaded=0
failed=0

echo "Total books to download: $total"
echo ""

for title in "${!BOOKS[@]}"; do
    current=$((current + 1))
    url="${BOOKS[$title]}"

    # Create filename from title
    filename=$(echo "$title" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g')
    filename="${filename}.pdf"

    echo "[$current/$total] Downloading: $title"

    if [ -f "$DOWNLOAD_DIR/$filename" ]; then
        echo "  -> Already exists, skipping"
        downloaded=$((downloaded + 1))
        continue
    fi

    if wget -q --timeout=30 --tries=2 -O "$DOWNLOAD_DIR/$filename" "$url" 2>/dev/null; then
        # Verify file size
        size=$(stat -c%s "$DOWNLOAD_DIR/$filename" 2>/dev/null || stat -f%z "$DOWNLOAD_DIR/$filename" 2>/dev/null || echo "0")
        if [ "$size" -gt 10000 ]; then
            echo "  -> OK ($(( size / 1024 ))KB)"
            downloaded=$((downloaded + 1))
        else
            echo "  -> Failed (file too small), removing"
            rm -f "$DOWNLOAD_DIR/$filename"
            failed=$((failed + 1))
        fi
    else
        echo "  -> Failed to download"
        rm -f "$DOWNLOAD_DIR/$filename"
        failed=$((failed + 1))
    fi

    # Rate limiting
    sleep 2
done

echo ""
echo "=========================================="
echo "DOWNLOAD COMPLETE"
echo "=========================================="
echo "Downloaded: $downloaded"
echo "Failed: $failed"
echo "Total: $total"
echo ""
echo "Files in $DOWNLOAD_DIR:"
ls -lhS "$DOWNLOAD_DIR" 2>/dev/null | head -20
echo ""
echo "Total size: $(du -sh "$DOWNLOAD_DIR" 2>/dev/null | cut -f1)"
