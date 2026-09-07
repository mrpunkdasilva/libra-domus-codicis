#!/bin/bash

# Script to stage and commit an individual file with a semantic message.

# Determina o diretório raiz do projeto para garantir a execução correta.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

# Muda para o diretório raiz do projeto
cd "$PROJECT_ROOT" || exit

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  echo "ERRO: Nenhum arquivo fornecido para o commit."
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "ERRO: O arquivo '$FILE_PATH' não existe ou não é um arquivo comum."
  exit 1
fi

# Determina o tipo de mensagem com base na extensão do arquivo
EXT="${FILE_PATH##*.}"
EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

case "$EXT_LOWER" in
  pdf|epub|mobi)
    COMMIT_MSG="feat: Update book '$FILE_PATH'"
    ;;
  md)
    COMMIT_MSG="docs: Update documentation '$FILE_PATH'"
    ;;
  json)
    COMMIT_MSG="data: Update data '$FILE_PATH'"
    ;;
  py|sh|yml)
    COMMIT_MSG="chore: Update script '$FILE_PATH'"
    ;;
  *)
    COMMIT_MSG="feat: Update '$FILE_PATH'"
    ;;
esac

echo "Adicionando ao stage: $FILE_PATH"
git add "$FILE_PATH"
if [ $? -ne 0 ]; then
  echo "ERRO: Falha ao adicionar o arquivo '$FILE_PATH' ao stage."
  exit 1
fi

echo "Criando commit: $COMMIT_MSG"
git commit -m "$COMMIT_MSG"
if [ $? -ne 0 ]; then
  echo "ERRO: Falha ao criar o commit para o arquivo '$FILE_PATH'."
  # Faz unstage se falhar
  git reset HEAD "$FILE_PATH"
  exit 1
fi

echo "Arquivo '$FILE_PATH' commitado com sucesso."
exit 0
