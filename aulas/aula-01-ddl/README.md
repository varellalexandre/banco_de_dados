# Aula 01 — DDL: criar, alterar e remover tabelas

## Objetivo

Usar a DDL (_Data Definition Language_) do SQL para definir a estrutura de um banco. Ao final da aula, você deve saber:

1. subir o PostgreSQL no Docker e carregar a base loja;
2. distinguir as sublinguagens DDL, DML, DQL, DCL e TCL;
3. escolher o tipo de dado adequado para cada coluna;
4. declarar tabelas com chaves e restrições de integridade;
5. alterar e remover estruturas com `ALTER`, `TRUNCATE` e `DROP`.

## Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) com Docker Compose (ou PostgreSQL 17 instalado localmente)
- Base **loja** (`loja.sql`), disponibilizada pelo professor
- Os metacomandos do `psql` em [`psql_comandos.sql`](psql_comandos.sql)

## Arquivos

| Tópico | Arquivo                                            | Descrição                                                           |
|--------|----------------------------------------------------|---------------------------------------------------------------------|
| 01     | [`docker-compose.yml`](docker-compose.yml)         | Sobe o PostgreSQL 17 e o Adminer (interface web)                    |
| 01     | [`ambiente.sh`](ambiente.sh)                       | Sobe o ambiente, carrega a base loja e abre o `psql`                |
| 01     | [`psql_comandos.sql`](psql_comandos.sql)           | Metacomandos do `psql` (`\dt`, `\d`, `\x`...)                       |
| 02     | [`02-sublinguagens.sql`](02-sublinguagens.sql)     | Um exemplo de DDL, DML, DQL, DCL e TCL                              |
| 03     | [`03-tipos-de-dados.sql`](03-tipos-de-dados.sql)   | Tipos numéricos, texto, data/hora, ENUM, DOMAIN, UUID, JSONB        |
| 04     | [`04-restricoes.sql`](04-restricoes.sql)           | FK autorreferente, FK composta, CHECK entre colunas, UNIQUE parcial |
| 05     | [`05-alterar-remover.sql`](05-alterar-remover.sql) | ALTER com USING, NOT VALID, DROP CASCADE, TRUNCATE, DROP SCHEMA     |
| 04, 05 | [`ddl.sql`](ddl.sql)                               | Script integrado: cria, altera e remove três tabelas                |

Todos os scripts `.sql` desfazem o que criam: a base loja termina do jeito que começou, e cada um pode ser rodado quantas vezes quiser.

## Passo a passo

1. **Configure o usuário e a senha.** No `docker-compose.yml`, troque `{modificar_usuario}` e `{modificar_senha}` por valores seus. Use essas credenciais só na sua máquina e **não faça commit** do arquivo alterado.

2. **Suba o ambiente** (na pasta desta aula):

   ```bash
   docker compose up -d
   ```

   O Adminer fica em <http://localhost:8080> (sistema: PostgreSQL, servidor: `pgres`, banco: `imd0401`).

3. **Carregue a base loja.** Rodar de novo apaga e recria o schema `loja`, o que serve para "resetar a base":

   ```bash
   docker compose exec -T pgres psql -U <usuario> -d imd0401 < loja.sql
   ```

4. **Abra o `psql`** e explore a base com os metacomandos de [`psql_comandos.sql`](psql_comandos.sql):

   ```bash
   docker compose exec pgres psql -U <usuario> -d imd0401
   ```

   ```sql
   SET search_path TO loja, public;
   \dt
   \d produto
   ```

   Os passos 2 a 4 também podem ser feitos de uma vez com o script do tópico 01:

   ```bash
   sh ambiente.sh <usuario> loja.sql
   ```

5. **Execute os scripts dos tópicos**, na ordem:

   ```bash
   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 02-sublinguagens.sql
   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 03-tipos-de-dados.sql
   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 04-restricoes.sql
   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 05-alterar-remover.sql
   docker compose exec -T pgres psql -U <usuario> -d imd0401 < ddl.sql
   ```

   Para acompanhar com calma, rode um trecho de cada vez (os trechos estão marcados com `-- #trecho:` nos arquivos). Os erros de propósito ficam dentro de blocos `DO $$ ... $$` e aparecem como `NOTICE`, sem interromper o script.

