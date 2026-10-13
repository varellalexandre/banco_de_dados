# Banco de Dados — Aulas Práticas

Materiais das aulas práticas da disciplina de Banco de Dados. Cada aula tem sua própria pasta, com os scripts SQL e um roteiro explicando o que fazer.

Os exemplos usam **PostgreSQL**.

## Estrutura do repositório

```text
banco_de_dados/
├── README.md
└── aulas/
    ├── aula-01-tema/
    │   ├── README.md              # roteiro da aula
    │   ├── 01-criar-tabelas.sql
    │   ├── 02-inserir-dados.sql
    │   └── 03-consultas.sql
    └── aula-02-tema/
        └── ...
```

Os scripts de cada aula são numerados na ordem em que devem ser executados.

## Pré-requisitos

- [PostgreSQL](https://www.postgresql.org/download/) instalado localmente (ou via [Docker](https://hub.docker.com/_/postgres))
- Um cliente SQL, por exemplo:
  - `psql` (linha de comando, já vem com o PostgreSQL)
  - [pgAdmin](https://www.pgadmin.org/)
  - [DBeaver](https://dbeaver.io/)

## Como usar

1. Clone o repositório:

   ```bash
   git clone https://github.com/varellalexandre/banco_de_dados.git
   cd banco_de_dados
   ```

2. Entre na pasta da aula e leia o `README.md` dela:

   ```bash
   cd aulas/aula-01-ddl
   ```

3. Execute os scripts na ordem indicada:

   ```bash
   psql -U <usuario> -d <banco> -f 01-criar-tabelas.sql
   ```

   Substitua `<usuario>` e `<banco>` pelos valores da sua instalação local.

## Aulas

| Aula | Tema                                  | Pasta                             |
|------|---------------------------------------|-----------------------------------|
| 01   | DDL: criar, alterar e remover tabelas | [aula-01-ddl](aulas/aula-01-ddl/) |

## Aviso

Este repositório é público. Usuários, senhas e dados que aparecem nos exemplos são fictícios. Use as suas credenciais apenas na sua máquina e **nunca** as adicione ao repositório (arquivos `.env`, `.pgpass` etc. já estão no `.gitignore`).
