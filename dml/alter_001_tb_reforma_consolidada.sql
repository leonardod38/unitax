-- ============================================================
-- Tipo    : ALTER TABLE
-- Objeto  : TB_REFORMA_CONSOLIDADA
-- Schema  : USER_XMLS
-- Arquivo : alter_001_tb_reforma_consolidada.sql
-- Descricao: Script de alteracao para aplicar em banco existente.
--            Nao executar em instalacao nova — o campo ja consta
--            no CREATE TABLE de ddl_tb_reforma_consolidada.sql.
-- ------------------------------------------------------------
-- Historico de alteracoes:
-- 001 - 2026-06-03 - Adicionado campo I16_VFRETE (frete por
--                    item extraído de prod/vFrete da NF-e)
-- ============================================================

-- 001 - ajuste no campo frete
ALTER TABLE TB_REFORMA_CONSOLIDADA ADD (I16_VFRETE NUMBER)
/