## Tópicos da aula

### Tópico 01 — Ambiente

O `docker-compose.yml` sobe dois containers: o PostgreSQL 17 (`pgres`) e o Adminer, uma interface web. O `psql` roda dentro do container, então não é preciso instalá-lo. A base loja fica no schema `loja`: `SET search_path TO loja, public;` permite escrever `produto` em vez de `loja.produto`.

| Comando                  | Efeito                                    |
|--------------------------|-------------------------------------------|
| `docker compose up -d`   | Sobe os containers em segundo plano       |
| `docker compose stop`    | Desliga, mantendo os dados                |
| `docker compose down -v` | Remove os containers **e apaga os dados** |

### Tópico 02 — Sublinguagens — [`02-sublinguagens.sql`](02-sublinguagens.sql)

| Sublinguagem | Para quê             | Comandos                                         | Trecho |
|--------------|----------------------|--------------------------------------------------|--------|
| DDL          | Definir a estrutura  | `CREATE`, `ALTER`, `DROP`, `TRUNCATE`, `COMMENT` | `ddl`  |
| DML          | Manipular as linhas  | `INSERT`, `UPDATE`, `DELETE`                     | `dml`  |
| DQL          | Consultar            | `SELECT`                                         | `dql`  |
| DCL          | Controlar o acesso   | `GRANT`, `REVOKE`                                | `dcl`  |
| TCL          | Controlar transações | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`       | `tcl`  |

Dois detalhes do script: o papel `estagiario` recebe `SELECT` e `INSERT`, mas tem o `UPDATE` barrado; e, no PostgreSQL, até um `DROP TABLE` pode ser desfeito com `ROLLBACK`.

### Tópico 03 — Tipos de dados — [`03-tipos-de-dados.sql`](03-tipos-de-dados.sql)

| Família   | Tipos                                                  | Use para                                    |
|-----------|--------------------------------------------------------|---------------------------------------------|
| Inteiros  | `SMALLINT`, `INTEGER`, `BIGINT`                        | Contagens, identificadores                  |
| Exatos    | `NUMERIC(p,s)`                                         | Dinheiro e tudo que não pode arredondar     |
| Flutuante | `REAL`, `DOUBLE PRECISION`                             | Medidas científicas (`0.1 + 0.2 <> 0.3`!)   |
| Texto     | `CHAR(n)`, `VARCHAR(n)`, `TEXT`                        | Códigos fixos, nomes, textos livres         |
| Tempo     | `DATE`, `TIME`, `TIMESTAMP`, `TIMESTAMPTZ`, `INTERVAL` | Datas, horários, durações                   |
| Lógico    | `BOOLEAN`                                              | Sim/não                                     |
| Outros    | `UUID`, `JSONB`, `TEXT[]`                              | Identificadores globais, documentos, listas |
| Próprios  | `CREATE TYPE ... AS ENUM`, `CREATE DOMAIN`             | Lista fechada de valores; tipo com regra    |

No fim do script, um valor fora do limite é testado para cada tipo (SMALLINT, NUMERIC, VARCHAR, DATE, ENUM e DOMAIN).

### Tópico 04 — Chaves e restrições — [`04-restricoes.sql`](04-restricoes.sql) e [`ddl.sql`](ddl.sql)

O `ddl.sql` mostra as restrições básicas (seções 1 a 6 abaixo). O `04-restricoes.sql` acrescenta:

| Trecho            | O que mostra                                                                                  |
|-------------------|-----------------------------------------------------------------------------------------------|
| `autorreferencia` | FK para a própria tabela (`setor` → `setor`) com `ON DELETE SET NULL`                         |
| `check_colunas`   | `CHECK (fim >= inicio)`, `UNIQUE` composto e coluna gerada (`GENERATED ALWAYS AS ... STORED`) |
| `fk_composta`     | FK de duas colunas apontando para a chave composta de `estoque`                               |
| `unique_parcial`  | `CREATE UNIQUE INDEX ... WHERE principal`: só um endereço principal por cliente               |

### Tópico 05 — Alterar e remover — [`05-alterar-remover.sql`](05-alterar-remover.sql) e [`ddl.sql`](ddl.sql)

O `ddl.sql` mostra os `ALTER TABLE` básicos (seções 7 e 10 abaixo). O `05-alterar-remover.sql` trabalha em cópias, num schema `rascunho`, e acrescenta:

| Trecho                         | O que mostra                                                                       |
|--------------------------------|------------------------------------------------------------------------------------|
| `copiar`                       | `CREATE TABLE ... (LIKE ...)` e `CREATE TABLE ... AS SELECT`                       |
| `alter_tipo`                   | `ALTER COLUMN ... TYPE ... USING` para converter os valores                        |
| `alter_restricoes`, `validar`  | `DROP NOT NULL`, `RENAME CONSTRAINT`, `ADD CONSTRAINT ... NOT VALID` e `VALIDATE`  |
| `drop_cascade`                 | `DROP COLUMN` barrado por uma visão, e o mesmo com `CASCADE`                       |
| `truncate`, `truncate_cascade` | `TRUNCATE` de várias tabelas, `RESTART IDENTITY` e `CASCADE`                       |
| `drop`                         | `SET SCHEMA`, `DROP TABLE IF EXISTS` com várias tabelas, `DROP SCHEMA ... CASCADE` |

## O script integrado: `ddl.sql`

O modelo usado no `ddl.sql` liga fornecedores aos produtos da base loja:

```text
fornecedor 1 ──── N fornecimento N ──── 1 produto   (base loja)
     │
     1 ──── N contato_fornecedor
