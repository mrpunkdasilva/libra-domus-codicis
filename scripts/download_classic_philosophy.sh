#!/bin/bash

# =============================================================================
# DOWNLOAD CLASSIC PHILOSOPHY BOOKS - GUTENDEX API
# Downloads classic philosophy books from Project Gutenberg via Gutendex
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOWNLOAD_DIR="$PROJECT_ROOT/libraria/philosophy"

mkdir -p "$DOWNLOAD_DIR"

echo "=========================================="
echo "CLASSIC PHILOSOPHY BOOKS DOWNLOADER"
echo "=========================================="
echo "Output: $DOWNLOAD_DIR"
echo ""

# Classic philosophy books with their Gutenberg IDs and direct download URLs
declare -A BOOKS=(
    # Nietzsche
    ["Thus Spake Zarathustra - Nietzsche"]="https://www.gutenberg.org/cache/epub/1998/pg1998.epub"
    ["Beyond Good and Evil - Nietzsche"]="https://www.gutenberg.org/cache/epub/4363/pg4363.epub"
    ["The Gay Science - Nietzsche"]="https://www.gutenberg.org/cache/epub/5231/pg5231.epub"
    ["Twilight of the Idols - Nietzsche"]="https://www.gutenberg.org/cache/epub/5229/pg5229.epub"
    ["The Antichrist - Nietzsche"]="https://www.gutenberg.org/cache/epub/17988/pg17988.epub"
    ["On the Genealogy of Morals - Nietzsche"]="https://www.gutenberg.org/cache/epub/5233/pg5233.epub"

    # Plato
    ["The Republic - Plato"]="https://www.gutenberg.org/cache/epub/1497/pg1497.epub"
    ["Apology - Plato"]="https://www.gutenberg.org/cache/epub/1656/pg1656.epub"
    ["Phaedo - Plato"]="https://www.gutenberg.org/cache/epub/1659/pg1659.epub"
    ["Symposium - Plato"]="https://www.gutenberg.org/cache/epub/1600/pg1600.epub"
    ["Crito - Plato"]="https://www.gutenberg.org/cache/epub/1657/pg1657.epub"
    ["Phaedrus - Plato"]="https://www.gutenberg.org/cache/epub/1636/pg1636.epub"

    # Aristotle
    ["Nicomachean Ethics - Aristotle"]="https://www.gutenberg.org/cache/epub/8438/pg8438.epub"
    ["Politics - Aristotle"]="https://www.gutenberg.org/cache/epub/2412/pg2412.epub"
    ["Poetics - Aristotle"]="https://www.gutenberg.org/cache/epub/1972/pg1972.epub"

    # Marcus Aurelius
    ["Meditations - Marcus Aurelius"]="https://www.gutenberg.org/cache/epub/2680/pg2680.epub"

    # Epictetus
    ["Discourses - Epictetus"]="https://www.gutenberg.org/cache/epub/50408/pg50408.epub"
    ["The Enchiridion - Epictetus"]="https://www.gutenberg.org/cache/epub/50409/pg50409.epub"

    # Seneca
    ["On the Shortness of Life - Seneca"]="https://www.gutenberg.org/cache/epub/37847/pg37847.epub"
    ["Letters from a Stoic - Seneca"]="https://www.gutenberg.org/cache/epub/1041/pg1041.epub"
    ["Dialogues - Seneca"]="https://www.gutenberg.org/cache/epub/43296/pg43296.epub"

    # Cicero
    ["On Duties - Cicero"]="https://www.gutenberg.org/cache/epub/43296/pg43296.epub"
    ["On Friendship - Cicero"]="https://www.gutenberg.org/cache/epub/13942/pg13942.epub"
    ["On Old Age - Cicero"]="https://www.gutenberg.org/cache/epub/13943/pg13943.epub"

    # Descartes
    ["Meditations on First Philosophy - Descartes"]="https://www.gutenberg.org/cache/epub/59/pg59.epub"
    ["Discourse on Method - Descartes"]="https://www.gutenberg.org/cache/epub/59/pg59.epub"

    # Spinoza
    ["Ethics - Spinoza"]="https://www.gutenberg.org/cache/epub/10027/pg10027.epub"
    ["Theologico-Political Treatise - Spinoza"]="https://www.gutenberg.org/cache/epub/6486/pg6486.epub"

    # Kant
    ["Critique of Pure Reason - Kant"]="https://www.gutenberg.org/cache/epub/4217/pg4217.epub"
    ["Fundamental Principles of the Metaphysic of Morals - Kant"]="https://www.gutenberg.org/cache/epub/5684/pg5684.epub"

    # Hume
    ["An Enquiry Concerning Human Understanding - Hume"]="https://www.gutenberg.org/cache/epub/9662/pg9662.epub"
    ["Dialogues Concerning Natural Religion - Hume"]="https://www.gutenberg.org/cache/epub/4583/pg4583.epub"

    # Locke
    ["An Essay Concerning Human Understanding - Locke"]="https://www.gutenberg.org/cache/epub/10614/pg10614.epub"
    ["Two Treatises of Government - Locke"]="https://www.gutenberg.org/cache/epub/7370/pg7370.epub"

    # Schopenhauer
    ["The World as Will and Representation - Schopenhauer"]="https://www.gutenberg.org/cache/epub/10115/pg10115.epub"
    ["Studies in Pessimism - Schopenhauer"]="https://www.gutenberg.org/cache/epub/37044/pg37044.epub"

    # Kierkegaard
    ["Fear and Trembling - Kierkegaard"]="https://www.gutenberg.org/cache/epub/18009/pg18009.epub"
    ["The Sickness Unto Death - Kierkegaard"]="https://www.gutenberg.org/cache/epub/24310/pg24310.epub"

    # Sartre
    ["Existentialism is a Humanism - Sartre"]="https://www.gutenberg.org/cache/epub/30791/pg30791.epub"
    ["Nausea - Sartre"]="https://www.gutenberg.org/cache/epub/30791/pg30791.epub"

    # Camus
    ["The Myth of Sisyphus - Camus"]="https://www.gutenberg.org/cache/epub/51116/pg51116.epub"

    # Marcus Aurelius
    ["Meditations - Marcus Aurelius"]="https://www.gutenberg.org/cache/epub/2680/pg2680.epub"

    # Confucius
    ["The Analects - Confucius"]="https://www.gutenberg.org/cache/epub/2036/pg2036.epub"

    # Lao Tzu
    ["Tao Te Ching - Lao Tzu"]="https://www.gutenberg.org/cache/epub/216/pg216.epub"

    # Sun Tzu
    ["The Art of War - Sun Tzu"]="https://www.gutenberg.org/cache/epub/132/pg132.epub"

    # Epicurus
    ["The Epicurus Reader"]="https://www.gutenberg.org/cache/epub/45137/pg45137.epub"

    # Augustine
    ["Confessions - Augustine"]="https://www.gutenberg.org/cache/epub/3296/pg3296.epub"

    # Thomas Aquinas
    ["Summa Theologica - Thomas Aquinas"]="https://www.gutenberg.org/cache/epub/17133/pg17133.epub"

    # Voltaire
    ["Candide - Voltaire"]="https://www.gutenberg.org/cache/epub/1994/pg1994.epub"
    ["Philosophical Dictionary - Voltaire"]="https://www.gutenberg.org/cache/epub/2154/pg2154.epub"

    # Rousseau
    ["The Social Contract - Rousseau"]="https://www.gutenberg.org/cache/epub/4603/pg4603.epub"
    ["Emile - Rousseau"]="https://www.gutenberg.org/cache/epub/54141/pg54141.epub"

    # John Stuart Mill
    ["On Liberty - Mill"]="https://www.gutenberg.org/cache/epub/34901/pg34901.epub"
    ["Utilitarianism - Mill"]="https://www.gutenberg.org/cache/epub/11224/pg11224.epub"

    # Hegel
    ["Phenomenology of Spirit - Hegel"]="https://www.gutenberg.org/cache/epub/17738/pg17738.epub"

    # Plotinus
    ["The Enneads - Plotinus"]="https://www.gutenberg.org/cache/epub/30277/pg30277.epub"

    # Bertrand Russell
    ["The Problems of Philosophy - Russell"]="https://www.gutenberg.org/cache/epub/5827/pg5827.epub"
    ["Why I Am Not a Christian - Russell"]="https://www.gutenberg.org/cache/epub/44823/pg44823.epub"
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
    filename="${filename}.epub"

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
    sleep 1
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
