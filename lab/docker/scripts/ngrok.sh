#!/bin/bash
set -euo pipefail

# Função para exibir mensagens informativas
info() {
    echo -e "\e[32m[INFO]\e[0m $1"
}

# Função para exibir mensagens de erro e encerrar
error_exit() {
    echo -e "\e[31m[ERROR]\e[0m $1" >&2
    exit 1
}

# Encerrar instâncias anteriores do ngrok, se houver
info "Encerrando instâncias anteriores do ngrok..."
pkill -f "ngrok start --all" || true
sleep 2

# Iniciar o ngrok
info "Iniciando ngrok com os túneis definidos..."
nohup ngrok start --all > /tmp/ngrok.log 2>&1 &

# Definir as possíveis portas da API do ngrok
NGROK_API_4041="http://127.0.0.1:4041/api/tunnels"
NGROK_API_4040="http://127.0.0.1:4040/api/tunnels"

# Verificar qual porta a API está rodando
info "Aguardando a API do ngrok..."
for i in {1..15}; do
    if curl -s "$NGROK_API_4041" | jq '.tunnels' &> /dev/null; then
        NGROK_API="$NGROK_API_4041"
        info "API do ngrok disponível na porta 4041!"
        break
    elif curl -s "$NGROK_API_4040" | jq '.tunnels' &> /dev/null; then
        NGROK_API="$NGROK_API_4040"
        info "API do ngrok disponível na porta 4040!"
        break
    else
        info "Tentativa $i de 15: API ainda não disponível. Aguardando 2 segundos..."
        sleep 2
    fi
    if [ "$i" -eq 15 ]; then
        error_exit "A API do ngrok não respondeu. Verifique /tmp/ngrok.log para mais detalhes."
    fi
done

# Obter as URLs públicas dos túneis
CTFD_PUBLIC_URL=$(curl -s "$NGROK_API" | jq -r '.tunnels[] | select(.name=="ctfd") | .public_url')
KIBANA_PUBLIC_URL=$(curl -s "$NGROK_API" | jq -r '.tunnels[] | select(.name=="kibana") | .public_url')

# Validar URLs
if [[ -z "$CTFD_PUBLIC_URL" || "$CTFD_PUBLIC_URL" == "null" ]]; then
    error_exit "Não foi possível obter a URL pública para o túnel CTFd."
fi

if [[ -z "$KIBANA_PUBLIC_URL" || "$KIBANA_PUBLIC_URL" == "null" ]]; then
    error_exit "Não foi possível obter a URL pública para o túnel Kibana."
fi

# Exibir URLs na tela
echo -e "\n\e[34m🚀 TÚNEIS ATIVOS:\e[0m"
echo -e "\e[33m🔹 CTFd:\e[0m   $CTFD_PUBLIC_URL"
echo -e "\e[33m🔹 Kibana:\e[0m $KIBANA_PUBLIC_URL\n"

# Criar o script de keepalive
KEEPALIVE_SCRIPT="/tmp/ngrok_keepalive.sh"

info "Criando script de keepalive em $KEEPALIVE_SCRIPT..."
cat << EOF > "$KEEPALIVE_SCRIPT"
#!/bin/bash
while true; do
    CT_URL=\$(curl -s $NGROK_API | jq -r '.tunnels[] | select(.name=="ctfd") | .public_url')
    KI_URL=\$(curl -s $NGROK_API | jq -r '.tunnels[] | select(.name=="kibana") | .public_url')

    if [[ -n "\$CT_URL" && "\$CT_URL" != "null" ]]; then
        echo "\$(date) - Ping para CTFd: \$CT_URL"
        curl -s "\$CT_URL" > /dev/null
    fi
    if [[ -n "\$KI_URL" && "\$KI_URL" != "null" ]]; then
        echo "\$(date) - Ping para Kibana: \$KI_URL"
        curl -s "\$KI_URL" > /dev/null
    fi
    sleep 3600  # Ping a cada 1 hora
done
EOF
chmod +x "$KEEPALIVE_SCRIPT"

# Verificar se o daemon já está rodando e matá-lo se necessário
KEEP_PID_FILE="/tmp/ngrok_keepalive.pid"
if [ -f "$KEEP_PID_FILE" ]; then
    KEEP_PID=$(cat "$KEEP_PID_FILE")
    if ps -p "$KEEP_PID" > /dev/null 2>&1; then
        info "Matando daemon antigo de keepalive (PID: $KEEP_PID)..."
        kill -9 "$KEEP_PID" || true
    fi
fi

# Iniciar o daemon de keepalive
info "Iniciando daemon de keepalive..."
nohup "$KEEPALIVE_SCRIPT" > /tmp/ngrok_keepalive.log 2>&1 &
KEEP_PID=$(pgrep -f "$KEEPALIVE_SCRIPT")
echo "$KEEP_PID" > "$KEEP_PID_FILE"
info "Daemon de keepalive iniciado com PID $KEEP_PID"

