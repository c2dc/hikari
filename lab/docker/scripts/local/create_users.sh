#!/bin/bash

# Caminho para o script de setup (usando a versão com underscore)
SETUP_SCRIPT="./setup_elasticsearch.sh"

if [ -f "${SETUP_SCRIPT}" ]; then
  echo "Iniciando a configuração do Elasticsearch, criação de papel e usuários..."
  bash "${SETUP_SCRIPT}"
else
  echo "Erro: O script ${SETUP_SCRIPT} não foi encontrado!"
  exit 1
fi
