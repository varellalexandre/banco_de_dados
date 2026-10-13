-- IMD0401 · Aula 8 · DDL: criar, alterar e remover tabelas
--
-- Script completo e executável sobre a base loja (sql_course/base/loja.sql):
--
--   docker compose -f compose-postgres.yml exec -T pgres \
--     psql -U user_test -d imd0401 < sql_course/aulas/aula_8/codigos/ddl.sql
--
-- Cria três tabelas novas (fornecedor, fornecimento e contato_fornecedor),
-- mexe nelas e no fim as remove: a base loja sai daqui do jeito que entrou.

SET search_path TO loja, public;
DROP TABLE IF EXISTS contato, contato_fornecedor;
DROP TABLE IF EXISTS fornecimento;
DROP TABLE IF EXISTS fornecedor;

-- #trecho: create
CREATE TABLE fornecedor (
    id_fornecedor INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cnpj          CHAR(14)     NOT NULL UNIQUE,
    razao_social  VARCHAR(80)  NOT NULL,
    cidade        VARCHAR(40)  NOT NULL DEFAULT 'Natal',
    prazo_dias    INTEGER      CHECK (prazo_dias BETWEEN 1 AND 90),
    cadastrado_em DATE         NOT NULL DEFAULT current_date,
    -- restrição de tabela, com nome: aparece assim nas mensagens de erro
    CONSTRAINT cnpj_so_digitos CHECK (cnpj ~ '^[0-9]{14}$')
);
-- #fim: create

-- #trecho: fk
-- tabela associativa: quem fornece qual produto, e a que custo
CREATE TABLE fornecimento (
    id_fornecedor INTEGER NOT NULL
        REFERENCES fornecedor (id_fornecedor) ON DELETE CASCADE,
    id_produto    INTEGER NOT NULL
        REFERENCES produto (id_produto) ON DELETE RESTRICT,
    custo         NUMERIC(10,2) NOT NULL CHECK (custo > 0),
    PRIMARY KEY (id_fornecedor, id_produto)
);
-- #fim: fk

-- #trecho: restricoes_nomeadas
-- relacionamento 1:N (um fornecedor, vários contatos) com todas as
-- restrições declaradas no fim, cada uma com nome próprio
CREATE TABLE contato_fornecedor (
    id_contato    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_fornecedor INTEGER     NOT NULL,
    tipo          VARCHAR(10) NOT NULL,
    valor         VARCHAR(80) NOT NULL,
    CONSTRAINT contato_fornecedor_fk FOREIGN KEY (id_fornecedor)
        REFERENCES fornecedor (id_fornecedor) ON DELETE CASCADE,
    CONSTRAINT contato_tipo_valido CHECK (tipo IN ('email', 'telefone', 'site')),
    CONSTRAINT contato_unico UNIQUE (id_fornecedor, tipo, valor)
);
-- #fim: restricoes_nomeadas

INSERT INTO fornecedor (cnpj, razao_social, prazo_dias)
VALUES ('11222333000181', 'Distribuidora Seridó', 30);

-- #trecho: desafio
INSERT INTO fornecedor (cnpj, razao_social, prazo_dias)
VALUES ('44555666000172', 'Papel & Cia', NULL);
-- #fim: desafio

-- #trecho: insert_varios
-- várias linhas num só INSERT; quem não informa a cidade fica com o DEFAULT
INSERT INTO fornecedor (cnpj, razao_social, cidade, prazo_dias) VALUES
    ('12345678000190', 'Eletrônicos Potengi',    'Natal',      15),  -- 3
    ('23456789000101', 'Atacado Mossoró',        'Mossoró',    45),  -- 4
    ('34567890000112', 'Utilidades Caicó',       'Caicó',      20),  -- 5
    ('45678901000123', 'Tech Parnamirim',        'Parnamirim', 10);  -- 6

INSERT INTO fornecedor (cnpj, razao_social, prazo_dias)
VALUES ('56789012000134', 'Gráfica Ponta Negra', 25);                -- 7, Natal
-- #fim: insert_varios

