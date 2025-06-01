#!/bin/bash
set -euo pipefail

# Diretório base do script atual
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$BASE_DIR/../../../" && pwd)"
CTFD_DIR="$PROJECT_ROOT/CTFd-HIKARI"

info() { echo -e "\e[32m[INFO]\e[0m $1"; }
fail() { echo -e "\e[31m[ERRO]\e[0m $1"; exit 1; }

# ---------------- Detecta o comando compose ----------------
get_compose_cmd() {
  if command -v docker compose &>/dev/null; then
    echo "docker compose"
  elif command -v docker-compose &>/dev/null; then
    echo "docker-compose"
  else
    fail "'docker compose' (plugin) ou 'docker-compose' (legacy) não estão disponíveis."
  fi
}

COMPOSE_CMD="$(get_compose_cmd)"

# ---------------- Verificações de pré-requisitos ----------------
command -v docker >/dev/null || fail "Docker não está instalado."

AVAILABLE_SPACE_MB=$(df --output=avail / | tail -1)
if (( AVAILABLE_SPACE_MB < 2 * 1024 * 1024 )); then
  fail "Espaço em disco insuficiente (<2GB) para executar containers."
fi

info "Atualizando pacotes e instalando curl..."
sudo apt update -qq && sudo apt install -y -qq curl

# ---------------- Parando o CTFd se necessário ----------------
info "Parando CTFd, se estiver rodando..."
cd "$CTFD_DIR" || fail "CTFd-HIKARI não encontrado!"
$COMPOSE_CMD down -v || true
cd - > /dev/null

# ---------------- Limpeza do ambiente ----------------
info "Limpando ambiente Docker..."
CONTAINERS=$(docker ps -q)
[ -n "$CONTAINERS" ] && docker stop $CONTAINERS || true
docker container prune -f

# ---------------- Verificação da rede ----------------
info "Verificando rede 'hikari'..."
NETWORK_ID=$(docker network ls --filter name=^hikari$ -q)
if [ -n "$NETWORK_ID" ]; then
  ACTIVE=$(docker network inspect hikari --format '{{len .Containers}}')
  info "Rede 'hikari' já existe com $ACTIVE container(s)."
else
  info "Rede 'hikari' será criada automaticamente quando necessário."
fi

# ---------------- Execução dos scripts ----------------
for script in \
    start_env.sh \
    setup_kibana.sh \
    setup_elasticsearch.sh \
    create_users.sh \
    check_pipeline.sh \
    setup_kibana_user.sh \
    elasticsearch_user_creation.sh
do
  SCRIPT_PATH="$BASE_DIR/$script"
  if [[ -x "$SCRIPT_PATH" ]]; then
    info "Executando $script..."
    bash "$SCRIPT_PATH"
  else
    fail "Script ausente ou sem permissão: $SCRIPT_PATH"
  fi
done

# ---------------- Subida do CTFd ----------------
info "Iniciando CTFd..."
cd "$CTFD_DIR" || fail "CTFd-HIKARI não encontrado!"
if docker ps | grep -q ctfd-hikari-ctfd; then
  info "CTFd já está rodando. Pulando."
else
  $COMPOSE_CMD up -d
  info "CTFd iniciado com sucesso."
fi
cd - > /dev/null

info "✅ Todas as etapas foram concluídas com sucesso."

