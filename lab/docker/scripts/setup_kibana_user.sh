#!/bin/bash
set -e

echo "===================="
echo "Configurando usuários adicionais do Kibana"
echo "===================="

# Caminho absoluto para o script de setup do Elasticsearch
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_ELASTICSEARCH="$SCRIPT_DIR/setup_elasticsearch.sh"

if [ -f "${SETUP_ELASTICSEARCH}" ]; then
  echo "Iniciando a configuração do Elasticsearch, criação de papel e usuários..."
  bash "${SETUP_ELASTICSEARCH}"
else
  echo "Erro: O script ${SETUP_ELASTICSEARCH} não foi encontrado!"
  exit 1
fi

echo "✔ Configuração adicional do Kibana concluída (se aplicável)."

