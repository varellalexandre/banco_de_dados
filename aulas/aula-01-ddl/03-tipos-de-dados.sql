-- IMD0401 · Aula 01 · Tópico 03 · Escolher o tipo de dado adequado para cada coluna
--
--   docker compose exec -T pgres psql -U <usuario> -d imd0401 < 03-tipos-de-dados.sql
--
-- Uma tabela por família de tipos, com valores no limite de cada um. No fim,
-- tudo é removido: a base loja sai daqui do jeito que entrou.

SET search_path TO loja, public;
DROP TABLE IF EXISTS tipos_numericos, tipos_texto, tipos_tempo, avaliacao;
DROP TYPE IF EXISTS humor;
DROP DOMAIN IF EXISTS nota_estrela;

-- #trecho: numericos
CREATE TABLE tipos_numericos (
    pequeno    SMALLINT,          -- 2 bytes: -32 768 a 32 767
    inteiro    INTEGER,           -- 4 bytes: cerca de ±2,1 bilhões
    grande     BIGINT,            -- 8 bytes: cerca de ±9,2 quintilhões
    exato      NUMERIC(10,2),     -- 10 dígitos, 2 após a vírgula: dinheiro
    aproximado DOUBLE PRECISION   -- ponto flutuante: medidas, ciência
);

INSERT INTO tipos_numericos VALUES
    (32767, 2147483647, 9223372036854775807, 99999999.99, 0.1),  -- os máximos
    (-5,    0,          42,                  19.999,      1e-10); -- 19.999 vira 20.00

SELECT * FROM tipos_numericos;

-- NUMERIC é exato; ponto flutuante acumula erro de arredondamento
SELECT 0.1::NUMERIC + 0.2::NUMERIC                   = 0.3 AS numeric_acerta,
       0.1::DOUBLE PRECISION + 0.2::DOUBLE PRECISION = 0.3 AS double_acerta;
-- #fim: numericos

-- #trecho: texto
CREATE TABLE tipos_texto (
    uf    CHAR(2),       -- tamanho fixo: completa com espaços
    nome  VARCHAR(12),   -- tamanho variável, com limite
    obs   TEXT           -- tamanho variável, sem limite
);

INSERT INTO tipos_texto VALUES
    ('RN', 'Natal',       'Capital do Rio Grande do Norte'),
    ('P',  'Pipa',        NULL),
    ('PB', 'João Pessoa', 'TEXT aceita textos de qualquer tamanho');

-- CHAR(2) guarda 'P ' (com espaço); VARCHAR guarda só o que foi digitado
SELECT uf, octet_length(uf) AS bytes_uf, nome, length(nome) AS letras_nome
FROM tipos_texto;
-- #fim: texto

-- #trecho: tempo
CREATE TABLE tipos_tempo (
    dia        DATE,          -- só a data
    hora       TIME,          -- só a hora
    momento    TIMESTAMP,     -- data e hora, sem fuso horário
    momento_tz TIMESTAMPTZ,   -- data e hora com fuso: o indicado para eventos
    duracao    INTERVAL       -- um intervalo de tempo
);

INSERT INTO tipos_tempo VALUES
    ('2026-10-13', '19:30', '2026-10-13 19:30', '2026-10-13 19:30-03', '2 hours 30 minutes');

-- aritmética de datas: o tipo certo faz a conta certa
SELECT dia + 30                        AS dia_mais_30,
       DATE '2027-01-01' - dia         AS dias_ate_2027,
       momento + duracao               AS termina_em,
       momento_tz AT TIME ZONE 'UTC'   AS em_utc
FROM tipos_tempo;
-- #fim: tempo

-- #trecho: outros
-- ENUM: uma lista fechada de valores, com ordem
CREATE TYPE humor AS ENUM ('ruim', 'regular', 'bom', 'otimo');
-- DOMAIN: um tipo existente + uma restrição, reaproveitável em várias tabelas
CREATE DOMAIN nota_estrela AS SMALLINT CHECK (VALUE BETWEEN 1 AND 5);

CREATE TABLE avaliacao (
    id_avaliacao UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    id_produto   INTEGER      NOT NULL REFERENCES produto (id_produto),
    estrelas     nota_estrela NOT NULL,
    sentimento   humor,
    recomenda    BOOLEAN      NOT NULL DEFAULT true,
    tags         TEXT[],                          -- vetor de textos
    detalhes     JSONB,                           -- documento JSON
    criada_em    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

INSERT INTO avaliacao (id_produto, estrelas, sentimento, recomenda, tags, detalhes) VALUES
    ( 1, 5, 'otimo',   true,  ARRAY['rápido', 'leve'], '{"uso": "trabalho", "meses": 6}'),
    ( 4, 3, 'regular', true,  ARRAY['pilha'],          '{"uso": "casa"}'),
    (14, 2, 'ruim',    false, NULL,                    '{"uso": "academia", "defeito": "chiado"}'),
    (26, 4, 'bom',     true,  ARRAY['prático'],        '{"uso": "casa", "meses": 2}');

SELECT p.nome,
       a.estrelas,
       a.sentimento,
       a.tags[1]              AS primeira_tag,
       a.detalhes ->> 'uso'   AS uso
FROM avaliacao a
JOIN produto p USING (id_produto)
WHERE a.sentimento >= 'regular'         -- ENUM compara pela ordem declarada
ORDER BY a.estrelas DESC;

-- pg_typeof mostra o tipo de qualquer expressão
SELECT pg_typeof(42)           AS inteiro,
       pg_typeof(42.0)         AS decimal,
       pg_typeof(current_date) AS data,
       pg_typeof(now())        AS agora,
       pg_typeof(true)         AS logico;
-- #fim: outros

-- Valores que não cabem no tipo, um por vez, dentro de um bloco que captura
-- o erro: o script segue rodando e mostra a mensagem.
DO $$
BEGIN
    BEGIN
        INSERT INTO tipos_numericos (pequeno) VALUES (40000);
    EXCEPTION WHEN numeric_value_out_of_range THEN
        RAISE NOTICE 'SMALLINT estourou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO tipos_numericos (exato) VALUES (123456789.00);
    EXCEPTION WHEN numeric_value_out_of_range THEN
        RAISE NOTICE 'NUMERIC(10,2) estourou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO tipos_texto (nome) VALUES ('São Gonçalo do Amarante');
    EXCEPTION WHEN string_data_right_truncation THEN
        RAISE NOTICE 'VARCHAR(12) estourou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO tipos_tempo (dia) VALUES ('2026-02-30');
    EXCEPTION WHEN datetime_field_overflow THEN
        RAISE NOTICE 'DATE inválida: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO avaliacao (id_produto, estrelas, sentimento) VALUES (1, 4, 'péssimo');
    EXCEPTION WHEN invalid_text_representation THEN
        RAISE NOTICE 'ENUM barrou: %', SQLERRM;
    END;
    BEGIN
        INSERT INTO avaliacao (id_produto, estrelas) VALUES (1, 6);
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'DOMAIN barrou: %', SQLERRM;
    END;
END
$$;

-- limpeza: primeiro as tabelas, depois os tipos que elas usam
DROP TABLE tipos_numericos, tipos_texto, tipos_tempo, avaliacao;
DROP TYPE humor;
DROP DOMAIN nota_estrela;
