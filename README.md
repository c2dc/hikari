# HIKARI (Hunting Integrado: Kompetição e Aprendizado em Resposta a Incidentes)

O HIKARI é um ambiente automatizado de experimentação para competições técnicas na área de segurança cibernética, integrando coleta de dados, análise com Elastic Stack e desafios interativos via CTFd.

## Requisitos

- Linux (testado no Ubuntu 22.04 LTS)
- Docker e Docker Compose (instalado automaticamente, se ausente)
- Acesso à internet (obrigatório na primeira execução)
- Permissões de sudo para instalação de dependências
- **Firewall liberado** para as seguintes portas (localmente ou em nuvem):

  ```
  2181, 9092, 9200, 5000, 5601, 8000, 80, 8888
  ```

> Essas portas são utilizadas por serviços como ZooKeeper, Kafka, Elasticsearch, Logstash, Kibana, CTFd e outros componentes auxiliares.

## Instalação

Clone o repositório:

```bash
git clone https://github.com/c2dc/hikari.git
cd hikari
```

Execute o script principal:

```bash
./setup.sh
```

Esse script irá:

- Verificar e instalar dependências (ex: curl, unzip, Docker)
- Instanciar todos os containers Docker necessários
- Configurar Elasticsearch, Logstash, Kibana e Kafka
- Criar índices, usuários e permissões no Elasticsearch/Kibana
- Subir o ambiente do CTFd com banco de dados e interface web

## Acesso aos sistemas

- **Kibana (read-only)**: [http://localhost:5601](http://localhost:5601)  
  **Usuário**: `user`  
  **Senha**: `userPass456`

- **CTFd (admin)**: [http://localhost:8888](http://localhost:8888)  
  **Usuário**: `admin`  
  **Senha**: `hikari@2023`

> Em ambientes em nuvem (ex: AWS), substitua `localhost` pelo IP público da instância.

## Observações importantes

- É necessário criar manualmente os usuários competidores no painel do CTFd.
- Todos os competidores devem utilizar o mesmo usuário `user` para acesso ao Kibana.
- Caso o `docker` esteja instalado mas inacessível ao seu usuário, execute:

  ```bash
  sudo usermod -aG docker $USER
  # e reinicie sua sessão
  ```

## Licença

Este projeto é mantido pelo laboratório C2DC (ITA).

