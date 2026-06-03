-- ============================================================
-- Tipo    : TABLE
-- Objeto  : TB_REFORMA_CONSOLIDADA
-- Schema  : USER_XMLS
-- Descricao: Tabela de staging das NF-e consolidadas.
--            Armazena emitente, destinatario, itens e
--            tributos (ICMS, IPI, PIS, COFINS) extraídos
--            do XML via PRC_NFE_REFORMA_CONSOLIDADA e
--            PRC_LOTE_NFE_REFORMA_CONSOLIDADA.
-- ------------------------------------------------------------
-- Historico de alteracoes:
-- 001 - 2026-06-03 - Adicionado campo I16_VFRETE (frete por
--                    item extraído de prod/vFrete da NF-e)
-- ============================================================
-- ATENCAO: Nunca executar DROP TABLE em producao.
--          Para adicionar campos, usar ALTER TABLE (secao abaixo).
-- ============================================================

CREATE TABLE TB_REFORMA_CONSOLIDADA
(
  TIPO_DOCUMENTO      VARCHAR2(10 BYTE),
  CHAVE_ACESSO        VARCHAR2(44 BYTE),
  NUMERO_NF           VARCHAR2(20 BYTE),
  DATA_EMISSAO_NFE    VARCHAR2(10 BYTE),
  NITEM               NUMBER,
  -- Emitente
  C02_CNPJ            VARCHAR2(14 BYTE),
  C02A_CPF            VARCHAR2(11 BYTE),
  C03_XNOME           VARCHAR2(60 BYTE),
  C04_XFANT           VARCHAR2(60 BYTE),
  C05_XLGR            VARCHAR2(60 BYTE),
  C05_NRO             VARCHAR2(60 BYTE),
  C05_XCPL            VARCHAR2(60 BYTE),
  C05_XBAIRRO         VARCHAR2(60 BYTE),
  C05_CMUN            VARCHAR2(7 BYTE),
  C05_XMUN            VARCHAR2(60 BYTE),
  C05_UF              VARCHAR2(2 BYTE),
  C05_CEP             VARCHAR2(8 BYTE),
  C05_CPAIS           VARCHAR2(4 BYTE),
  C05_XPAIS           VARCHAR2(60 BYTE),
  C05_FONE            VARCHAR2(14 BYTE),
  C17_IE              VARCHAR2(14 BYTE),
  C18_IEST            VARCHAR2(14 BYTE),
  C19_IM              VARCHAR2(15 BYTE),
  C20_CNAE            VARCHAR2(7 BYTE),
  C21_CRT             VARCHAR2(1 BYTE),
  -- Destinatário
  E02_CNPJ            VARCHAR2(14 BYTE),
  E03_CPF             VARCHAR2(11 BYTE),
  E03A_IDESTRANGEIRO  VARCHAR2(20 BYTE),
  E04_XNOME           VARCHAR2(60 BYTE),
  E05_XLGR            VARCHAR2(60 BYTE),
  E05_NRO             VARCHAR2(60 BYTE),
  E05_XCPL            VARCHAR2(60 BYTE),
  E05_XBAIRRO         VARCHAR2(60 BYTE),
  E05_CMUN            VARCHAR2(7 BYTE),
  E05_XMUN            VARCHAR2(60 BYTE),
  E05_UF              VARCHAR2(2 BYTE),
  E05_CEP             VARCHAR2(8 BYTE),
  E05_CPAIS           VARCHAR2(4 BYTE),
  E05_XPAIS           VARCHAR2(60 BYTE),
  E05_FONE            VARCHAR2(14 BYTE),
  E16_INDIEDEST       VARCHAR2(1 BYTE),
  E17_IE              VARCHAR2(14 BYTE),
  E18_ISUF            VARCHAR2(9 BYTE),
  E19_IM              VARCHAR2(15 BYTE),
  E20_EMAIL           VARCHAR2(60 BYTE),
  -- Item / Produto
  I02_CPROD           VARCHAR2(60 BYTE),
  I03_CEAN            VARCHAR2(14 BYTE),
  I04_XPROD           VARCHAR2(120 BYTE),
  I05_NCM             VARCHAR2(8 BYTE),
  I08_CFOP            VARCHAR2(4 BYTE),
  I09_UCOM            VARCHAR2(6 BYTE),
  I10_QCOM            NUMBER,
  I10A_VUNCOM         NUMBER,
  I11_VPROD           NUMBER,
  I12_CEANTRIB        VARCHAR2(14 BYTE),
  I13_UTRIB           VARCHAR2(6 BYTE),
  I14_QTRIB           NUMBER,
  I14A_VUNTRIB        NUMBER,
  I15_VDESC           NUMBER,
  I17B_INDTOT         VARCHAR2(1 BYTE),
  -- ICMS
  ICMS_ORIG           VARCHAR2(1 BYTE),
  ICMS_CST            VARCHAR2(3 BYTE),
  ICMS_CSOSN          VARCHAR2(4 BYTE),
  ICMS_VBC            NUMBER,
  ICMS_PICMS          NUMBER,
  ICMS_VICMS          NUMBER,
  ICMS_VBCST          NUMBER,
  ICMS_PICMSST        NUMBER,
  ICMS_VICMSST        NUMBER,
  -- IPI
  IPI_CENQ            VARCHAR2(3 BYTE),
  IPI_CNPJPROD        VARCHAR2(14 BYTE),
  IPI_CST             VARCHAR2(2 BYTE),
  IPI_VBC             NUMBER,
  IPI_PIPI            NUMBER,
  IPI_QUNID           NUMBER,
  IPI_VUNID           NUMBER,
  IPI_VIPI            NUMBER,
  -- PIS
  PIS_CST             VARCHAR2(2 BYTE),
  PIS_VBC             NUMBER,
  PIS_PPIS            NUMBER,
  PIS_QBCPROD         NUMBER,
  PIS_VALIQPROD       NUMBER,
  PIS_VPIS            NUMBER,
  PISST_VBC           NUMBER,
  PISST_PPIS          NUMBER,
  PISST_QBCPROD       NUMBER,
  PISST_VALIQPROD     NUMBER,
  PISST_VPIS          NUMBER,
  -- COFINS
  COFINS_CST          VARCHAR2(2 BYTE),
  COFINS_VBC          NUMBER,
  COFINS_PCOFINS      NUMBER,
  COFINS_QBCPROD      NUMBER,
  COFINS_VALIQPROD    NUMBER,
  COFINS_VCOFINS      NUMBER,
  COFINSST_VBC        NUMBER,
  COFINSST_PCOFINS    NUMBER,
  COFINSST_QBCPROD    NUMBER,
  COFINSST_VALIQPROD  NUMBER,
  COFINSST_VCOFINS    NUMBER,
  -- Cabeçalho NF-e
  NOME_ARQUIVO        VARCHAR2(255 BYTE),
  B02_CUF             VARCHAR2(2 BYTE),
  B03_CNF             VARCHAR2(8 BYTE),
  B04_NATOP           VARCHAR2(60 BYTE),
  B06_MOD             VARCHAR2(2 BYTE),
  B07_SERIE           VARCHAR2(60 BYTE),
  B10_DHSAIENT        VARCHAR2(30 BYTE),
  B11_TPNF            VARCHAR2(1 BYTE),
  B11A_IDDEST         VARCHAR2(1 BYTE),
  B12_CMUNFG          VARCHAR2(7 BYTE),
  B21_TPIMP           VARCHAR2(1 BYTE),
  B22_TPEMIS          VARCHAR2(1 BYTE),
  B23_CDV             VARCHAR2(1 BYTE),
  B24_TPAMB           VARCHAR2(1 BYTE),
  B25_FINNFE          VARCHAR2(1 BYTE),
  B25A_INDFINAL       VARCHAR2(1 BYTE),
  B25B_INDPRES        VARCHAR2(1 BYTE),
  B25C_INDINTERMED    VARCHAR2(1 BYTE),
  B26_PROCEMI         VARCHAR2(1 BYTE),
  B27_VERPROC         VARCHAR2(20 BYTE),
  B28_DHCONT          VARCHAR2(30 BYTE),
  B29_XJUST           VARCHAR2(256 BYTE),
  B_CMUNFGIBS         VARCHAR2(7 BYTE),
  -- 001 - ajuste no campo frete
  I16_VFRETE          NUMBER
)
TABLESPACE TBS_APEX
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
NOLOGGING
NOCOMPRESS
INMEMORY MEMCOMPRESS FOR QUERY LOW PRIORITY NONE DISTRIBUTE AUTO FOR SERVICE DEFAULT NO DUPLICATE
NOCACHE
/

-- ============================================================
-- Para alteracoes em banco existente, consultar:
-- alter_001_tb_reforma_consolidada.sql
-- ============================================================
