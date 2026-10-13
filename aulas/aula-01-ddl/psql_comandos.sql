-- IMD0401 · Aula 8 · Metacomandos do psql
--
-- Começam com barra invertida e não são SQL: quem os interpreta é o psql,
-- antes de qualquer coisa chegar ao servidor. Não levam ponto e vírgula.

-- #trecho: meta
\dn              -- lista os schemas (public e loja)
\dt              -- lista as tabelas do schema loja
\d produto       -- colunas, tipos, chaves e restrições
\x               -- liga e desliga a saída vertical
\i arquivo.sql   -- executa um script inteiro
\?               -- ajuda dos metacomandos
\q               -- sai do psql
-- #fim: meta
