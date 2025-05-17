#!/bin/bash

# Caminho para o script de setup do Elasticsearch (usando a versão com underscore)
SETUP_ELASTICSEARCH="./setup_elasticsearch.sh"

if [ -f "${SETUP_ELASTICSEARCH}" ]; then
  echo "Iniciando a configuração do Elasticsearch, criação de papel e usuários..."
  bash "${SETUP_ELASTICSEARCH}"
else
  echo "Erro: O script ${SETUP_ELASTICSEARCH} não foi encontrado!"
  exit 1
fi

echo "✔ Configuração do Kibana concluída."

