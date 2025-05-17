#!/bin/bash
set -e

# Caminho absoluto do diretório onde o script está
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="${SCRIPT_DIR}/setup_elasticsearch.sh"

if [ -f "${SETUP_SCRIPT}" ]; then
  echo "[INFO] Iniciando a configuração do Elasticsearch, criação de papel e usuários..."
  bash "${SETUP_SCRIPT}"
else
  echo "[ERRO] Script '${SETUP_SCRIPT}' não encontrado!"
  exit 1
fi