-- os ids de produto são os da base loja (veja os comentários em loja.sql)
INSERT INTO fornecimento (id_fornecedor, id_produto, custo) VALUES
    -- 1 · Distribuidora Seridó: papelaria
    (1, 17,   18.50), (1, 18,    8.70), (1, 20,    1.10),
    (1, 21,    0.80), (1, 22,    2.60),
    -- 2 · Papel & Cia: papelaria e material escolar
    (2, 17,   17.90), (2, 18,    9.00), (2, 19,   22.00),
    (2, 23,   13.50), (2, 24,   95.00),
    -- 3 · Eletrônicos Potengi: informática
    (3,  1, 2900.00), (3,  4,   42.00), (3,  5,  210.00),
    (3,  6,  610.00), (3,  9,  300.00), (3, 14,  120.00),
    -- 4 · Atacado Mossoró: celulares e acessórios
    (4, 10,  950.00), (4, 12,   15.00), (4, 13,   48.00),
    (4, 25,   55.00),
    -- 5 · Utilidades Caicó: casa
    (5, 26,  150.00), (5, 27,  120.00), (5, 28,   38.00),
    (5, 29,   70.00),
    -- 6 · Tech Parnamirim: informática, celulares e áudio
    (6,  2, 4300.00), (6,  3, 1650.00), (6,  7,  110.00),
    (6,  8,   26.00), (6, 11, 2500.00), (6, 15,  180.00),
    (6, 16,  160.00),
    -- 7 · Gráfica Ponta Negra: papelaria (concorre com 1 e 2)
    (7, 17,   19.20), (7, 19,   21.50), (7, 20,    0.95);

-- contatos fictícios (domínio .example é reservado e nunca existe de verdade)
INSERT INTO contato_fornecedor (id_fornecedor, tipo, valor) VALUES
    (1, 'email',    'vendas@serido.example'),
    (1, 'telefone', '(84) 3000-0001'),
    (2, 'email',    'contato@papelecia.example'),
    (3, 'email',    'comercial@potengi.example'),
    (3, 'site',     'www.potengi.example'),
    (4, 'telefone', '(84) 3000-0004'),
    (5, 'email',    'pedidos@caico.example'),
    (6, 'email',    'vendas@techparnamirim.example'),
    (6, 'telefone', '(84) 3000-0006'),
    (7, 'site',     'www.graficapontanegra.example');

-- A violação de cada restrição, uma por vez, dentro de um bloco que captura
-- o erro: o script segue rodando e mostra a mensagem.
DO $$
BEGIN
    BEGIN
        INSERT INTO fornecedor (cnpj, razao_social, prazo_dias)
        VALUES ('11222333000181', 'CNPJ repetido', 10);
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'UNIQUE barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO fornecedor (cnpj, razao_social, prazo_dias)
        VALUES ('77888999000163', 'Prazo longo', 120);
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO fornecedor (cnpj, razao_social, prazo_dias)
        VALUES ('ABC', 'CNPJ com letras', 10);
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK nomeado barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO fornecedor (cnpj, razao_social, prazo_dias)
        VALUES ('99888777000155', NULL, 10);
    EXCEPTION WHEN not_null_violation THEN
        RAISE NOTICE 'NOT NULL barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO fornecimento VALUES (1, 17, 20.00);
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PRIMARY KEY barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO fornecimento VALUES (3, 20, 0.00);
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK do custo barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO fornecimento VALUES (1, 999, 10.00);
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'FK barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO contato_fornecedor (id_fornecedor, tipo, valor)
        VALUES (1, 'fax', '(84) 3000-0009');
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK do tipo barrou: %', SQLERRM;
    END;
    BEGIN
        DELETE FROM produto WHERE id_produto = 18;
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'FK barrou a remoção: %', SQLERRM;
    END;
END
$$;

-- #trecho: cascade
-- ON DELETE CASCADE: remover o fornecedor 7 leva junto o que depende dele
SELECT count(*) AS fornecimentos_do_7 FROM fornecimento WHERE id_fornecedor = 7;
SELECT count(*) AS contatos_do_7 FROM contato_fornecedor WHERE id_fornecedor = 7;
DELETE FROM fornecedor WHERE id_fornecedor = 7;
SELECT count(*) AS fornecimentos_do_7 FROM fornecimento WHERE id_fornecedor = 7;  -- 0
SELECT count(*) AS contatos_do_7 FROM contato_fornecedor WHERE id_fornecedor = 7; -- 0
-- #fim: cascade

