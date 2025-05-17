# HIKARI (Hunting Integrado: Kompetição e Aprendizado em Resposta a Incidentes)

O HIKARI é um ambiente automatizado de experimentação para competições técnicas na área de segurança cibernética, integrando coleta de dados, análise, visualização com Kibana e desafios interativos via CTFd.

## Requisitos

- Docker e Docker Compose
- Linux (testado no Ubuntu 22.04 LTS)
- Acesso à internet (para primeira instalação)

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

- Instanciar todos os containers Docker necessários
- Configurar Elasticsearch, Logstash, Kibana e Kafka
- Criar usuários de acesso no Kibana
- Subir o ambiente do CTFd com base de dados e interface

## Acesso aos sistemas

- **Kibana (read-only)**: [http://localhost:5601](http://localhost:5601)  
  Usuário: `user`  
  Senha: `userPass456`

- **CTFd (admin)**: [http://localhost:8888](http://localhost:8888)  
  Usuário: `admin`  
  Senha: `hikari@2023`

## Observações importantes

- É necessário criar manualmente os usuários competidores dentro do CTFd.
- Todos os competidores devem acessar o Kibana com o mesmo usuário `user`.

## Licença

Este projeto é mantido pelo laboratório C2DC (ITA).