```

### 1. Criando tabelas — `#trecho: create`

`CREATE TABLE` define colunas, tipos e restrições. A tabela `fornecedor` usa:

| Restrição                      | Exemplo no script             | O que garante                            |
|--------------------------------|-------------------------------|------------------------------------------|
| `PRIMARY KEY`                  | `id_fornecedor`               | Identifica cada linha (único e não nulo) |
| `GENERATED ALWAYS AS IDENTITY` | `id_fornecedor`               | O banco gera o número sozinho            |
| `NOT NULL`                     | `razao_social`                | Valor obrigatório                        |
| `UNIQUE`                       | `cnpj`                        | Não repete entre as linhas               |
| `DEFAULT`                      | `cidade DEFAULT 'Natal'`      | Valor usado quando o INSERT não informa  |
| `CHECK`                        | `prazo_dias BETWEEN 1 AND 90` | Condição que todo valor precisa cumprir  |
| `CONSTRAINT nome CHECK`        | `cnpj_so_digitos`             | Igual ao CHECK, mas com nome escolhido   |

### 2. Chaves estrangeiras — `#trecho: fk`

`fornecimento` é uma tabela associativa (N:N entre fornecedor e produto) com chave primária composta. Cada FK escolhe o que acontece quando a linha referenciada é removida:

- `ON DELETE CASCADE`: remove junto as linhas que dependem dela;
- `ON DELETE RESTRICT`: impede a remoção enquanto houver dependentes.

### 3. Restrições nomeadas — `#trecho: restricoes_nomeadas`

Em `contato_fornecedor`, todas as restrições são declaradas no fim da tabela, cada uma com `CONSTRAINT <nome>`. O nome aparece nas mensagens de erro e permite remover a restrição depois com `ALTER TABLE ... DROP CONSTRAINT`.

### 4. Inserindo dados — `#trecho: insert_varios`

Um único `INSERT` pode trazer várias linhas. As colunas omitidas recebem o `DEFAULT`. Todos os dados da aula são fictícios.

### 5. Violando restrições

Um bloco `DO $$ ... $$` tenta, de propósito, quebrar cada restrição (`UNIQUE`, `CHECK`, `NOT NULL`, `PRIMARY KEY`, `FOREIGN KEY`) e mostra a mensagem de erro como `NOTICE`, sem interromper o script. Leia as mensagens e identifique qual restrição barrou cada caso.

### 6. Remoção em cascata — `#trecho: cascade`

Ao apagar o fornecedor 7, seus fornecimentos e contatos somem junto, por causa do `ON DELETE CASCADE`. O script conta as linhas antes e depois para mostrar o efeito.

### 7. Alterando tabelas — `#trecho: alter` e `#trecho: alter_mais`

