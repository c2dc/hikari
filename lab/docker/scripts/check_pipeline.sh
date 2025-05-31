#!/bin/bash
set -euo pipefail

info() { echo -e "\e[32m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[AVISO]\e[0m $1"; }
fail() { echo -e "\e[31m[ERRO]\e[0m $1"; exit 1; }

info "Verificando tópicos do Kafka..."
if ! docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list; then
  warn "Não foi possível listar os tópicos do Kafka. Verifique se o container está ativo."
fi

info "Verificando erros nos logs do Logstash..."
if ! docker logs logstash 2>&1 | grep -i error; then
  info "Nenhum erro encontrado nos logs do Logstash."
fi

info "Verificando índices do Elasticsearch..."
if ! curl -s -X GET "http://localhost:9200/_cat/indices?v" -u elastic:adminPass123; then
  fail "Falha ao consultar índices do Elasticsearch."
fi

info "Realizando busca de teste no índice 'competition1'..."
if ! curl -s -X GET "http://localhost:9200/competition1/_search?size=1&pretty" -u elastic:adminPass123; then
  warn "Índice 'competition1' não encontrado ou vazio."
fi

