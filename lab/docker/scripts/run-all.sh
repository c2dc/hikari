#!/bin/bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
info() { echo -e "\e[32m[INFO]\e[0m $1"; }
fail() { echo -e "\e[31m[ERRO]\e[0m $1"; exit 1; }

info "Atualizando pacotes e instalando o curl..."
sudo apt update -qq && sudo apt install -y -qq curl

info "Parando CTfd, se estiver rodando..."
cd /home/ubuntu/hikari/CTFd-HIKARI || fail "CTFd-HIKARI não encontrado!"
docker-compose down -v || true
cd - > /dev/null

info "Limpando ambiente Docker..."
CONTAINERS=$(docker ps -q)
[ -n "$CONTAINERS" ] && docker stop $CONTAINERS || true
docker container prune -f

info "Verificando rede 'hikari'..."
NETWORK_ID=$(docker network ls --filter name=^hikari$ -q)
if [ -n "$NETWORK_ID" ]; then
  ACTIVE=$(docker network inspect hikari --format '{{len .Containers}}')
  info "Rede 'hikari' já existe com $ACTIVE container(s)."
else
  info "Rede 'hikari' será criada automaticamente quando necessário."
fi

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

info "Iniciando CTFd..."
cd /home/ubuntu/hikari/CTFd-HIKARI || fail "CTFd-HIKARI não encontrado!"
if docker ps | grep -q ctfd-hikari-ctfd; then
  info "CTFd já está rodando. Pulando."
else
  docker-compose up -d
  info "CTFd iniciado com sucesso."
fi
cd - > /dev/null

info "✅ Todas as etapas foram concluídas."

