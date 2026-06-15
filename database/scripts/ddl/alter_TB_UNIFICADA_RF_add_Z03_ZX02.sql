-- =============================================================================
-- Script.....: alter_TB_UNIFICADA_RF_add_Z03_ZX02.sql
-- Objetivo...: Propaga as colunas de Informacoes Adicionais (infCpl) e
--              Suplementares (qrCode da NFC-e) para a tabela unificada,
--              alimentada por PRC_NFE_UNIFICAR_DADOS.
-- Tabela.....: USER_XMLS.TB_UNIFICADA_RF
--
-- Historico:
--   v1.0.0 - 2026-06-15 - Adiciona Z03_INFCPL e ZX02_QRCODE
-- =============================================================================

ALTER TABLE USER_XMLS.TB_UNIFICADA_RF ADD (
   Z03_INFCPL    VARCHAR2(4000),   -- Grupo Z  - infAdic/infCpl  (informacoes complementares)
   ZX02_QRCODE   VARCHAR2(1000)    -- Grupo ZX - infNFeSupl/qrCode (QR Code - somente NFC-e mod 65)
);

COMMENT ON COLUMN USER_XMLS.TB_UNIFICADA_RF.Z03_INFCPL  IS 'NF-e grupo Z (Z03) - infAdic/infCpl: informacoes complementares. Propagado de TB_REFORMA_CONSOLIDADA.';
COMMENT ON COLUMN USER_XMLS.TB_UNIFICADA_RF.ZX02_QRCODE IS 'NF-e grupo ZX (ZX02) - infNFeSupl/qrCode: URL do QR Code (somente NFC-e). Propagado de TB_REFORMA_CONSOLIDADA.';