| Comando                              | Efeito                                       |
|--------------------------------------|----------------------------------------------|
| `ADD COLUMN`                         | Acrescenta uma coluna                        |
| `DROP COLUMN`                        | Remove uma coluna                            |
| `RENAME COLUMN ... TO ...`           | Renomeia uma coluna                          |
| `RENAME TO ...`                      | Renomeia a tabela                            |
| `ALTER COLUMN ... TYPE`              | Muda o tipo de uma coluna                    |
| `ALTER COLUMN ... SET DEFAULT`       | Define o valor padrão                        |
| `ALTER COLUMN ... SET NOT NULL`      | Torna obrigatória (falha se já houver NULL)  |
| `ADD CONSTRAINT` / `DROP CONSTRAINT` | Acrescenta ou retira uma restrição pelo nome |

Repare na ordem usada para tornar `prazo_dias` obrigatória: primeiro um `UPDATE` preenche os `NULL`, só depois vem o `SET NOT NULL`.

### 8. Índices e comentários — `#trecho: indice_comentario`

- `CREATE INDEX` acelera buscas por uma coluna (aqui: "quem fornece o produto X?").
- `COMMENT ON` documenta tabelas e colunas dentro do próprio banco; os comentários aparecem no `\d+` do `psql`.

### 9. O catálogo — `#trecho: catalogo`

O banco guarda a descrição de si mesmo. A visão `information_schema.table_constraints` lista as restrições criadas, inclusive os nomes que o PostgreSQL gera automaticamente (como `fornecedor_cnpj_key`).

### 10. Removendo — `#trecho: remover`

| Comando      | Tipo | O que remove                         |
|--------------|------|--------------------------------------|
| `DELETE`     | DML  | As linhas que atendem ao `WHERE`     |
| `TRUNCATE`   | DDL  | Todas as linhas, de uma vez          |
| `DROP TABLE` | DDL  | A tabela inteira (estrutura e dados) |

Um `DROP TABLE` falha se outra tabela ainda depende dela por chave estrangeira. Por isso o script remove `contato` antes de `fornecedor`.

## Exercícios

1. O fornecedor "Papel & Cia" é inserido com `prazo_dias` nulo, e o `CHECK (prazo_dias BETWEEN 1 AND 90)` não barra. Por quê?
2. Crie uma tabela `marca` (id, nome único, país de origem com valor padrão `'Brasil'`) e acrescente a `produto` uma coluna `id_marca` com chave estrangeira para ela.
3. Na tabela `fornecimento`, troque o `ON DELETE CASCADE` da FK de fornecedor por `ON DELETE RESTRICT`. O que muda ao apagar um fornecedor? (Dica: `DROP CONSTRAINT` + `ADD CONSTRAINT`.)
4. Acrescente à tabela `fornecedor` um `CHECK` que impeça `cadastrado_em` no futuro.
5. Explique a diferença entre `DELETE FROM fornecimento;` e `TRUNCATE fornecimento;`. Os dois deixam a tabela vazia: o que mais muda?
6. Use `\d fornecedor` antes e depois do `#trecho: alter` e anote tudo o que mudou na estrutura.
7. Classifique cada comando como DDL, DML, DQL, DCL ou TCL: `TRUNCATE`, `GRANT`, `SELECT`, `SAVEPOINT`, `COMMENT ON`, `UPDATE`.
8. Escolha o tipo de cada coluna de uma tabela `entrega`: código de rastreio (sempre 13 caracteres), peso em kg, valor do frete, data e hora da saída (com fuso), prazo previsto (em dias) e status (`'postado'`, `'em trânsito'`, `'entregue'`). Justifique cada escolha.
9. Crie um `DOMAIN` chamado `cep` que só aceite 8 dígitos e use-o em uma tabela.
10. No `04-restricoes.sql`, troque o `ON DELETE SET NULL` de `setor` por `ON DELETE CASCADE` e rode de novo. O que acontece com Expedição e Televendas?
11. Por que `TRUNCATE lista` falha mesmo quando `item_lista` já está vazia? Como resolver sem `CASCADE`?

Ao terminar, recarregue a base loja (passo 3) para desfazer as alterações.
