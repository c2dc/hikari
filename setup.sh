#!/bin/bash
set -euo pipefail

# ------------------ Funções auxiliares ------------------
info() {
  echo -e "\e[32m[INFO]\e[0m $1"
}

error_exit() {
  echo -e "\e[31m[ERRO]\e[0m $1" >&2
  exit 1
}

check_command() {
  command -v "$1" &>/dev/null || {
    info "'$1' não encontrado. Instalando via APT..."
    sudo apt update -qq
    sudo apt install -y "$1"
  }
}

ensure_docker_with_compose() {
  if ! command -v docker &>/dev/null || ! docker compose version &>/dev/null; then
    info "Docker ou plugin 'docker compose' não encontrado. Instalando via script oficial..."
    curl -fsSL https://get.docker.com | sh
  else
    info "Docker e plugin 'docker compose' já estão instalados."
  fi
}

check_disk_space() {
  local MIN_GB=10
  local AVAILABLE_KB
  AVAILABLE_KB=$(df --output=avail / | tail -1)
  local AVAILABLE_GB=$((AVAILABLE_KB / 1024 / 1024))
  if [ "$AVAILABLE_GB" -lt "$MIN_GB" ]; then
    error_exit "Espaço insuficiente: ${AVAILABLE_GB}GB disponíveis. Mínimo recomendado: ${MIN_GB}GB."
  else
    info "Espaço em disco suficiente: ${AVAILABLE_GB}GB disponíveis."
  fi
}

# ------------------ Verificações de dependências ------------------
info "Verificando dependências..."
check_command curl
check_command unzip
check_disk_space
ensure_docker_with_compose

# ------------------ Inicialização ------------------
info "Inicializando o ambiente HIKARI..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/lab/docker/scripts"
CTFD_DIR="$ROOT_DIR/CTFd-HIKARI"
RUN_ALL="$SCRIPTS_DIR/run-all.sh"
UP_SH="$CTFD_DIR/up.sh"

# ------------------ Verificações de arquivos ------------------
[ -x "$RUN_ALL" ] || error_exit "Script run-all.sh não encontrado ou sem permissão: $RUN_ALL"
[ -f "$UP_SH" ] || error_exit "Script up.sh não encontrado: $UP_SH"

# ------------------ Execução ------------------
info "Executando orquestração Docker com run-all.sh..."
bash "$RUN_ALL" || error_exit "Falha ao executar run-all.sh"

info "Executando inicialização do CTFd com up.sh..."
cd "$CTFD_DIR" || error_exit "Não foi possível entrar em $CTFD_DIR"
bash "$UP_SH" || error_exit "Falha ao executar up.sh"

info "✅ Ambiente HIKARI inicializado com sucesso."

# ------------------ Instruções finais ------------------
echo ""
echo -e "\e[34m====================\e[0m"
echo -e "\e[34mINSTRUÇÕES DE ACESSO\e[0m"
echo -e "\e[34m====================\e[0m"
echo ""
echo -e "➡ Acesse o Kibana (read-only): http://localhost:5601"
echo -e "   Usuário: \e[1muser\e[0m"
echo -e "   Senha:   \e[1muserPass456\e[0m"
echo ""
echo -e "➡ Acesse o CTFd (admin): http://localhost:8888"
echo -e "   Usuário: \e[1madmin\e[0m"
echo -e "   Senha:   \e[1mhikari@2023\e[0m"
echo ""
echo -e "\e[33m⚠️  Observações:\e[0m"
echo -e "  - É necessário criar manualmente os usuários no CTFd para cada competidor."
echo -e "  - Todos os competidores devem utilizar o mesmo usuário de acesso read-only ao Kibana."
echo ""
echo -e "\e[33mℹ️  O funcionamento correto da plataforma HIKARI depende da disponibilidade das seguintes portas de rede:\e[0m"
echo -e "   \e[1m2181, 9092, 9200, 5000, 5601, 8000, 80, 8888\e[0m"
echo -e "   Estas são utilizadas por serviços como ZooKeeper, Kafka, Elasticsearch, Logstash, Kibana, CTFd e outros componentes auxiliares."
echo -e "   Recomenda-se verificar previamente as configurações de firewall ou segurança do ambiente de execução."

