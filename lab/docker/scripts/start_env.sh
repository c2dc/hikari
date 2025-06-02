#!/bin/bash
set -euo pipefail

print_header() {
  echo -e "\n\e[34m===================="
  echo -e "$1"
  echo -e "====================\e[0m"
}

fail() {
  echo -e "\e[31m[ERRO]\e[0m $1" >&2
  exit 1
}

wait_for_container_healthy() {
  local container="$1"
  local timeout=180
  local interval=5
  local waited=0

  echo -e "\e[34mAguardando container '$container' ficar saudável...\e[0m"
  while [[ "$(docker inspect -f '{{.State.Health.Status}}' "$container" 2>/dev/null || echo "missing")" != "healthy" ]]; do
    sleep $interval
    waited=$((waited + interval))
    if (( waited >= timeout )); then
      fail "Timeout: container '$container' não ficou saudável em $timeout segundos."
    fi
  done
  echo -e "\e[32m✔ Container '$container' está saudável.\e[0m"
}

# Caminho absoluto do diretório onde este script está
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$DOCKER_ROOT" || fail "Não foi possível acessar o diretório do docker-compose"

[ -f docker-compose.yml ] || fail "Arquivo docker-compose.yml não encontrado em $DOCKER_ROOT"

print_header "Parando e removendo containers, volumes e orfãos"
docker compose down --volumes --remove-orphans || true

print_header "Reconstruindo e subindo o ambiente Docker"
docker compose up -d --build

print_header "Aguardando serviços críticos..."
wait_for_container_healthy elastic
wait_for_container_healthy kafka

print_header "Ambiente pronto"
echo -e "\e[33m✔ Próximo passo: './scripts/setup_kibana.sh'\e[0m"

