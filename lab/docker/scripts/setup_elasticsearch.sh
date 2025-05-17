#!/bin/bash
set -e

# Define usuário e senha do admin
ADMIN_USER="elastic"
ADMIN_PASS="adminPass123"

# Define o usuário somente leitura e a senha
READONLY_USER="user"
READONLY_PASS="userPass456"

# Define o papel
READONLY_ROLE="kibana_dashboard_only"

# Define o endereço do Elasticsearch
ELASTIC_ADDR="localhost"

echo "Esperando o Elasticsearch iniciar..."
until curl -u "${ADMIN_USER}:${ADMIN_PASS}" -s "http://${ELASTIC_ADDR}:9200/_cluster/health" | grep -qE '"status":"(yellow|green)"'; do
  sleep 5
  echo "Aguardando Elasticsearch..."
done

echo "✔ Elasticsearch está pronto!"

echo "Criando papel '${READONLY_ROLE}'..."
curl -s -u "${ADMIN_USER}:${ADMIN_PASS}" -X POST "http://${ELASTIC_ADDR}:9200/_security/role/${READONLY_ROLE}" \
  -H "Content-Type: application/json" \
  -d '{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["*"],
      "privileges": ["read", "view_index_metadata"]
    }
  ],
  "applications": [
    {
      "application": "kibana-.kibana",
      "privileges": ["read"],
      "resources": ["*"]
    }
  ]
}'
echo "✔ Papel '${READONLY_ROLE}' criado com sucesso!"

echo "Criando usuário '${READONLY_USER}'..."
curl -s -u "${ADMIN_USER}:${ADMIN_PASS}" -X POST "http://${ELASTIC_ADDR}:9200/_security/user/${READONLY_USER}" \
  -H "Content-Type: application/json" \
  -d '{
  "password": "'"${READONLY_PASS}"'",
  "roles": ["'"${READONLY_ROLE}"'"],
  "full_name": "Read-Only User",
  "email": "readonly@example.com"
}'
echo "✔ Usuário '${READONLY_USER}' criado com sucesso!"
