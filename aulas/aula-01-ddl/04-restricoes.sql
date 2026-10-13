-- IMD0401 · Aula 01 · Tópico 04 · Declarar tabelas com chaves e restrições de integridade
--
--   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 04-restricoes.sql
--
-- Complementa o ddl.sql com chaves e restrições que ele não usa: FK para a
-- própria tabela, ON DELETE SET NULL, FK composta, CHECK entre colunas,
-- coluna gerada e UNIQUE parcial. No fim, tudo é removido: a base loja sai
-- daqui do jeito que entrou.

SET search_path TO loja, public;
DROP TABLE IF EXISTS setor, promocao, movimentacao, endereco_cliente;

-- #trecho: autorreferencia
-- FK para a própria tabela: cada setor pode ter um setor "pai".
-- ON DELETE SET NULL: se o pai sumir, o filho fica sem pai (NULL), mas fica.
CREATE TABLE setor (
    id_setor     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome         VARCHAR(40) NOT NULL UNIQUE,
    id_setor_pai INTEGER REFERENCES setor (id_setor) ON DELETE SET NULL
);

INSERT INTO setor (nome, id_setor_pai) VALUES
    ('Operações', NULL),   -- 1
    ('Logística', 1),      -- 2
    ('Vendas',    1),      -- 3
    ('Expedição', 2),      -- 4
    ('Televendas', 3);     -- 5

DELETE FROM setor WHERE nome = 'Operações';
SELECT * FROM setor ORDER BY id_setor;   -- Logística e Vendas ficaram com pai NULL
-- #fim: autorreferencia

-- #trecho: check_colunas
-- CHECK entre colunas (só pode ser de tabela) e coluna gerada pelo banco
CREATE TABLE promocao (
    id_promocao INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_produto  INTEGER      NOT NULL
        REFERENCES produto (id_produto) ON DELETE CASCADE,
    percentual  NUMERIC(5,2) NOT NULL CHECK (percentual > 0 AND percentual <= 70),
    inicio      DATE         NOT NULL,
    fim         DATE         NOT NULL,
    dias        INTEGER      GENERATED ALWAYS AS (fim - inicio + 1) STORED,
    CONSTRAINT periodo_valido  CHECK (fim >= inicio),
    CONSTRAINT promocao_unica  UNIQUE (id_produto, inicio)
);

INSERT INTO promocao (id_produto, percentual, inicio, fim) VALUES
    (17, 20, '2027-01-15', '2027-02-28'),   -- volta às aulas: cadernos
    (18, 20, '2027-01-15', '2027-02-28'),
    (24, 15, '2027-01-15', '2027-02-28'),   -- mochila
    ( 1, 10, '2026-11-27', '2026-11-27'),   -- black friday: um dia só
    (10,  5, '2026-12-01', '2026-12-24');

SELECT p.nome, pr.percentual, pr.inicio, pr.fim, pr.dias
FROM promocao pr JOIN produto p USING (id_produto)
ORDER BY pr.inicio, p.nome;
-- #fim: check_colunas

-- #trecho: fk_composta
-- FK composta: o par (loja, produto) precisa existir no estoque.
-- A FK para funcionário usa ON DELETE SET NULL: o histórico não se perde.
CREATE TABLE movimentacao (
    id_movimentacao INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_loja         INTEGER   NOT NULL,
    id_produto      INTEGER   NOT NULL,
    quantidade      INTEGER   NOT NULL CHECK (quantidade <> 0),  -- + entra, - sai
    id_funcionario  INTEGER
        REFERENCES funcionario (id_funcionario) ON DELETE SET NULL,
    registrada_em   TIMESTAMP NOT NULL DEFAULT now(),
    CONSTRAINT movimentacao_estoque_fk FOREIGN KEY (id_loja, id_produto)
        REFERENCES estoque (id_loja, id_produto) ON DELETE CASCADE
);

-- o estoque da base é sorteado: pegamos pares (loja, produto) que existem
INSERT INTO movimentacao (id_loja, id_produto, quantidade)
SELECT id_loja, id_produto, 10
FROM estoque
WHERE id_loja = 1
ORDER BY id_produto
LIMIT 3;

SELECT id_loja, id_produto, quantidade FROM movimentacao ORDER BY id_movimentacao;
-- #fim: fk_composta

-- #trecho: unique_parcial
-- Um cliente pode ter vários endereços, mas só UM principal.
-- O índice único parcial (com WHERE) garante isso.
CREATE TABLE endereco_cliente (
    id_endereco INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_cliente  INTEGER     NOT NULL
        REFERENCES cliente (id_cliente) ON DELETE CASCADE,
    tipo        VARCHAR(10) NOT NULL DEFAULT 'casa'
        CHECK (tipo IN ('casa', 'trabalho', 'outro')),
    cep         CHAR(8)     NOT NULL CHECK (cep ~ '^[0-9]{8}$'),
    numero      VARCHAR(10) NOT NULL DEFAULT 'S/N',
    principal   BOOLEAN     NOT NULL DEFAULT false
);
CREATE UNIQUE INDEX um_principal_por_cliente
    ON endereco_cliente (id_cliente) WHERE principal;

INSERT INTO endereco_cliente (id_cliente, tipo, cep, numero, principal) VALUES
    (1, 'casa',     '59000000', '100', true),
    (1, 'trabalho', '59000001', '200', false),
    (2, 'casa',     '59600000', 'S/N', true);
-- #fim: unique_parcial

-- A violação de cada restrição, uma por vez, dentro de um bloco que captura
-- o erro: o script segue rodando e mostra a mensagem.
DO $$
BEGIN
    BEGIN
        INSERT INTO setor (nome, id_setor_pai) VALUES ('Fantasma', 99);
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'FK autorreferente barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO promocao (id_produto, percentual, inicio, fim)
        VALUES (20, 10, '2027-03-10', '2027-03-01');
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK entre colunas barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO promocao (id_produto, percentual, inicio, fim)
        VALUES (20, 90, '2027-03-01', '2027-03-10');
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK do percentual barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO promocao (id_produto, percentual, inicio, fim)
        VALUES (17, 25, '2027-01-15', '2027-01-31');
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'UNIQUE composto barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO promocao (id_produto, percentual, inicio, fim, dias)
        VALUES (20, 10, '2027-03-01', '2027-03-10', 99);
    EXCEPTION WHEN generated_always THEN
        RAISE NOTICE 'Coluna gerada barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO movimentacao (id_loja, id_produto, quantidade) VALUES (99, 1, 5);
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'FK composta barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO movimentacao (id_loja, id_produto, quantidade)
        SELECT id_loja, id_produto, 0 FROM estoque LIMIT 1;
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK da quantidade barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO endereco_cliente (id_cliente, cep, principal)
        VALUES (1, '59000002', true);
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'UNIQUE parcial barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO endereco_cliente (id_cliente, cep) VALUES (3, '5900-000');
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'CHECK do CEP barrou: %', SQLERRM;
    END;
END
$$;

-- um segundo endereço NÃO principal para o cliente 1 é aceito
INSERT INTO endereco_cliente (id_cliente, tipo, cep) VALUES (1, 'outro', '59000003');
SELECT id_cliente, tipo, cep, numero, principal
FROM endereco_cliente
ORDER BY id_cliente, principal DESC, tipo;

DROP TABLE setor, promocao, movimentacao, endereco_cliente;