-- #trecho: alter
ALTER TABLE fornecedor ADD COLUMN email VARCHAR(80);
ALTER TABLE fornecedor ADD CONSTRAINT email_unico UNIQUE (email);
ALTER TABLE fornecedor ALTER COLUMN prazo_dias SET DEFAULT 30;
UPDATE fornecedor SET prazo_dias = 30 WHERE prazo_dias IS NULL;
ALTER TABLE fornecedor ALTER COLUMN prazo_dias SET NOT NULL;
ALTER TABLE fornecedor RENAME COLUMN razao_social TO nome;
ALTER TABLE fornecedor DROP COLUMN email;
-- #fim: alter

-- #trecho: alter_mais
-- coluna nova com DEFAULT: as linhas que já existem recebem o valor padrão
ALTER TABLE fornecedor ADD COLUMN ativo BOOLEAN NOT NULL DEFAULT true;
UPDATE fornecedor SET ativo = false WHERE id_fornecedor = 5;

-- mudar o tipo: aumentar o tamanho é sempre seguro
ALTER TABLE fornecedor ALTER COLUMN cidade TYPE VARCHAR(60);
ALTER TABLE fornecimento ALTER COLUMN custo TYPE NUMERIC(12,2);

-- acrescentar e retirar uma restrição pelo nome
ALTER TABLE fornecimento ADD COLUMN prazo_entrega INTEGER;
ALTER TABLE fornecimento
    ADD CONSTRAINT prazo_entrega_positivo CHECK (prazo_entrega > 0);
UPDATE fornecimento f
SET prazo_entrega = fo.prazo_dias
FROM fornecedor fo
WHERE fo.id_fornecedor = f.id_fornecedor;
ALTER TABLE fornecimento DROP CONSTRAINT prazo_entrega_positivo;

-- renomear a tabela inteira
ALTER TABLE contato_fornecedor RENAME TO contato;
-- #fim: alter_mais

-- #trecho: indice_comentario
-- índice para acelerar a busca "quem fornece o produto X?"
CREATE INDEX idx_fornecimento_produto ON fornecimento (id_produto);

-- comentários ficam guardados no catálogo e aparecem no \d+ do psql
COMMENT ON TABLE fornecedor IS 'Empresas que abastecem a rede Potiguar';
COMMENT ON COLUMN fornecedor.prazo_dias IS 'Prazo de pagamento, em dias';
COMMENT ON TABLE fornecimento IS 'Quem fornece qual produto, e a que custo';
-- #fim: indice_comentario

SELECT * FROM fornecedor ORDER BY id_fornecedor;

-- #trecho: consulta
-- as tabelas novas já conversam com as da base loja
SELECT f.nome  AS fornecedor,
       p.nome  AS produto,
       fo.custo,
       p.preco,
       p.preco - fo.custo AS margem
FROM fornecimento fo
JOIN fornecedor f USING (id_fornecedor)
JOIN produto    p USING (id_produto)
WHERE f.ativo
ORDER BY f.nome, p.nome;
-- #fim: consulta

-- #trecho: catalogo
-- o próprio banco descreve as restrições que criamos (os NOT NULL também
-- aparecem lá, como CHECK de nome interno: o filtro os esconde)
SELECT table_name, constraint_name, constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'loja'
  AND table_name IN ('fornecedor', 'fornecimento', 'contato')
  AND constraint_name NOT LIKE '%not_null'
ORDER BY table_name, constraint_type, constraint_name;
-- #fim: catalogo

-- DROP sem CASCADE recusa remover uma tabela da qual outra depende
DO $$
BEGIN
    DROP TABLE fornecedor;
EXCEPTION WHEN dependent_objects_still_exist THEN
    RAISE NOTICE 'DROP barrou: %', SQLERRM;
END
$$;

-- #trecho: remover
DELETE FROM fornecimento WHERE custo > 10;  -- algumas linhas (DML)
TRUNCATE fornecimento;                      -- todas as linhas, de uma vez
DROP TABLE fornecimento;                    -- a tabela inteira some
DROP TABLE contato;                         -- depende de fornecedor: sai antes
DROP TABLE IF EXISTS fornecedor;            -- sem erro se já não existir
-- #fim: remover
