#!/bin/sh
# IMD0401 · Aula 01 · Tópico 01 · Subir o PostgreSQL no Docker e carregar a base loja
#
# Uso (na pasta desta aula, onde fica o docker-compose.yml):
#
#   sh ambiente.sh <usuario> [caminho/para/loja.sql]
#
# Antes, troque {modificar_usuario} e {modificar_senha} no docker-compose.yml.
# <usuario> é o mesmo que você colocou lá. Não precisa de psql instalado:
# o psql que roda é o de dentro do container.

USUARIO=${1:?informe o usuário do banco: sh ambiente.sh <usuario> [loja.sql]}
BASE=${2:-loja.sql}

# #trecho: subir
# 1. sobe o PostgreSQL 17 e o Adminer (http://localhost:8080)
docker compose up -d

# 2. espera o servidor aceitar conexões
until docker compose exec -T pgres pg_isready -U "$USUARIO" -d imd0401 >/dev/null 2>&1; do
  echo "aguardando o PostgreSQL..."
  sleep 1
done

# 3. carrega a base loja (rodar de novo = resetar a base)
docker compose exec -T pgres psql -U "$USUARIO" -d imd0401 < "$BASE"

# 4. confere: versão do servidor e tabelas do schema loja
docker compose exec -T pgres psql -U "$USUARIO" -d imd0401 -c "SELECT version();" -c "\dt loja.*"

# 5. abre o terminal interativo do psql
docker compose exec pgres psql -U "$USUARIO" -d imd0401
# #fim: subir

# Para desligar sem perder os dados:   docker compose stop
# Para apagar tudo, inclusive os dados: docker compose down -v
