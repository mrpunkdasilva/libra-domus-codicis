#!/bin/bash

# Script to push local commits to the remote repository.

# Determina o diretório raiz do projeto para garantir a execução correta.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
PROJECT_ROOT="$SCRIPT_DIR/.."

# Muda para o diretório raiz do projeto
cd "$PROJECT_ROOT" || exit

# Verifica se existe um repositório remoto configurado
if ! git remote | grep -q .; then
  echo "AVISO: Nenhum destino remoto configurado no Git."
  echo "Para configurar um repositório remoto, execute:"
  echo "  git remote add origin <url-do-repositorio>"
  echo "  git push -u origin main"
  echo "Abortando o push por falta de remote configurado."
  exit 1
fi

echo "Enviando alterações para o repositório remoto..."
git push
if [ $? -ne 0 ]; then
  echo "ERRO: Falha ao realizar o push para o repositório remoto."
  echo "Por favor, verifique sua conexão ou tente fazer o push manualmente."
  exit 1
fi

echo "Push realizado com sucesso."
exit 0
