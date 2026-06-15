-- =============================================================================
-- Script.....: alter_TB_REFORMA_CONSOLIDADA_add_Z03_ZX02.sql
-- Objetivo...: Acrescenta as colunas de Informacoes Adicionais (infCpl) e
--              Informacoes Suplementares (qrCode da NFC-e) na consolidada.
-- Tabela.....: USER_XMLS.TB_REFORMA_CONSOLIDADA
--
-- Historico:
--   v1.0.0 - 2026-06-15 - Adiciona Z03_INFCPL e ZX02_QRCODE
-- =============================================================================

ALTER TABLE USER_XMLS.TB_REFORMA_CONSOLIDADA ADD (
   Z03_INFCPL    VARCHAR2(4000),   -- Grupo Z  - infAdic/infCpl  (informacoes complementares)
   ZX02_QRCODE   VARCHAR2(1000)    -- Grupo ZX - infNFeSupl/qrCode (QR Code - somente NFC-e mod 65)
);

COMMENT ON COLUMN USER_XMLS.TB_REFORMA_CONSOLIDADA.Z03_INFCPL  IS 'NF-e grupo Z (Z03) - infAdic/infCpl: informacoes complementares de interesse do contribuinte.';
COMMENT ON COLUMN USER_XMLS.TB_REFORMA_CONSOLIDADA.ZX02_QRCODE IS 'NF-e grupo ZX (ZX02) - infNFeSupl/qrCode: URL do QR Code. Presente apenas em NFC-e (mod 65); NULL nos demais modelos.';
