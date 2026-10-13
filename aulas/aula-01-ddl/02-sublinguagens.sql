-- IMD0401 · Aula 01 · Tópico 02 · As sublinguagens do SQL: DDL, DML, DQL, DCL e TCL
--
--   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 02-sublinguagens.sql
--
-- Um exemplo de cada sublinguagem sobre uma tabela pequena (cupom) e um papel
-- (estagiario). Os dois são removidos no fim: a base loja sai daqui do jeito
-- que entrou.

SET search_path TO loja, public;
DROP TABLE IF EXISTS cupom;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'estagiario') THEN
        DROP OWNED BY estagiario;   -- retira as permissões que sobraram
        DROP ROLE estagiario;
    END IF;
END
$$;

-- #trecho: ddl
-- DDL (Data Definition Language): define a ESTRUTURA — CREATE, ALTER, DROP
CREATE TABLE cupom (
    codigo     VARCHAR(20)  PRIMARY KEY,
    desconto   NUMERIC(5,2) NOT NULL CHECK (desconto BETWEEN 0 AND 100),
    valido_ate DATE         NOT NULL
);
ALTER TABLE cupom ADD COLUMN usado BOOLEAN NOT NULL DEFAULT false;
COMMENT ON TABLE cupom IS 'Cupons de desconto da loja virtual';
-- #fim: ddl

-- #trecho: dml
-- DML (Data Manipulation Language): mexe nas LINHAS — INSERT, UPDATE, DELETE
INSERT INTO cupom (codigo, desconto, valido_ate) VALUES
    ('BEMVINDO10', 10, '2026-12-31'),
    ('VOLTAAULAS', 15, '2027-02-28'),
    ('NATAL25',    25, '2026-12-25'),
    ('EXPIRADO5',   5, '2025-01-31');
UPDATE cupom SET usado = true WHERE codigo = 'BEMVINDO10';
DELETE FROM cupom WHERE valido_ate < DATE '2026-01-01';
-- #fim: dml

-- #trecho: dql
-- DQL (Data Query Language): só CONSULTA, não altera nada — SELECT
SELECT codigo, desconto, valido_ate
FROM cupom
WHERE NOT usado
ORDER BY desconto DESC;

-- a mesma DQL serve para as tabelas da base loja
SELECT nome, preco, round(preco * 0.85, 2) AS preco_com_voltaaulas
FROM produto
WHERE id_categoria IN (8, 9)   -- cadernos e escrita
ORDER BY preco;
-- #fim: dql

-- #trecho: dcl
-- DCL (Data Control Language): quem pode fazer o quê — GRANT, REVOKE
CREATE ROLE estagiario NOLOGIN;              -- um papel sem senha, só para o teste
GRANT USAGE ON SCHEMA loja TO estagiario;    -- pode "entrar" no schema
GRANT SELECT, INSERT, UPDATE ON cupom TO estagiario;
REVOKE UPDATE ON cupom FROM estagiario;      -- mudamos de ideia sobre o UPDATE

-- o catálogo mostra as permissões concedidas (no psql: \dp cupom)
SELECT grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_name = 'cupom' AND grantee = 'estagiario'
ORDER BY privilege_type;

-- testando: a sessão passa a agir como se fosse o estagiário
SET ROLE estagiario;
SELECT count(*) AS cupons_que_o_estagiario_ve FROM cupom;
DO $$
BEGIN
    UPDATE cupom SET desconto = 99;
EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'DCL barrou: %', SQLERRM;
END
$$;
RESET ROLE;                                  -- de volta ao usuário original
-- #fim: dcl

-- #trecho: tcl
-- TCL (Transaction Control Language): agrupa comandos numa transação —
-- BEGIN, COMMIT, ROLLBACK, SAVEPOINT
BEGIN;
UPDATE cupom SET desconto = desconto + 5;            -- vale para todos
SAVEPOINT antes_de_apagar;
DELETE FROM cupom;
SELECT count(*) AS cupons_apos_delete FROM cupom;    -- 0
ROLLBACK TO SAVEPOINT antes_de_apagar;               -- desfaz só o DELETE
SELECT count(*) AS cupons_apos_rollback FROM cupom;  -- voltaram
COMMIT;                                              -- confirma o UPDATE

SELECT codigo, desconto FROM cupom ORDER BY codigo;  -- descontos com +5

-- no PostgreSQL até a DDL obedece à transação: o DROP é desfeito
BEGIN;
DROP TABLE cupom;
ROLLBACK;
SELECT count(*) AS cupom_ainda_existe FROM cupom;
-- #fim: tcl

-- limpeza: permissões, tabela e papel
REVOKE ALL ON SCHEMA loja FROM estagiario;
DROP TABLE cupom;              -- leva junto as permissões sobre a tabela
DROP ROLE estagiario;
