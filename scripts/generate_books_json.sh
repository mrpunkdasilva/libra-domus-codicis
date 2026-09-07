#!/bin/bash

# Script para gerar o arquivo data_books.json
# Escaneia a pasta libraria/ e gera o JSON com informações dos livros

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."
LIBRARIA_DIR="$PROJECT_ROOT/libraria"
OUTPUT_FILE="$PROJECT_ROOT/docs/data/data_books.json"

echo "Escaneando livros em: $LIBRARIA_DIR"

# Coleta todos os arquivos primeiro
files=()
while IFS= read -r file; do
  files+=("$file")
done < <(find "$LIBRARIA_DIR" -type f \( -name "*.pdf" -o -name "*.epub" -o -name "*.mobi" -o -name "*.azw3" \) | sort)

total=${#files[@]}
echo "Total de arquivos encontrados: $total"

# Inicia o JSON
echo "[" > "$OUTPUT_FILE"

count=0
for file in "${files[@]}"; do
  count=$((count + 1))
  
  # Obtém o caminho relativo
  relative_path="${file#$LIBRARIA_DIR/}"
  
  # Obtém o nome do arquivo
  filename=$(basename "$file")
  
  # Obtém a categoria (pasta)
  directory=$(dirname "$relative_path")
  
  # Limpa o título (remove extensão, substitui _ por espaço)
  title="${filename%.*}"
  title_clean=$(echo "$title" | sed 's/_/ /g' | sed 's/-/ - /g' | sed 's/  */ /g')
  
  # Escapa aspas duplas no título
  title_clean="${title_clean//\"/\\\"}"
  
  # Adiciona vírgula se não for o primeiro
  if [ $count -gt 1 ]; then
    echo "," >> "$OUTPUT_FILE"
  fi
  
  # Escreve o objeto JSON
  cat >> "$OUTPUT_FILE" << EOF
  {
    "name": "$filename",
    "path": "libraria/$relative_path",
    "title_clean": "$title_clean",
    "description": "",
    "language": "",
    "tags": [],
    "category": "$directory"
  }
EOF
done

# Fecha o JSON
echo "" >> "$OUTPUT_FILE"
echo "]" >> "$OUTPUT_FILE"

echo ""
echo "JSON gerado com sucesso!"
echo "Arquivo: $OUTPUT_FILE"
echo "Total de livros: $total"
