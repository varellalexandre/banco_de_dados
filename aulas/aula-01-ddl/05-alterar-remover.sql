-- IMD0401 · Aula 01 · Tópico 05 · Alterar e remover estruturas com ALTER, TRUNCATE e DROP
--
--   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 05-alterar-remover.sql
--
-- Complementa o ddl.sql. Trabalha sobre CÓPIAS de tabelas da base loja, num
-- schema de rascunho que é apagado no fim: a base loja sai daqui do jeito
-- que entrou.

DROP SCHEMA IF EXISTS rascunho CASCADE;

-- #trecho: copiar
-- um schema só para os testes; as tabelas originais ficam em loja
CREATE SCHEMA rascunho;
SET search_path TO rascunho, loja, public;   -- o que for criado vai para rascunho

-- LIKE copia a estrutura (colunas, DEFAULT, CHECK, índices), mas não as FKs
CREATE TABLE produto_copia (LIKE loja.produto INCLUDING ALL);
INSERT INTO produto_copia SELECT * FROM loja.produto;

-- CREATE TABLE AS copia o resultado de uma consulta, sem restrição nenhuma
CREATE TABLE resumo_categoria AS
SELECT id_categoria, count(*) AS qtd_produtos, round(avg(preco), 2) AS preco_medio
FROM loja.produto
GROUP BY id_categoria;

SELECT * FROM resumo_categoria ORDER BY id_categoria;
-- #fim: copiar

-- #trecho: alter_tipo
-- Trocar BOOLEAN por CHAR(1) ('S'/'N'): o USING diz como converter cada valor.
-- O DEFAULT antigo (true) não vira 'S' sozinho: sai antes e volta depois.
ALTER TABLE produto_copia ALTER COLUMN ativo DROP DEFAULT;
ALTER TABLE produto_copia
    ALTER COLUMN ativo TYPE CHAR(1)
    USING CASE WHEN ativo THEN 'S' ELSE 'N' END;
ALTER TABLE produto_copia ALTER COLUMN ativo SET DEFAULT 'S';
ALTER TABLE produto_copia
    ADD CONSTRAINT ativo_s_ou_n CHECK (ativo IN ('S', 'N'));

SELECT nome, ativo FROM produto_copia WHERE id_produto IN (1, 30);
-- #fim: alter_tipo

-- #trecho: alter_restricoes
-- NOT NULL e DEFAULT também se retiram
ALTER TABLE resumo_categoria ALTER COLUMN qtd_produtos SET NOT NULL;
ALTER TABLE resumo_categoria ALTER COLUMN qtd_produtos DROP NOT NULL;
ALTER TABLE resumo_categoria ADD PRIMARY KEY (id_categoria);

-- renomear uma restrição
ALTER TABLE produto_copia RENAME CONSTRAINT ativo_s_ou_n TO produto_ativo_valido;

-- NOT VALID: a restrição vale para as linhas NOVAS; as antigas não são checadas
ALTER TABLE produto_copia
    ADD CONSTRAINT preco_ate_5000 CHECK (preco <= 5000) NOT VALID;
-- #fim: alter_restricoes

DO $$
BEGIN
    BEGIN
        -- o Notebook Aurora 15 Pro custa 5499: a validação encontra a linha antiga
        ALTER TABLE produto_copia VALIDATE CONSTRAINT preco_ate_5000;
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'VALIDATE barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO produto_copia (id_produto, nome, id_categoria, preco)
        VALUES (31, 'Notebook Gamer', 3, 9999.00);
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'NOT VALID já vale para linhas novas: %', SQLERRM;
    END;
END
$$;

-- #trecho: validar
UPDATE produto_copia SET preco = 4999.00 WHERE preco > 5000;
ALTER TABLE produto_copia VALIDATE CONSTRAINT preco_ate_5000;   -- agora passa
-- #fim: validar

-- #trecho: drop_dependencia
-- uma visão que depende da coluna preco
CREATE VIEW vitrine AS
SELECT nome, preco FROM produto_copia WHERE ativo = 'S';
-- #fim: drop_dependencia

DO $$
BEGIN
    ALTER TABLE produto_copia DROP COLUMN preco;
EXCEPTION WHEN dependent_objects_still_exist THEN
    RAISE NOTICE 'DROP COLUMN barrou: %', SQLERRM;
END
$$;

-- #trecho: drop_cascade
ALTER TABLE produto_copia DROP COLUMN preco CASCADE;   -- leva a visão junto
SELECT count(*) AS visoes_restantes
FROM information_schema.views
WHERE table_schema = 'rascunho';                       -- 0
-- #fim: drop_cascade

-- #trecho: truncate
CREATE TABLE lista (
    id_lista INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome     VARCHAR(40) NOT NULL
);
CREATE TABLE item_lista (
    id_lista   INTEGER NOT NULL REFERENCES lista (id_lista),
    id_produto INTEGER NOT NULL,
    PRIMARY KEY (id_lista, id_produto)
);
INSERT INTO lista (nome) VALUES ('Volta às aulas'), ('Home office'), ('Cozinha');
INSERT INTO item_lista VALUES (1, 17), (1, 20), (2, 6), (3, 26);

-- TRUNCATE comum: as linhas somem, mas a numeração continua de onde parou.
-- As duas tabelas vão no mesmo comando: assim a FK continua satisfeita.
TRUNCATE item_lista, lista;
INSERT INTO lista (nome) VALUES ('Nova lista');
SELECT id_lista, nome FROM lista;                       -- id 4

-- RESTART IDENTITY: zera a numeração
TRUNCATE item_lista, lista RESTART IDENTITY;
INSERT INTO lista (nome) VALUES ('Recomeço');
SELECT id_lista, nome FROM lista;                       -- id 1
INSERT INTO item_lista VALUES (1, 17);
-- #fim: truncate

DO $$
BEGIN
    TRUNCATE lista;   -- item_lista aponta para lista
EXCEPTION WHEN feature_not_supported THEN
    RAISE NOTICE 'TRUNCATE barrou: %', SQLERRM;
END
$$;

-- #trecho: truncate_cascade
TRUNCATE lista CASCADE;                                 -- esvazia item_lista também
SELECT (SELECT count(*) FROM lista)      AS linhas_lista,
       (SELECT count(*) FROM item_lista) AS linhas_item_lista;
-- #fim: truncate_cascade

-- #trecho: drop
-- mover uma tabela de schema e renomeá-la
ALTER TABLE resumo_categoria SET SCHEMA public;
ALTER TABLE public.resumo_categoria RENAME TO resumo_categoria_old;
DROP TABLE public.resumo_categoria_old;

-- vários objetos de uma vez; IF EXISTS evita erro se algum já não existir
DROP TABLE IF EXISTS item_lista, lista, tabela_que_nao_existe;

-- DROP SCHEMA ... CASCADE apaga o schema e TUDO o que está dentro dele
\dt rascunho.*
DROP SCHEMA rascunho CASCADE;
-- #fim: drop

SET search_path TO loja, public;
