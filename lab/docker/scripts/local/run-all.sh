#!/bin/bash

echo "Atualizando pacotes e instalando o curl..."
sudo apt update
sudo apt install curl -y

echo "Parando CTfd, se estiver rodando..."
# Navega para o diretório do CTfd-HIKARI e desliga o CTfd (para liberar a rede)
cd /home/ubuntu/hikari/CTFd-HIKARI || { echo "Diretório /home/ubuntu/hikari/CTFd-HIKARI não encontrado!"; exit 1; }
docker-compose down -v || true
cd - > /dev/null

echo "Limpando ambiente Docker..."
# Parar todos os containers ativos
CONTAINERS=$(docker ps -q)
if [ -n "$CONTAINERS" ]; then
    docker stop $CONTAINERS
fi
# Remover todos os containers parados
docker container prune -f

echo "Verificando a rede 'hikari'..."
NETWORK_ID=$(docker network ls --filter name=^hikari$ -q)
if [ -n "$NETWORK_ID" ]; then
    ACTIVE=$(docker network inspect hikari --format '{{len .Containers}}')
    if [ "$ACTIVE" -eq 0 ]; then
        echo "Rede 'hikari' já existe e está vazia. Mantendo a rede."
    else
        echo "Rede 'hikari' já existe e possui $ACTIVE container(s) conectados."
        echo "Mantendo a rede para uso compartilhado entre backend e CTfd."
    fi
else
    echo "Rede 'hikari' não existe. Ela será criada automaticamente quando necessário."
fi

echo "Iniciando o ambiente Docker (start_env.sh)..."
./start_env.sh

echo "Configurando o Kibana (setup_kibana.sh)..."
./setup_kibana.sh

echo "Configurando o Elasticsearch (setup_elasticsearch.sh)..."
./setup_elasticsearch.sh

echo "Criando usuários no Elasticsearch (create_users.sh)..."
./create_users.sh

echo "Verificando a integridade da pipeline (check_pipeline.sh)..."
./check_pipeline.sh

echo "Configurando usuários adicionais do Kibana (setup_kibana_user.sh)..."
./setup_kibana_user.sh

echo "Criando usuário somente leitura (elasticsearch_user_creation.sh)..."
./elasticsearch_user_creation.sh

echo "Iniciando CTfd..."
# Navega para o diretório do CTfd-HIKARI e inicia os containers do CTfd
cd /home/ubuntu/hikari/CTFd-HIKARI || { echo "Diretório /home/ubuntu/hikari/CTFd-HIKARI não encontrado!"; exit 1; }
docker-compose up -d
cd - > /dev/null
echo "CTfd iniciado com sucesso."

echo "Todas as etapas foram concluídas."

