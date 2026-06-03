-- DDL: Tabelas para armazenar candidatos diários do bloco Q2 Combinado
-- Criado : 2026-05-18
-- Uso    : Cada execução do blk_q2_combinado insere os candidatos para consulta diária

-- ── Sequence: ID de execução ──────────────────────────────────────────────────
CREATE SEQUENCE seq_claude_exec_id
   START WITH 1
   INCREMENT BY 1
   NOCACHE
   NOCYCLE;

-- ── Tabela 1: Cabeçalho de cada execução ──────────────────────────────────────
CREATE TABLE tb_claude_exec_head (
    id_execucao     NUMBER          DEFAULT seq_claude_exec_id.NEXTVAL,
    dt_referencia   DATE            NOT NULL,   -- data do sorteio analisado
    dt_execucao     DATE            DEFAULT SYSDATE NOT NULL,
    modo_exec       VARCHAR2(10)    NOT NULL,   -- PREDICAO | HISTORICO
    run_label       VARCHAR2(60),
    total_q1        NUMBER,
    total_premios   NUMBER,
    total_nao_prem  NUMBER,
    CONSTRAINT pk_claude_exec PRIMARY KEY (id_execucao)
);

COMMENT ON TABLE  tb_claude_exec_head              IS 'Cabeçalho de cada execução do blk_q2_combinado';
COMMENT ON COLUMN tb_claude_exec_head.dt_referencia IS 'Data do sorteio (v_dt_ini do bloco)';
COMMENT ON COLUMN tb_claude_exec_head.modo_exec       IS 'PREDICAO=candidatos futuros | HISTORICO=validacao passado';

-- ── Tabela 2: Candidatos por execução ─────────────────────────────────────────
CREATE TABLE tb_claude_diario_cand (
    id_cand         NUMBER          GENERATED ALWAYS AS IDENTITY,
    id_execucao     NUMBER          NOT NULL,
    dt_referencia   DATE            NOT NULL,
    id_dados_orbita NUMBER          NOT NULL,   -- ID do candidato a jogar
    filtro          VARCHAR2(20)    NOT NULL,   -- C4r | C3r | C5r | C4a2 | C4c2 | C4c3
    is_premio       VARCHAR2(1)     DEFAULT 'P' NOT NULL,
        -- P=Pendente (PREDICAO, aguardando sorteio)
        -- Y=Sim (HISTORICO, confirmado premiado)
        -- N=Nao (HISTORICO, confirmado nao-premiado)
    premio_valor    NUMBER,                     -- valor do premio se is_premio=Y
    betti_0         NUMBER,                     -- valor betti_0 usado no ranking T2
    dt_ins          DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_claude_cand  PRIMARY KEY (id_cand),
    CONSTRAINT fk_claude_exec  FOREIGN KEY (id_execucao)
        REFERENCES tb_claude_exec_head(id_execucao),
    CONSTRAINT ck_claude_prem  CHECK (is_premio IN ('P','Y','N'))
);

COMMENT ON TABLE  tb_claude_diario_cand                  IS 'Candidatos diários para jogar — gerados pelo blk_q2_combinado';
COMMENT ON COLUMN tb_claude_diario_cand.id_dados_orbita   IS 'ID do candidato (FK para DADOS_ORBITA)';
COMMENT ON COLUMN tb_claude_diario_cand.filtro             IS 'Filtro que gerou o candidato: C4r|C3r|C5r|C4a2|C4c2|C4c3';
COMMENT ON COLUMN tb_claude_diario_cand.is_premio          IS 'P=pendente P|Y=premiado|N=nao-premiado';
COMMENT ON COLUMN tb_claude_diario_cand.betti_0            IS 'Score betti_0 usado no ranking (C4r/C3r/C5r)';

-- ── Índices de consulta ───────────────────────────────────────────────────────
CREATE INDEX ix_claude_cand_dt     ON tb_claude_diario_cand (dt_referencia, filtro);
CREATE INDEX ix_claude_cand_id_orb ON tb_claude_diario_cand (id_dados_orbita);
CREATE INDEX ix_claude_cand_exec   ON tb_claude_diario_cand (id_execucao);

-- ── View de consulta rápida: candidatos de hoje ───────────────────────────────
CREATE OR REPLACE VIEW vw_claude_candidatos_hoje AS
SELECT
    c.dt_referencia,
    c.filtro,
    c.id_dados_orbita,
    c.is_premio,
    c.premio_valor,
    c.betti_0,
    h.v_modo,
    h.run_label,
    h.dt_execucao
FROM tb_claude_diario_cand c
JOIN tb_claude_exec_head   h ON h.id_execucao = c.id_execucao
WHERE c.dt_referencia = TRUNC(SYSDATE)
ORDER BY c.filtro, c.betti_0 DESC NULLS LAST;

COMMENT ON VIEW vw_claude_candidatos_hoje IS 'Candidatos do dia atual — consultar para saber quais IDs jogar';

-- ── View histórico: todos os dias ─────────────────────────────────────────────
CREATE OR REPLACE VIEW vw_claude_historico AS
SELECT
    c.dt_referencia,
    c.filtro,
    c.id_dados_orbita,
    c.is_premio,
    c.premio_valor,
    c.betti_0,
    h.v_modo
FROM tb_claude_diario_cand c
JOIN tb_claude_exec_head   h ON h.id_execucao = c.id_execucao
ORDER BY c.dt_referencia DESC, c.filtro, c.betti_0 DESC NULLS LAST;
