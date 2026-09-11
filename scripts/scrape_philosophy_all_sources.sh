#!/bin/bash

# =============================================================================
# SCRAPE PHILOSOPHY BOOKS - MULTIPLE SOURCES
# Downloads classic philosophy books from multiple free sources
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOWNLOAD_DIR="$PROJECT_ROOT/libraria/philosophy"
DATA_DIR="$SCRIPT_DIR/data"
LOG_FILE="$DATA_DIR/scrape_log.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

mkdir -p "$DOWNLOAD_DIR" "$DATA_DIR"

echo "" > "$LOG_FILE"

log() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

download_book() {
    local url="$1"
    local filename="$2"
    local source="$3"

    if [ -f "$DOWNLOAD_DIR/$filename" ]; then
        warn "Already exists: $filename"
        return 0
    fi

    log "Downloading: $filename from $source"
    if wget -q --timeout=30 --tries=2 -O "$DOWNLOAD_DIR/$filename" "$url" 2>/dev/null; then
        local size=$(stat -f%z "$DOWNLOAD_DIR/$filename" 2>/dev/null || stat -c%s "$DOWNLOAD_DIR/$filename" 2>/dev/null || echo "0")
        if [ "$size" -gt 10000 ]; then
            success "Downloaded: $filename ($(( size / 1024 ))KB)"
            echo "$filename|$source|$url" >> "$DATA_DIR/downloaded_books.txt"
            return 0
        else
            rm -f "$DOWNLOAD_DIR/$filename"
            error "File too small, removed: $filename"
            return 1
        fi
    else
        error "Failed: $filename"
        return 1
    fi
}

