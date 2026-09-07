#!/bin/bash

# Script to orchestrate individual commit and push of modified or new files.

# Determina o diretório raiz do projeto para garantir a execução correta.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

# Muda para o diretório raiz do projeto antes de executar qualquer coisa
cd "$PROJECT_ROOT" || exit

echo "Buscando por arquivos novos ou modificados (PDFs, e-books, dados, docs, scripts)..."

# Lista de extensões de arquivos suportadas
EXTENSIONS=('*.pdf' '*.epub' '*.mobi' '*.json' '*.md' '*.py' '*.sh' '*.svg')

# Usa git ls-files com as extensões listadas acima
# Obtém uma lista terminada em NUL (-z) para lidar corretamente com caminhos que possuem espaços
git ls-files --modified --others --exclude-standard -z "${EXTENSIONS[@]}" | while IFS= read -r -d '' file; do
  echo "---------------------------------"
  echo "Processando arquivo: $file"

  # Executa o script de commit individual
  bash "$SCRIPT_DIR/commit_file.sh" "$file"
  if [ $? -ne 0 ]; then
    echo "ERRO: Abortando o processo devido a uma falha no commit de '$file'."
    exit 1
  fi

  # Executa o script de push
  bash "$SCRIPT_DIR/push_repo.sh"
  if [ $? -ne 0 ]; then
    echo "ERRO: Abortando o processo devido a uma falha no push após commitar '$file'."
    exit 1
  fi

  echo "Arquivo '$file' processado e enviado com sucesso."
done

# Verifica se algum arquivo correspondente foi encontrado para dar um feedback limpo
if ! git ls-files --modified --others --exclude-standard "${EXTENSIONS[@]}" | read -r; then
    echo "Nenhum arquivo novo ou modificado com as extensões suportadas foi encontrado."
fi

echo "---------------------------------"
echo "Processo concluído."
