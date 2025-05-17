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

# ------------------ Inicialização ------------------
info "Inicializando o ambiente HIKARI..."

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$ROOT_DIR/lab/docker/scripts"
CTFD_DIR="$ROOT_DIR/CTFd-HIKARI"
RUN_ALL="$SCRIPTS_DIR/run-all.sh"
UP_SH="$CTFD_DIR/up.sh"

# ------------------ Verificações ------------------
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
echo -e "⚠️  Observação:"
echo -e "  - É necessário criar manualmente os usuários no CTFd para cada competidor."
echo -e "  - Todos os competidores devem utilizar o mesmo usuário de acesso read-only ao Kibana."

