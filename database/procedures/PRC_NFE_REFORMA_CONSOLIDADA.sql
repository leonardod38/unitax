-- =============================================================================
-- Procedure..: USER_XMLS.PRC_NFE_REFORMA_CONSOLIDADA
-- Resumo.....: Orquestrador da consolidacao de NF-e/NFC-e. Le os XMLs da
--              stg_nfe, extrai os campos via XMLTABLE (capa + itens), grava em
--              massa na TB_REFORMA_CONSOLIDADA (BULK COLLECT + FORALL SAVE
--              EXCEPTIONS, log em TB_LOG_NFE_REFORMA) e ao final dispara
--              PRC_LOTE_NFE_REFORMA_CONSOLIDADA e PRC_CFE_REFORMA_CONSOLIDADA.
--
-- Historico:
--   v1.1.0 - 2026-06-15 - Adicionados os campos Z03_INFCPL (infAdic/infCpl) e
--                         ZX02_QRCODE (infNFeSupl/qrCode): extracao no XMLTABLE
--                         da capa e gravacao no INSERT da TB_REFORMA_CONSOLIDADA.
--   v1.0.0 - 2026-05-19 - Versao inicial.
-- =============================================================================
CREATE OR REPLACE PROCEDURE USER_XMLS.PRC_NFE_REFORMA_CONSOLIDADA AS
    CURSOR c_docs IS
        SELECT /*+ PARALLEL(32) */
           'NFE' AS TIPO_DOCUMENTO,
           t.NOME_ARQUIVO,
           capa.CHAVE_ACESSO,

           -- Grupo B - Identificadores
           capa.B02_CUF,
           capa.B03_CNF,
           capa.B04_NATOP,
           capa.B06_MOD,
           capa.B07_SERIE,
           capa.NUMERO_NF,
           TO_CHAR(TO_TIMESTAMP_TZ(capa.DATA_EMISSAO_RAW, 'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'), 'DD/MM/YYYY') AS DATA_EMISSAO_NFE,
           capa.B10_DHSAIENT,
           capa.B11_TPNF,
           capa.B11A_IDDEST,
           capa.B12_CMUNFG,
           capa.B21_TPIMP,
           capa.B22_TPEMIS,
           capa.B23_CDV,
           capa.B24_TPAMB,
           capa.B25_FINNFE,
           capa.B25A_INDFINAL,
           capa.B25B_INDPRES,
           capa.B25C_INDINTERMED,
           capa.B26_PROCEMI,
           capa.B27_VERPROC,
           capa.B28_DHCONT,
           capa.B29_XJUST,
           capa.B_CMUNFGIBS,

           TO_NUMBER(REGEXP_REPLACE(det.H02_NITEM, '[^0-9]', '')) AS NITEM,

           -- 1. Emitente Completo
           capa.C02_CNPJ, capa.C02A_CPF, capa.C03_XNOME, capa.C04_XFANT,
           capa.C05_XLGR, capa.C05_NRO, capa.C05_XCPL, capa.C05_XBAIRRO, capa.C05_CMUN,
           capa.C05_XMUN, capa.C05_UF, capa.C05_CEP, capa.C05_CPAIS, capa.C05_XPAIS, capa.C05_FONE,
           capa.C17_IE, capa.C18_IEST, capa.C19_IM, capa.C20_CNAE, capa.C21_CRT,

           -- 2. Destinatario Completo
           capa.E02_CNPJ, capa.E03_CPF, capa.E03A_IDESTRANGEIRO, capa.E04_XNOME,
           capa.E05_XLGR, capa.E05_NRO, capa.E05_XCPL, capa.E05_XBAIRRO, capa.E05_CMUN,
           capa.E05_XMUN, capa.E05_UF, capa.E05_CEP, capa.E05_CPAIS, capa.E05_XPAIS, capa.E05_FONE,
           capa.E16_INDIEDEST, capa.E17_IE, capa.E18_ISUF, capa.E19_IM, capa.E20_EMAIL,

           -- Informacoes Adicionais (Z) e Suplementares (ZX) - nivel capa
           capa.Z03_INFCPL, capa.ZX02_QRCODE,

           -- 3. Produtos
           det.I02_CPROD, det.I03_CEAN, det.I04_XPROD, det.I05_NCM, det.I08_CFOP, det.I09_UCOM,
           ROUND(TO_NUMBER(det.I10_QCOM_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS I10_QCOM,
           ROUND(TO_NUMBER(det.I10A_VUNCOM_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS I10A_VUNCOM,
           ROUND(TO_NUMBER(det.I11_VPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS I11_VPROD,
           det.I12_CEANTRIB, det.I13_UTRIB,
           ROUND(TO_NUMBER(det.I14_QTRIB_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS I14_QTRIB,
           ROUND(TO_NUMBER(det.I14A_VUNTRIB_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS I14A_VUNTRIB,
           ROUND(TO_NUMBER(NVL(det.I15_VDESC_STR, '0'), '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS I15_VDESC,
           det.I17B_INDTOT,

           -- 4. Impostos Atuais (ICMS)
           det.ICMS_ORIG, det.ICMS_CST, det.ICMS_CSOSN,
           ROUND(TO_NUMBER(det.ICMS_VBC_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS ICMS_VBC,
           ROUND(TO_NUMBER(det.ICMS_PICMS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS ICMS_PICMS,
           ROUND(TO_NUMBER(det.ICMS_VICMS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS ICMS_VICMS,
           ROUND(TO_NUMBER(det.ICMS_VBCST_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS ICMS_VBCST,
           ROUND(TO_NUMBER(det.ICMS_PICMSST_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS ICMS_PICMSST,
           ROUND(TO_NUMBER(det.ICMS_VICMSST_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS ICMS_VICMSST,

           -- 5. Impostos Atuais (IPI)
           det.IPI_CENQ, det.IPI_CNPJPROD, det.IPI_CST,
           ROUND(TO_NUMBER(det.IPI_VBC_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS IPI_VBC,
           ROUND(TO_NUMBER(det.IPI_PIPI_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS IPI_PIPI,
           ROUND(TO_NUMBER(det.IPI_QUNID_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS IPI_QUNID,
           ROUND(TO_NUMBER(det.IPI_VUNID_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS IPI_VUNID,
           ROUND(TO_NUMBER(det.IPI_VIPI_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS IPI_VIPI,

           -- 6. PIS e COFINS (Regular e ST)
           det.PIS_CST,
           ROUND(TO_NUMBER(det.PIS_VBC_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PIS_VBC,
           ROUND(TO_NUMBER(det.PIS_PPIS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PIS_PPIS,
           ROUND(TO_NUMBER(det.PIS_QBCPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PIS_QBCPROD,
           ROUND(TO_NUMBER(det.PIS_VALIQPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PIS_VALIQPROD,
           ROUND(TO_NUMBER(det.PIS_VPIS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PIS_VPIS,
           ROUND(TO_NUMBER(det.PISST_VBC_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PISST_VBC,
           ROUND(TO_NUMBER(det.PISST_PPIS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PISST_PPIS,
           ROUND(TO_NUMBER(det.PISST_QBCPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PISST_QBCPROD,
           ROUND(TO_NUMBER(det.PISST_VALIQPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PISST_VALIQPROD,
           ROUND(TO_NUMBER(det.PISST_VPIS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS PISST_VPIS,

           det.COFINS_CST,
           ROUND(TO_NUMBER(det.COFINS_VBC_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINS_VBC,
           ROUND(TO_NUMBER(det.COFINS_PCOFINS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINS_PCOFINS,
           ROUND(TO_NUMBER(det.COFINS_QBCPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINS_QBCPROD,
           ROUND(TO_NUMBER(det.COFINS_VALIQPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINS_VALIQPROD,
           ROUND(TO_NUMBER(det.COFINS_VCOFINS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINS_VCOFINS,
           ROUND(TO_NUMBER(det.COFINSST_VBC_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINSST_VBC,
           ROUND(TO_NUMBER(det.COFINSST_PCOFINS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINSST_PCOFINS,
           ROUND(TO_NUMBER(det.COFINSST_QBCPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINSST_QBCPROD,
           ROUND(TO_NUMBER(det.COFINSST_VALIQPROD_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINSST_VALIQPROD,
           ROUND(TO_NUMBER(det.COFINSST_VCOFINS_STR, '99999999999990.9999999999', 'NLS_NUMERIC_CHARACTERS = ''. '''), 2) AS COFINSST_VCOFINS

        FROM stg_nfe t,
             -- ==========================================
             -- XMLTABLE 1: CAPA (Pai) - Extrai 1 vez
             -- ==========================================
             XMLTABLE (
                 XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                 '/nfeProc'
                 PASSING XMLTYPE(t.conteudo_xml)
                 COLUMNS
                     CHAVE_ACESSO     VARCHAR2(44) PATH 'protNFe/infProt/chNFe',
                     NUMERO_NF        VARCHAR2(20) PATH 'NFe/infNFe/ide/nNF',
                     DATA_EMISSAO_RAW VARCHAR2(30) PATH 'NFe/infNFe/ide/dhEmi',

                     -- Grupo B
                     B02_CUF          VARCHAR2(2)  PATH 'NFe/infNFe/ide/cUF',
                     B03_CNF          VARCHAR2(8)  PATH 'NFe/infNFe/ide/cNF',
                     B04_NATOP        VARCHAR2(60) PATH 'NFe/infNFe/ide/natOp',
                     B06_MOD          VARCHAR2(2)  PATH 'NFe/infNFe/ide/mod',
                     B07_SERIE        VARCHAR2(3)  PATH 'NFe/infNFe/ide/serie',
                     B10_DHSAIENT     VARCHAR2(30) PATH 'NFe/infNFe/ide/dhSaiEnt',
                     B11_TPNF         VARCHAR2(1)  PATH 'NFe/infNFe/ide/tpNF',
                     B11A_IDDEST      VARCHAR2(1)  PATH 'NFe/infNFe/ide/idDest',
                     B12_CMUNFG       VARCHAR2(7)  PATH 'NFe/infNFe/ide/cMunFG',
                     B21_TPIMP        VARCHAR2(1)  PATH 'NFe/infNFe/ide/tpImp',
                     B22_TPEMIS       VARCHAR2(1)  PATH 'NFe/infNFe/ide/tpEmis',
                     B23_CDV          VARCHAR2(1)  PATH 'NFe/infNFe/ide/cDV',
                     B24_TPAMB        VARCHAR2(1)  PATH 'NFe/infNFe/ide/tpAmb',
                     B25_FINNFE       VARCHAR2(1)  PATH 'NFe/infNFe/ide/finNFe',
                     B25A_INDFINAL    VARCHAR2(1)  PATH 'NFe/infNFe/ide/indFinal',
                     B25B_INDPRES     VARCHAR2(1)  PATH 'NFe/infNFe/ide/indPres',
                     B25C_INDINTERMED VARCHAR2(1)  PATH 'NFe/infNFe/ide/indIntermed',
                     B26_PROCEMI      VARCHAR2(1)  PATH 'NFe/infNFe/ide/procEmi',
                     B27_VERPROC      VARCHAR2(20) PATH 'NFe/infNFe/ide/verProc',
                     B28_DHCONT       VARCHAR2(30) PATH 'NFe/infNFe/ide/dhCont',
                     B29_XJUST        VARCHAR2(256) PATH 'NFe/infNFe/ide/xJust',
                     B_CMUNFGIBS      VARCHAR2(7)  PATH 'NFe/infNFe/ide/cMunFGIBS',

                     -- Emitente
                     C02_CNPJ         VARCHAR2(14) PATH 'NFe/infNFe/emit/CNPJ',
                     C02A_CPF         VARCHAR2(11) PATH 'NFe/infNFe/emit/CPF',
                     C03_XNOME        VARCHAR2(60) PATH 'NFe/infNFe/emit/xNome',
                     C04_XFANT        VARCHAR2(60) PATH 'NFe/infNFe/emit/xFant',
                     C05_XLGR         VARCHAR2(60) PATH 'NFe/infNFe/emit/enderEmit/xLgr',
                     C05_NRO          VARCHAR2(60) PATH 'NFe/infNFe/emit/enderEmit/nro',
                     C05_XCPL         VARCHAR2(60) PATH 'NFe/infNFe/emit/enderEmit/xCpl',
                     C05_XBAIRRO      VARCHAR2(60) PATH 'NFe/infNFe/emit/enderEmit/xBairro',
                     C05_CMUN         VARCHAR2(7)  PATH 'NFe/infNFe/emit/enderEmit/cMun',
                     C05_XMUN         VARCHAR2(60) PATH 'NFe/infNFe/emit/enderEmit/xMun',
                     C05_UF           VARCHAR2(2)  PATH 'NFe/infNFe/emit/enderEmit/UF',
                     C05_CEP          VARCHAR2(8)  PATH 'NFe/infNFe/emit/enderEmit/CEP',
                     C05_CPAIS        VARCHAR2(4)  PATH 'NFe/infNFe/emit/enderEmit/cPais',
                     C05_XPAIS        VARCHAR2(60) PATH 'NFe/infNFe/emit/enderEmit/xPais',
                     C05_FONE         VARCHAR2(14) PATH 'NFe/infNFe/emit/enderEmit/fone',
                     C17_IE           VARCHAR2(14) PATH 'NFe/infNFe/emit/IE',
                     C18_IEST         VARCHAR2(14) PATH 'NFe/infNFe/emit/IEST',
                     C19_IM           VARCHAR2(15) PATH 'NFe/infNFe/emit/IM',
                     C20_CNAE         VARCHAR2(7)  PATH 'NFe/infNFe/emit/CNAE',
                     C21_CRT          VARCHAR2(1)  PATH 'NFe/infNFe/emit/CRT',

                     -- Destinatario
                     E02_CNPJ         VARCHAR2(14) PATH 'NFe/infNFe/dest/CNPJ',
                     E03_CPF          VARCHAR2(11) PATH 'NFe/infNFe/dest/CPF',
                     E03A_IDESTRANGEIRO VARCHAR2(20) PATH 'NFe/infNFe/dest/idEstrangeiro',
                     E04_XNOME        VARCHAR2(60) PATH 'NFe/infNFe/dest/xNome',
                     E05_XLGR         VARCHAR2(60) PATH 'NFe/infNFe/dest/enderDest/xLgr',
                     E05_NRO          VARCHAR2(60) PATH 'NFe/infNFe/dest/enderDest/nro',
                     E05_XCPL         VARCHAR2(60) PATH 'NFe/infNFe/dest/enderDest/xCpl',
                     E05_XBAIRRO      VARCHAR2(60) PATH 'NFe/infNFe/dest/enderDest/xBairro',
                     E05_CMUN         VARCHAR2(7)  PATH 'NFe/infNFe/dest/enderDest/cMun',
                     E05_XMUN         VARCHAR2(60) PATH 'NFe/infNFe/dest/enderDest/xMun',
                     E05_UF           VARCHAR2(2)  PATH 'NFe/infNFe/dest/enderDest/UF',
                     E05_CEP          VARCHAR2(8)  PATH 'NFe/infNFe/dest/enderDest/CEP',
                     E05_CPAIS        VARCHAR2(4)  PATH 'NFe/infNFe/dest/enderDest/cPais',
                     E05_XPAIS        VARCHAR2(60) PATH 'NFe/infNFe/dest/enderDest/xPais',
                     E05_FONE         VARCHAR2(14) PATH 'NFe/infNFe/dest/enderDest/fone',
                     E16_INDIEDEST    VARCHAR2(1)  PATH 'NFe/infNFe/dest/indIEDest',
                     E17_IE           VARCHAR2(14) PATH 'NFe/infNFe/dest/IE',
                     E18_ISUF         VARCHAR2(9)  PATH 'NFe/infNFe/dest/ISUF',
                     E19_IM           VARCHAR2(15) PATH 'NFe/infNFe/dest/IM',
                     E20_EMAIL        VARCHAR2(60) PATH 'NFe/infNFe/dest/email',

                     -- Grupo Z - Informacoes Adicionais
                     Z03_INFCPL       VARCHAR2(4000) PATH 'NFe/infNFe/infAdic/infCpl',

                     -- Grupo ZX - Informacoes Suplementares (QR Code - somente NFC-e mod 65)
                     ZX02_QRCODE      VARCHAR2(1000) PATH 'NFe/infNFeSupl/qrCode',

                     -- Passando no inteiro de itens para o Filho
                     XML_ITENS        XMLTYPE      PATH 'NFe/infNFe/det'
             ) capa,
             -- ==========================================
             -- XMLTABLE 2: DETALHE (Filho) - Extrai 1 vez
             -- ==========================================
             XMLTABLE (
                 XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                 '/det'
                 PASSING capa.XML_ITENS
                 COLUMNS
                     H02_NITEM        VARCHAR2(10) PATH '@nItem',
                     I02_CPROD        VARCHAR2(60) PATH 'prod/cProd',
                     I03_CEAN         VARCHAR2(14) PATH 'prod/cEAN',
                     I04_XPROD        VARCHAR2(120) PATH 'prod/xProd',
                     I05_NCM          VARCHAR2(8)  PATH 'prod/NCM',
                     I08_CFOP         VARCHAR2(4)  PATH 'prod/CFOP',
                     I09_UCOM         VARCHAR2(6)  PATH 'prod/uCom',
                     I10_QCOM_STR     VARCHAR2(30) PATH 'prod/qCom',
                     I10A_VUNCOM_STR  VARCHAR2(30) PATH 'prod/vUnCom',
                     I11_VPROD_STR    VARCHAR2(30) PATH 'prod/vProd',
                     I12_CEANTRIB     VARCHAR2(14) PATH 'prod/cEANTrib',
                     I13_UTRIB        VARCHAR2(6)  PATH 'prod/uTrib',
                     I14_QTRIB_STR    VARCHAR2(30) PATH 'prod/qTrib',
                     I14A_VUNTRIB_STR VARCHAR2(30) PATH 'prod/vUnTrib',
                     I15_VDESC_STR    VARCHAR2(30) PATH 'prod/vDesc',
                     I17B_INDTOT      VARCHAR2(1)  PATH 'prod/indTot',

                     -- ICMS
                     ICMS_ORIG        VARCHAR2(1)  PATH 'imposto/ICMS/*/orig',
                     ICMS_CST         VARCHAR2(3)  PATH 'imposto/ICMS/*/CST',
                     ICMS_CSOSN       VARCHAR2(4)  PATH 'imposto/ICMS/*/CSOSN',
                     ICMS_VBC_STR     VARCHAR2(30) PATH 'imposto/ICMS/*/vBC',
                     ICMS_PICMS_STR   VARCHAR2(30) PATH 'imposto/ICMS/*/pICMS',
                     ICMS_VICMS_STR   VARCHAR2(30) PATH 'imposto/ICMS/*/vICMS',
                     ICMS_VBCST_STR   VARCHAR2(30) PATH 'imposto/ICMS/*/vBCST',
                     ICMS_PICMSST_STR VARCHAR2(30) PATH 'imposto/ICMS/*/pICMSST',
                     ICMS_VICMSST_STR VARCHAR2(30) PATH 'imposto/ICMS/*/vICMSST',

                     -- IPI
                     IPI_CENQ         VARCHAR2(30) PATH 'imposto/IPI/cEnq',
                     IPI_CNPJPROD     VARCHAR2(30) PATH 'imposto/IPI/CNPJProd',
                     IPI_CST          VARCHAR2(30) PATH 'imposto/IPI/*/CST',
                     IPI_VBC_STR      VARCHAR2(30) PATH 'imposto/IPI/*/vBC',
                     IPI_PIPI_STR     VARCHAR2(30) PATH 'imposto/IPI/*/pIPI',
                     IPI_QUNID_STR    VARCHAR2(30) PATH 'imposto/IPI/*/qUnid',
                     IPI_VUNID_STR    VARCHAR2(30) PATH 'imposto/IPI/*/vUnid',
                     IPI_VIPI_STR     VARCHAR2(30) PATH 'imposto/IPI/*/vIPI',

                     -- PIS/COFINS
                     PIS_CST          VARCHAR2(30) PATH 'imposto/PIS/*/CST',
                     PIS_VBC_STR      VARCHAR2(30) PATH 'imposto/PIS/*/vBC',
                     PIS_PPIS_STR     VARCHAR2(30) PATH 'imposto/PIS/*/pPIS',
                     PIS_QBCPROD_STR  VARCHAR2(30) PATH 'imposto/PIS/*/qBCProd',
                     PIS_VALIQPROD_STR VARCHAR2(30) PATH 'imposto/PIS/*/vAliqProd',
                     PIS_VPIS_STR     VARCHAR2(30) PATH 'imposto/PIS/*/vPIS',
                     PISST_VBC_STR    VARCHAR2(30) PATH 'imposto/PISST/vBC',
                     PISST_PPIS_STR   VARCHAR2(30) PATH 'imposto/PISST/pPIS',
                     PISST_QBCPROD_STR VARCHAR2(30) PATH 'imposto/PISST/qBCProd',
                     PISST_VALIQPROD_STR VARCHAR2(30) PATH 'imposto/PISST/vAliqProd',
                     PISST_VPIS_STR   VARCHAR2(30) PATH 'imposto/PISST/vPIS',
                     COFINS_CST       VARCHAR2(30) PATH 'imposto/COFINS/*/CST',
                     COFINS_VBC_STR   VARCHAR2(30) PATH 'imposto/COFINS/*/vBC',
                     COFINS_PCOFINS_STR VARCHAR2(30) PATH 'imposto/COFINS/*/pCOFINS',
                     COFINS_QBCPROD_STR VARCHAR2(30) PATH 'imposto/COFINS/*/qBCProd',
                     COFINS_VALIQPROD_STR VARCHAR2(30) PATH 'imposto/COFINS/*/vAliqProd',
                     COFINS_VCOFINS_STR VARCHAR2(30) PATH 'imposto/COFINS/*/vCOFINS',
                     COFINSST_VBC_STR VARCHAR2(30) PATH 'imposto/COFINSST/vBC',
                     COFINSST_PCOFINS_STR VARCHAR2(30) PATH 'imposto/COFINSST/pCOFINS',
                     COFINSST_QBCPROD_STR VARCHAR2(30) PATH 'imposto/COFINSST/qBCProd',
                     COFINSST_VALIQPROD_STR VARCHAR2(30) PATH 'imposto/COFINSST/vAliqProd',
                     COFINSST_VCOFINS_STR VARCHAR2(30) PATH 'imposto/COFINSST/vCOFINS'
             ) det;

    TYPE t_doc_array IS TABLE OF c_docs%ROWTYPE;
    v_doc_array t_doc_array;
    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

    PROCEDURE gravar_log(p_chave IN VARCHAR2, p_nitem IN NUMBER, p_cod IN NUMBER, p_msg IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TB_LOG_NFE_REFORMA (CHAVE_ACESSO, NITEM, CODIGO_ERRO, MENSAGEM_ERRO)
        VALUES (p_chave, p_nitem, p_cod, SUBSTR(p_msg, 1, 4000));
        COMMIT;
    END gravar_log;

BEGIN
    EXECUTE IMMEDIATE 'TRUNCATE TABLE TB_REFORMA_CONSOLIDADA';

    OPEN c_docs;
    LOOP
        FETCH c_docs BULK COLLECT INTO v_doc_array LIMIT 1000;
        EXIT WHEN v_doc_array.COUNT = 0;

        BEGIN
            FORALL i IN 1 .. v_doc_array.COUNT SAVE EXCEPTIONS
                INSERT INTO TB_REFORMA_CONSOLIDADA (
                    TIPO_DOCUMENTO, NOME_ARQUIVO, CHAVE_ACESSO,

                    B02_CUF, B03_CNF, B04_NATOP, B06_MOD, B07_SERIE, NUMERO_NF, DATA_EMISSAO_NFE, B10_DHSAIENT,
                    B11_TPNF, B11A_IDDEST, B12_CMUNFG, B21_TPIMP, B22_TPEMIS, B23_CDV, B24_TPAMB, B25_FINNFE,
                    B25A_INDFINAL, B25B_INDPRES, B25C_INDINTERMED, B26_PROCEMI, B27_VERPROC, B28_DHCONT, B29_XJUST, B_CMUNFGIBS,

                    NITEM,

                    C02_CNPJ, C02A_CPF, C03_XNOME, C04_XFANT,
                    C05_XLGR, C05_NRO, C05_XCPL, C05_XBAIRRO, C05_CMUN, C05_XMUN, C05_UF, C05_CEP, C05_CPAIS, C05_XPAIS, C05_FONE,
                    C17_IE, C18_IEST, C19_IM, C20_CNAE, C21_CRT,

                    E02_CNPJ, E03_CPF, E03A_IDESTRANGEIRO, E04_XNOME, E05_XLGR, E05_NRO, E05_XCPL, E05_XBAIRRO, E05_CMUN, E05_XMUN, E05_UF, E05_CEP, E05_CPAIS, E05_XPAIS, E05_FONE,
                    E16_INDIEDEST, E17_IE, E18_ISUF, E19_IM, E20_EMAIL,

                    Z03_INFCPL, ZX02_QRCODE,

                    I02_CPROD, I03_CEAN, I04_XPROD, I05_NCM, I08_CFOP, I09_UCOM, I10_QCOM, I10A_VUNCOM, I11_VPROD, I12_CEANTRIB, I13_UTRIB, I14_QTRIB, I14A_VUNTRIB, I15_VDESC, I17B_INDTOT,

                    ICMS_ORIG, ICMS_CST, ICMS_CSOSN, ICMS_VBC, ICMS_PICMS, ICMS_VICMS, ICMS_VBCST, ICMS_PICMSST, ICMS_VICMSST,
                    IPI_CENQ, IPI_CNPJPROD, IPI_CST, IPI_VBC, IPI_PIPI, IPI_QUNID, IPI_VUNID, IPI_VIPI,
                    PIS_CST, PIS_VBC, PIS_PPIS, PIS_QBCPROD, PIS_VALIQPROD, PIS_VPIS, PISST_VBC, PISST_PPIS, PISST_QBCPROD, PISST_VALIQPROD, PISST_VPIS,
                    COFINS_CST, COFINS_VBC, COFINS_PCOFINS, COFINS_QBCPROD, COFINS_VALIQPROD, COFINS_VCOFINS, COFINSST_VBC, COFINSST_PCOFINS, COFINSST_QBCPROD, COFINSST_VALIQPROD, COFINSST_VCOFINS
                ) VALUES (
                    v_doc_array(i).TIPO_DOCUMENTO, v_doc_array(i).NOME_ARQUIVO, v_doc_array(i).CHAVE_ACESSO,

                    v_doc_array(i).B02_CUF, v_doc_array(i).B03_CNF, v_doc_array(i).B04_NATOP, v_doc_array(i).B06_MOD, v_doc_array(i).B07_SERIE, v_doc_array(i).NUMERO_NF, v_doc_array(i).DATA_EMISSAO_NFE, v_doc_array(i).B10_DHSAIENT,
                    v_doc_array(i).B11_TPNF, v_doc_array(i).B11A_IDDEST, v_doc_array(i).B12_CMUNFG, v_doc_array(i).B21_TPIMP, v_doc_array(i).B22_TPEMIS, v_doc_array(i).B23_CDV, v_doc_array(i).B24_TPAMB, v_doc_array(i).B25_FINNFE,
                    v_doc_array(i).B25A_INDFINAL, v_doc_array(i).B25B_INDPRES, v_doc_array(i).B25C_INDINTERMED, v_doc_array(i).B26_PROCEMI, v_doc_array(i).B27_VERPROC, v_doc_array(i).B28_DHCONT, v_doc_array(i).B29_XJUST, v_doc_array(i).B_CMUNFGIBS,

                    v_doc_array(i).NITEM,

                    v_doc_array(i).C02_CNPJ, v_doc_array(i).C02A_CPF, v_doc_array(i).C03_XNOME, v_doc_array(i).C04_XFANT,
                    v_doc_array(i).C05_XLGR, v_doc_array(i).C05_NRO, v_doc_array(i).C05_XCPL, v_doc_array(i).C05_XBAIRRO, v_doc_array(i).C05_CMUN, v_doc_array(i).C05_XMUN, v_doc_array(i).C05_UF, v_doc_array(i).C05_CEP, v_doc_array(i).C05_CPAIS, v_doc_array(i).C05_XPAIS, v_doc_array(i).C05_FONE,
                    v_doc_array(i).C17_IE, v_doc_array(i).C18_IEST, v_doc_array(i).C19_IM, v_doc_array(i).C20_CNAE, v_doc_array(i).C21_CRT,

                    v_doc_array(i).E02_CNPJ, v_doc_array(i).E03_CPF, v_doc_array(i).E03A_IDESTRANGEIRO, v_doc_array(i).E04_XNOME, v_doc_array(i).E05_XLGR, v_doc_array(i).E05_NRO, v_doc_array(i).E05_XCPL, v_doc_array(i).E05_XBAIRRO, v_doc_array(i).E05_CMUN, v_doc_array(i).E05_XMUN, v_doc_array(i).E05_UF, v_doc_array(i).E05_CEP, v_doc_array(i).E05_CPAIS, v_doc_array(i).E05_XPAIS, v_doc_array(i).E05_FONE,
                    v_doc_array(i).E16_INDIEDEST, v_doc_array(i).E17_IE, v_doc_array(i).E18_ISUF, v_doc_array(i).E19_IM, v_doc_array(i).E20_EMAIL,

                    v_doc_array(i).Z03_INFCPL, v_doc_array(i).ZX02_QRCODE,

                    v_doc_array(i).I02_CPROD, v_doc_array(i).I03_CEAN, v_doc_array(i).I04_XPROD, v_doc_array(i).I05_NCM, v_doc_array(i).I08_CFOP, v_doc_array(i).I09_UCOM, v_doc_array(i).I10_QCOM, v_doc_array(i).I10A_VUNCOM, v_doc_array(i).I11_VPROD, v_doc_array(i).I12_CEANTRIB, v_doc_array(i).I13_UTRIB, v_doc_array(i).I14_QTRIB, v_doc_array(i).I14A_VUNTRIB, v_doc_array(i).I15_VDESC, v_doc_array(i).I17B_INDTOT,

                    v_doc_array(i).ICMS_ORIG, v_doc_array(i).ICMS_CST, v_doc_array(i).ICMS_CSOSN, v_doc_array(i).ICMS_VBC, v_doc_array(i).ICMS_PICMS, v_doc_array(i).ICMS_VICMS, v_doc_array(i).ICMS_VBCST, v_doc_array(i).ICMS_PICMSST, v_doc_array(i).ICMS_VICMSST,
                    v_doc_array(i).IPI_CENQ, v_doc_array(i).IPI_CNPJPROD, v_doc_array(i).IPI_CST, v_doc_array(i).IPI_VBC, v_doc_array(i).IPI_PIPI, v_doc_array(i).IPI_QUNID, v_doc_array(i).IPI_VUNID, v_doc_array(i).IPI_VIPI,
                    v_doc_array(i).PIS_CST, v_doc_array(i).PIS_VBC, v_doc_array(i).PIS_PPIS, v_doc_array(i).PIS_QBCPROD, v_doc_array(i).PIS_VALIQPROD, v_doc_array(i).PIS_VPIS, v_doc_array(i).PISST_VBC, v_doc_array(i).PISST_PPIS, v_doc_array(i).PISST_QBCPROD, v_doc_array(i).PISST_VALIQPROD, v_doc_array(i).PISST_VPIS,
                    v_doc_array(i).COFINS_CST, v_doc_array(i).COFINS_VBC, v_doc_array(i).COFINS_PCOFINS, v_doc_array(i).COFINS_QBCPROD, v_doc_array(i).COFINS_VALIQPROD, v_doc_array(i).COFINS_VCOFINS, v_doc_array(i).COFINSST_VBC, v_doc_array(i).COFINSST_PCOFINS, v_doc_array(i).COFINSST_QBCPROD, v_doc_array(i).COFINSST_VALIQPROD, v_doc_array(i).COFINSST_VCOFINS
                );
        EXCEPTION
            WHEN e_bulk_errors THEN
                FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                    gravar_log(
                        v_doc_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).CHAVE_ACESSO,
                        v_doc_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).NITEM,
                        SQL%BULK_EXCEPTIONS(i).ERROR_CODE,
                        SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE)
                    );
                END LOOP;
        END;
        COMMIT;
    END LOOP;
    CLOSE c_docs;

BEGIN
    PRC_LOTE_NFE_REFORMA_CONSOLIDADA;
    PRC_CFE_REFORMA_CONSOLIDADA;
END;

END PRC_NFE_REFORMA_CONSOLIDADA;
/

SHOW ERRORS;
