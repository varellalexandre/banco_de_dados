# CLAUDE.md

Orientações para o Claude Code ao trabalhar neste repositório.

## Propósito

Repositório para compartilhar com os alunos os materiais das aulas práticas de Banco de Dados. O SGBD usado é o **PostgreSQL**. O público são estudantes, então o conteúdo deve ser didático, claro e escrito em português.

## Segurança (regra prioritária)

Este repositório é **público**. Ele serve apenas para disponibilizar códigos e materiais das aulas.

- **Nunca** adicionar senhas, tokens, chaves de API, strings de conexão reais, arquivos `.env`, `.pgpass` ou certificados.
- **Nunca** incluir hosts, IPs ou nomes de servidores internos/institucionais.
- **Nunca** incluir dados pessoais: nomes, e-mails, matrículas, notas ou qualquer informação de alunos ou usuários.
- **Nunca** versionar dumps ou backups com dados reais.
- Usar sempre placeholders (`<usuario>`, `<senha>`, `<banco>`, `localhost`) e dados fictícios nos exemplos.
- Antes de qualquer commit, revisar o diff procurando informações sensíveis. Se o `.gitignore` não cobrir algum arquivo sensível novo, atualizá-lo.

## Convenções

- Cada aula fica em `aulas/aula-NN-tema-curto/`: número com dois dígitos, tema em kebab-case, sem acentos (ex.: `aulas/aula-03-joins/`).
- Toda aula tem um `README.md` com: objetivo, pré-requisitos e passo a passo.
- Scripts SQL são numerados na ordem de execução: `01-criar-tabelas.sql`, `02-inserir-dados.sql`, `03-consultas.sql`.
- SQL compatível com PostgreSQL, com palavras-chave em MAIÚSCULAS e comentários em português.
- Ao adicionar uma aula, atualizar a tabela **Aulas** no `README.md` da raiz.