# =============================================================================
# SOURCE 1: PROJECT GUTENBERG (via Gutendex API)
# =============================================================================
scrape_gutenberg() {
    log "=========================================="
    log "SOURCE 1: Project Gutenberg (Gutendex API)"
    log "=========================================="

    local base_url="https://gutendex.com/books"
    local page=1
    local total_downloaded=0

    # Classic philosophy authors and titles
    local search_terms=(
        "philosophy"
        "Plato"
        "Aristotle"
        "Nietzsche"
        "Kant"
        "Descartes"
        "Seneca"
        "Marcus Aurelius"
        "Epictetus"
        "Locke"
        "Hume"
        "Spinoza"
        "Hegel"
        "Schopenhauer"
        "Kierkegaard"
        "Sartre"
        "Camus"
        "Bertrand Russell"
        "Cicero"
        "Plotinus"
        "Augustine"
        "Thomas Aquinas"
        "Voltaire"
        "Rousseau"
        "John Stuart Mill"
        "Friedrich Engels"
        "Confucius"
        "Lao Tzu"
        "Sun Tzu"
        "Epicurus"
        "Diogenes"
    )

    for term in "${search_terms[@]}"; do
        log "Searching: $term"
        local encoded_term=$(echo "$term" | sed 's/ /+/g')
        local response=$(curl -s "${base_url}?search=${encoded_term}&languages=en,pt")

        if [ -z "$response" ]; then
            warn "No response for: $term"
            continue
        fi

        # Extract book info using jq
        local count=$(echo "$response" | jq -r '.count // 0')
        log "Found $count results for: $term"

        # Parse each book
        echo "$response" | jq -r '.results[] | "\(.id)|\(.title)|\(.authors[0].name // "Unknown")|\.formats["text/plain; charset=utf-8"] // .formats["application/epub+zip"] // .formats["text/html"] // empty"' 2>/dev/null | \
        while IFS='|' read -r id title author format_url; do
            if [ -z "$format_url" ] || [ "$format_url" = "null" ]; then
                # Try to get any available format
                format_url=$(echo "$response" | jq -r ".results[] | select(.id==$id) | .formats | to_entries[] | select(.key | test(\"epub|txt|pdf\")) | .value" 2>/dev/null | head -1)
            fi

            if [ -n "$format_url" ] && [ "$format_url" != "null" ]; then
                # Clean filename
                local clean_title=$(echo "$title" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g' | head -c 100)
                local clean_author=$(echo "$author" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g' | head -c 50)

                # Determine extension
                local ext="txt"
                if echo "$format_url" | grep -qi "epub"; then
                    ext="epub"
                elif echo "$format_url" | grep -qi "pdf"; then
                    ext="pdf"
                fi

                local filename="${clean_author}_${clean_title}.${ext}"

                if download_book "$format_url" "$filename" "Project Gutenberg"; then
                    total_downloaded=$((total_downloaded + 1))
                fi
            fi

            sleep 1  # Rate limiting
        done

        sleep 2  # Rate limiting between searches
    done

    log "Gutenberg completed. Downloaded: $total_downloaded books"
}

# =============================================================================
# SOURCE 2: INTERNET ARCHIVE (Advanced Search API)
# =============================================================================
scrape_internet_archive() {
    log "=========================================="
    log "SOURCE 2: Internet Archive"
    log "=========================================="

    local base_url="https://archive.org/advancedsearch.php"
    local total_downloaded=0

    # Search queries for philosophy
    local queries=(
        "philosophy+collection:(texts)+mediatype:(texts)"
        "plato+collection:(texts)+mediatype:(texts)"
        "aristotle+collection:(texts)+mediatype:(texts)"
        "nietzsche+collection:(texts)+mediatype:(texts)"
        "kant+collection:(texts)+mediatype:(texts)"
        "descartes+collection:(texts)+mediatype:(texts)"
        "seneca+collection:(texts)+mediatype:(texts)"
        "marcus+aurelius+collection:(texts)+mediatype:(texts)"
        "epictetus+collection:(texts)+mediatype:(texts)"
        "spinoza+collection:(texts)+mediatype:(texts)"
        "hegel+collection:(texts)+mediatype:(texts)"
        "schopenhauer+collection:(texts)+mediatype:(texts)"
        "locke+collection:(texts)+mediatype:(texts)"
        "hume+collection:(texts)+mediatype:(texts)"
        "kierkegaard+collection:(texts)+mediatype:(texts)"
        "sartre+collection:(texts)+mediatype:(texts)"
        "cicero+collection:(texts)+mediatype:(texts)"
        "confucius+collection:(texts)+mediatype:(texts)"
        "lao+tzu+collection:(texts)+mediatype:(texts)"
    )

    for query in "${queries[@]}"; do
        log "Searching Internet Archive: $query"

        local response=$(curl -s "${base_url}?q=${query}&fl[]=identifier,title,creator&rows=20&output=json&sort[]=downloads+desc" 2>/dev/null)

        if [ -z "$response" ]; then
            warn "No response for query"
            continue
        fi

        echo "$response" | jq -r '.response.docs[]? | "\(.identifier)|\(.title)|\(.creator // "Unknown")"' 2>/dev/null | \
        while IFS='|' read -r identifier title creator; do
            if [ -z "$identifier" ]; then
                continue
            fi

            # Try to get PDF download
            local pdf_url="https://archive.org/download/${identifier}/${identifier}.pdf"
            local epub_url="https://archive.org/download/${identifier}/${identifier}.epub"

            local clean_title=$(echo "$title" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g' | head -c 100)
            local clean_creator=$(echo "$creator" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g' | head -c 50)

            # Try PDF first
            local filename="${clean_creator}_${clean_title}.pdf"
            if download_book "$pdf_url" "$filename" "Internet Archive"; then
                total_downloaded=$((total_downloaded + 1))
            else
                # Try EPUB
                filename="${clean_creator}_${clean_title}.epub"
                if download_book "$epub_url" "$filename" "Internet Archive"; then
                    total_downloaded=$((total_downloaded + 1))
                fi
            fi

            sleep 2  # Rate limiting
        done

        sleep 3  # Rate limiting between queries
    done

    log "Internet Archive completed. Downloaded: $total_downloaded books"
}

# =============================================================================
# SOURCE 3: BAIXE LIVROS (baixelivros.com.br - PT-BR)
# =============================================================================
scrape_baixe_livros() {
    log "=========================================="
    log "SOURCE 3: Baixe Livros (PT-BR)"
    log "=========================================="

    local base_url="https://www.baixelivros.com.br"
    local total_downloaded=0

    # Philosophy category pages
    local pages=(
        "/filosofia"
        "/filosofia/grega-e-antiga"
        "/filosofia/moderna-e-contemporanea"
    )

    for page in "${pages[@]}"; do
        log "Scraping: $base_url$page"

        local html=$(curl -s -L "$base_url$page" 2>/dev/null)

        if [ -z "$html" ]; then
            warn "No HTML response for: $page"
            continue
        fi

        # Extract PDF links
        echo "$html" | grep -oP 'href="[^"]*\.pdf"' | sed 's/href="//;s/"//' | sort -u | \
        while read -r pdf_path; do
            local pdf_url="$base_url$pdf_path"
            local filename=$(basename "$pdf_path")

            if download_book "$pdf_url" "$filename" "Baixe Livros"; then
                total_downloaded=$((total_downloaded + 1))
            fi

            sleep 1
        done

        sleep 2
    done

    log "Baixe Livros completed. Downloaded: $total_downloaded books"
}

# =============================================================================
# SOURCE 4: PORTAL USP (livrosabertos.abcd.usp.br)
# =============================================================================
scrape_portal_usp() {
    log "=========================================="
    log "SOURCE 4: Portal de Livros Abertos USP"
    log "=========================================="

    local base_url="https://www.livrosabertos.abcd.usp.br"
    local category_url="$base_url/portaldelivrosUSP/catalog/category/filosofia"
    local total_downloaded=0

    log "Scraping: $category_url"

    local html=$(curl -s -L "$category_url" 2>/dev/null)

    if [ -z "$html" ]; then
        warn "No response from Portal USP"
        return
    fi

    # Extract book page links
    echo "$html" | grep -oP 'href="[^"]*catalog/[^"]*"' | sed 's/href="//;s/"//' | sort -u | \
    while read -r book_path; do
        local book_url="$base_url$book_path"
        log "Checking book page: $book_url"

        local book_html=$(curl -s -L "$book_url" 2>/dev/null)

        # Extract PDF download link
        local pdf_url=$(echo "$book_html" | grep -oP 'href="[^"]*\.pdf"' | head -1 | sed 's/href="//;s/"//')

        if [ -n "$pdf_url" ]; then
            # Make absolute URL if needed
            if [[ "$pdf_url" != http* ]]; then
                pdf_url="$base_url$pdf_url"
            fi

            local filename=$(basename "$pdf_url")

            if download_book "$pdf_url" "$filename" "Portal USP"; then
                total_downloaded=$((total_downloaded + 1))
            fi
        fi

        sleep 2
    done

    log "Portal USP completed. Downloaded: $total_downloaded books"
}

# =============================================================================
# SOURCE 5: GUTENBERG DIRECT (Mirror for additional books)
# =============================================================================
scrape_gutenberg_direct() {
    log "=========================================="
    log "SOURCE 5: Project Gutenberg Direct"
    log "=========================================="

    local total_downloaded=0

    # Classic philosophy book IDs on Gutenberg
    local book_ids=(
        1497    # Thus Spake Zarathustra - Nietzsche
        5520    # The Prince - Machiavelli
        3082    # Meditations - Marcus Aurelius
        2776    # Discourses - Epictetus
        1439    # Pride and Prejudice (classic)
        5740    # The Republic - Plato
        1661    # The Art of War - Sun Tzu
        4300    # Utopia - Thomas More
        55      # The Works of Aristotle
        1726    # Gulliver's Travels
        1498    # Beyond Good and Evil - Nietzsche
        5507    # The Interpretation of Dreams - Freud
        4328    # The Critique of Pure Reason - Kant
        3822    # Notes from Underground - Dostoevsky
        4605    # Utilitarianism - John Stuart Mill
        4357    # A Treatise of Human Nature - Hume
        3207    # The Leviathan - Hobbes
        3600    # Thus Spake Zarathustra (alternate)
        4391    # The Antichrist - Nietzsche
        4487    # The Gay Science - Nietzsche
        5765    # The Republic - Plato (alternate)
        3058    # Seneca's Moral Essays
        5827    # Confucian Analects
        2105    # Lao Tzu - Tao Te Ching
        4406    # Thus Spake Zarathustra (another)
        3802    # Beyond Good and Evil (alternate)
        3784    # Twilight of the Idols - Nietzsche
        4231    # The Will to Power - Nietzsche
        4391    # The Antichrist - Nietzsche
        2805    # The Meditations - Descartes
        3648    # The Critique of Judgment - Kant
    )

    for book_id in "${book_ids[@]}"; do
        # Get download page
        local download_page=$(curl -s "https://www.gutenberg.org/ebooks/$book_id" 2>/dev/null)

        if [ -z "$download_page" ]; then
            continue
        fi

        # Get title
        local title=$(echo "$download_page" | grep -oP '<title>[^<]*</title>' | sed 's/<[^>]*>//g' | sed 's/ *|.*//')

        # Try EPUB first
        local epub_url=$(echo "$download_page" | grep -oP 'href="[^"]*\.epub\.noimages"' | head -1 | sed 's/href="//;s/"//')
        if [ -z "$epub_url" ]; then
            epub_url=$(echo "$download_page" | grep -oP 'href="[^"]*\.epub"' | head -1 | sed 's/href="//;s/"//')
        fi

        # Try plain text
        local txt_url=$(echo "$download_page" | grep -oP 'href="[^"]*-0\.txt"' | head -1 | sed 's/href="//;s/"//')
        if [ -z "$txt_url" ]; then
            txt_url=$(echo "$download_page" | grep -oP 'href="[^"]*\.txt"' | head -1 | sed 's/href="//;s/"//')
        fi

        local clean_title=$(echo "$title" | sed 's/[^a-zA-Z0-9._-]/_/g' | sed 's/__*/_/g' | head -c 80)

        # Download EPUB if available
        if [ -n "$epub_url" ]; then
            if [[ "$epub_url" != http* ]]; then
                epub_url="https://www.gutenberg.org$epub_url"
            fi
            local filename="${clean_title}.epub"
            if download_book "$epub_url" "$filename" "Gutenberg Direct"; then
                total_downloaded=$((total_downloaded + 1))
            fi
        elif [ -n "$txt_url" ]; then
            if [[ "$txt_url" != http* ]]; then
                txt_url="https://www.gutenberg.org$txt_url"
            fi
            local filename="${clean_title}.txt"
            if download_book "$txt_url" "$filename" "Gutenberg Direct"; then
                total_downloaded=$((total_downloaded + 1))
            fi
        fi

        sleep 2
    done

    log "Gutenberg Direct completed. Downloaded: $total_downloaded books"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================
main() {
    log "=========================================="
    log "PHILOSOPHY BOOK SCRAPER - ALL SOURCES"
    log "=========================================="
    log "Output directory: $DOWNLOAD_DIR"
    log ""

    local start_time=$(date +%s)

    # Run all scrapers
    scrape_gutenberg
    scrape_internet_archive
    scrape_baixe_livros
    scrape_portal_usp
    scrape_gutenberg_direct

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Summary
    log ""
    log "=========================================="
    log "SCRAPING COMPLETE"
    log "=========================================="
    log "Duration: $((duration / 60))m $((duration % 60))s"

    local total_files=$(ls -1 "$DOWNLOAD_DIR" 2>/dev/null | wc -l)
    log "Total files downloaded: $total_files"

    local total_size=$(du -sh "$DOWNLOAD_DIR" 2>/dev/null | cut -f1)
    log "Total size: $total_size"

    log ""
    log "Files in $DOWNLOAD_DIR:"
    ls -lhS "$DOWNLOAD_DIR" 2>/dev/null | head -30

    log ""
    log "Download log saved to: $LOG_FILE"
}

# Run main
main "$@"
