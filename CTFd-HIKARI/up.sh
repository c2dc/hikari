#!/bin/bash
set -euo pipefail

ZIP_SRC="../simulations/data.zip"
ZIP_DST="data.zip"
TARGET_DIR=".data"

info() {
  echo -e "\e[32m[INFO]\e[0m $1"
}

error_exit() {
  echo -e "\e[31m[ERRO]\e[0m $1" >&2
  exit 1
}

ensure_unzip() {
  if ! command -v unzip &>/dev/null; then
    info "'unzip' não encontrado. Instalando..."
    sudo apt update -qq
    sudo apt install -y unzip
  fi
}

# 1. Verifica e instala unzip se necessário
ensure_unzip

# 2. Verifica se o ZIP existe
[[ -f "$ZIP_SRC" ]] || error_exit "Arquivo $ZIP_SRC não encontrado."

# 3. Remove diretório .data/ se já existir
if [[ -d "$TARGET_DIR" ]]; then
  info "Pasta '$TARGET_DIR' já existe. Removendo antes de extrair..."
  sudo rm -rf "$TARGET_DIR"
fi

# 4. Copia e extrai com permissões elevadas
info "Copiando e extraindo $ZIP_SRC..."
cp "$ZIP_SRC" "$ZIP_DST"
sudo unzip -o "$ZIP_DST" >/dev/null || error_exit "Falha ao extrair $ZIP_DST"
rm "$ZIP_DST"

# 5. Sobe os containers do CTFd
info "Subindo containers do CTFd..."
docker compose up -d

# 6. Reinicia container de banco de dados para garantir leitura dos dados
info "Reiniciando container ctfd-hikari-db-1 para garantir leitura do volume..."
docker restart ctfd-hikari-db-1 >/dev/null || error_exit "Falha ao reiniciar ctfd-hikari-db-1"

info "✅ Dados restaurados e containers do CTFd operacionais."

