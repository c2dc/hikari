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

# Caminho absoluto do diretório onde este script está
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Diretório raiz docker (um nível acima)
DOCKER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$DOCKER_ROOT" || fail "Não foi possível acessar o diretório do docker-compose"

[ -f docker-compose.yml ] || fail "Arquivo docker-compose.yml não encontrado em $DOCKER_ROOT"

print_header "Parando e removendo containers, volumes e orfãos"
docker compose down --volumes --remove-orphans || true

print_header "Reconstruindo e subindo o ambiente Docker"
docker compose up -d --build
echo -e "\e[32m✔ Docker iniciado com sucesso.\e[0m"
echo "Aguardando serviços estabilizarem..."
sleep 10

print_header "Ambiente pronto"
echo -e "\e[33m✔ Próximo passo: './scripts/setup_kibana.sh'\e[0m"

