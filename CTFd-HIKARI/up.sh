#!/bin/bash
set -euo pipefail

ZIP_SRC="../simulations/data.zip"
ZIP_DST="data.zip"

# Verifica se o arquivo ZIP existe
if [[ ! -f "$ZIP_SRC" ]]; then
  echo -e "\e[31m[ERRO]\e[0m Arquivo $ZIP_SRC não encontrado. Abortando."
  exit 1
fi

# Copia e descompacta
echo -e "\e[32m[INFO]\e[0m Copiando e extraindo $ZIP_SRC..."
cp "$ZIP_SRC" "$ZIP_DST"
sudo unzip -o "$ZIP_DST" >/dev/null
rm "$ZIP_DST"

# Sobe os containers
echo -e "\e[32m[INFO]\e[0m Subindo containers do CTFd..."
docker compose up -d

