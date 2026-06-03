CREATE OR REPLACE PROCEDURE USER_XMLS.PRC_CFE_REFORMA_CONSOLIDADA 
AS

/* ============================================================
   DDL — Nova tabela de log unificada para CFe
   Execute antes do bloco de teste.
   ============================================================ */
--CREATE TABLE TB_LOG_CFE_REFORMA (
--    ID_LOG           NUMBER          GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
--    DT_PROCESSAMENTO TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
--    NOME_ARQUIVO     VARCHAR2(200),
--    CHAVE_ACESSO     VARCHAR2(44),
--    NITEM            NUMBER,
--    FORMATO_XML      VARCHAR2(10),   -- 'UNITARIO' ou 'LOTE_CFE'
--    ORIGEM           VARCHAR2(200),
--    ORA_CODE         NUMBER,
--    ORA_MSG          VARCHAR2(4000),
--    BACKTRACE        VARCHAR2(4000)
--);
--/
--
--
--/* ============================================================
--   BLOCO DE TESTE — PRC_CFE_REFORMA_CONSOLIDADA
--   Contempla os dois formatos de CFe na staging:
--     [A] CFe Unitário  → tag raiz <CFe>         (sem namespace)
--     [B] Lote de CFe   → tag raiz <envCFe>       (namespace fazenda.sp.gov.br/sat)
--   Lógica: UNION ALL no cursor + BULK COLLECT + FORALL + SAVE EXCEPTIONS
--   ============================================================ */
--DECLARE

    /* ----------------------------------------------------------
       Cursor principal — UNION ALL une os dois formatos
    ---------------------------------------------------------- */
    CURSOR c_cfe IS

        /* ==================================================
           [A] CFe UNITÁRIO — raiz <CFe> sem namespace
        ================================================== */
        SELECT
            'CFE'                                                               AS TIPO_DOCUMENTO,
            'UNITARIO'                                                          AS FORMATO_XML,
            t.NOME_ARQUIVO,
            SUBSTR(capa.ID_CORTADO, 4, 44)                                      AS CHAVE_ACESSO,
            -- Grupo B
            capa.B02_CUF, capa.B03_CNF,
            NULL                                                                AS B04_NATOP,
            capa.B06_MOD, capa.B07_SERIE, capa.NUMERO_NF,
            TO_CHAR(TO_DATE(capa.DEMI_RAW || capa.HEMI_RAW,
                'YYYYMMDDHH24MISS'), 'DD/MM/YYYY')                             AS DATA_EMISSAO_NFE,
            NULL  AS B10_DHSAIENT, NULL  AS B11_TPNF,    NULL  AS B11A_IDDEST,
            NULL  AS B12_CMUNFG,   NULL  AS B21_TPIMP,
            capa.B22_TPEMIS, capa.B23_CDV, capa.B24_TPAMB,
            NULL  AS B25_FINNFE,   NULL  AS B25A_INDFINAL, NULL AS B25B_INDPRES,
            NULL  AS B25C_INDINTERMED, NULL AS B26_PROCEMI, NULL AS B27_VERPROC,
            NULL  AS B28_DHCONT,   NULL  AS B29_XJUST,    NULL  AS B_CMUNFGIBS,
            -- nItem
            TO_NUMBER(REGEXP_REPLACE(det.H02_NITEM,'[^0-9]',''))               AS NITEM,
            -- Emitente
            capa.C02_CNPJ, NULL AS C02A_CPF, capa.C03_XNOME, NULL AS C04_XFANT,
            capa.C05_XLGR, capa.C05_NRO, capa.C05_XCPL, capa.C05_XBAIRRO,
            NULL  AS C05_CMUN, capa.C05_XMUN, NULL AS C05_UF, capa.C05_CEP,
            NULL  AS C05_CPAIS, NULL AS C05_XPAIS, NULL AS C05_FONE,
            capa.C17_IE, NULL AS C18_IEST, capa.C19_IM, NULL AS C20_CNAE, capa.C21_CRT,
            -- Destinatário
            capa.E02_CNPJ, capa.E03_CPF,
            NULL  AS E03A_IDESTRANGEIRO, capa.E04_XNOME,
            NULL  AS E05_XLGR,  NULL AS E05_NRO,   NULL AS E05_XCPL,
            NULL  AS E05_XBAIRRO, NULL AS E05_CMUN, NULL AS E05_XMUN,
            NULL  AS E05_UF,    NULL AS E05_CEP,   NULL AS E05_CPAIS,
            NULL  AS E05_XPAIS, NULL AS E05_FONE,
            NULL  AS E16_INDIEDEST, NULL AS E17_IE, NULL AS E18_ISUF,
            NULL  AS E19_IM,    NULL AS E20_EMAIL,
            -- Produtos
            det.I02_CPROD, det.I03_CEAN, det.I04_XPROD, det.I05_NCM,
            det.I08_CFOP,  det.I09_UCOM,
            ROUND(TO_NUMBER(det.I10_QCOM_STR,    '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I10_QCOM,
            ROUND(TO_NUMBER(det.I10A_VUNCOM_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I10A_VUNCOM,
            ROUND(TO_NUMBER(det.I11_VPROD_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I11_VPROD,
            NULL  AS I12_CEANTRIB, NULL AS I13_UTRIB, NULL AS I14_QTRIB, NULL AS I14A_VUNTRIB,
            ROUND(TO_NUMBER(NVL(det.I15_VDESC_STR,'0'),'99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I15_VDESC,
            det.I17B_INDTOT,
            -- ICMS
            det.ICMS_ORIG, NULL AS ICMS_CST, det.ICMS_CSOSN,
            ROUND(TO_NUMBER(det.ICMS_VBC_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS ICMS_VBC,
            ROUND(TO_NUMBER(det.ICMS_PICMS_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS ICMS_PICMS,
            ROUND(TO_NUMBER(det.ICMS_VICMS_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS ICMS_VICMS,
            NULL  AS ICMS_VBCST, NULL AS ICMS_PICMSST, NULL AS ICMS_VICMSST,
            -- IPI (não existe no CFe)
            NULL  AS IPI_CENQ,   NULL AS IPI_CNPJPROD, NULL AS IPI_CST,
            NULL  AS IPI_VBC,    NULL AS IPI_PIPI,     NULL AS IPI_QUNID,
            NULL  AS IPI_VUNID,  NULL AS IPI_VIPI,
            -- PIS
            det.PIS_CST,
            ROUND(TO_NUMBER(det.PIS_VBC_STR,       '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_VBC,
            ROUND(TO_NUMBER(det.PIS_PPIS_STR,      '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_PPIS,
            ROUND(TO_NUMBER(det.PIS_QBCPROD_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_QBCPROD,
            ROUND(TO_NUMBER(det.PIS_VALIQPROD_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_VALIQPROD,
            ROUND(TO_NUMBER(det.PIS_VPIS_STR,      '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_VPIS,
            NULL  AS PISST_VBC, NULL AS PISST_PPIS, NULL AS PISST_QBCPROD,
            NULL  AS PISST_VALIQPROD, NULL AS PISST_VPIS,
            -- COFINS
            det.COFINS_CST,
            ROUND(TO_NUMBER(det.COFINS_VBC_STR,       '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_VBC,
            ROUND(TO_NUMBER(det.COFINS_PCOFINS_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_PCOFINS,
            ROUND(TO_NUMBER(det.COFINS_QBCPROD_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_QBCPROD,
            ROUND(TO_NUMBER(det.COFINS_VALIQPROD_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_VALIQPROD,
            ROUND(TO_NUMBER(det.COFINS_VCOFINS_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_VCOFINS,
            NULL  AS COFINSST_VBC,   NULL AS COFINSST_PCOFINS, NULL AS COFINSST_QBCPROD,
            NULL  AS COFINSST_VALIQPROD, NULL AS COFINSST_VCOFINS

        FROM stg_nfe t,
             -- Capa: um registro por CFe unitário
             XMLTABLE (
                 '/CFe/infCFe'
                 PASSING XMLTYPE(t.conteudo_xml)
                 COLUMNS
                     ID_CORTADO   VARCHAR2(50) PATH '@Id',
                     NUMERO_NF    VARCHAR2(20) PATH 'ide/nCFe',
                     DEMI_RAW     VARCHAR2(8)  PATH 'ide/dEmi',
                     HEMI_RAW     VARCHAR2(6)  PATH 'ide/hEmi',
                     B02_CUF      VARCHAR2(2)  PATH 'ide/cUF',
                     B03_CNF      VARCHAR2(8)  PATH 'ide/cNF',
                     B06_MOD      VARCHAR2(2)  PATH 'ide/mod',
                     B07_SERIE    VARCHAR2(9)  PATH 'ide/nserieSAT',
                     B22_TPEMIS   VARCHAR2(1)  PATH 'ide/tpEmi',
                     B23_CDV      VARCHAR2(1)  PATH 'ide/cDV',
                     B24_TPAMB    VARCHAR2(1)  PATH 'ide/tpAmb',
                     C02_CNPJ     VARCHAR2(14) PATH 'emit/CNPJ',
                     C03_XNOME    VARCHAR2(60) PATH 'emit/xNome',
                     C05_XLGR     VARCHAR2(60) PATH 'emit/enderEmit/xLgr',
                     C05_NRO      VARCHAR2(60) PATH 'emit/enderEmit/nro',
                     C05_XCPL     VARCHAR2(60) PATH 'emit/enderEmit/xCpl',
                     C05_XBAIRRO  VARCHAR2(60) PATH 'emit/enderEmit/xBairro',
                     C05_XMUN     VARCHAR2(60) PATH 'emit/enderEmit/xMun',
                     C05_CEP      VARCHAR2(8)  PATH 'emit/enderEmit/CEP',
                     C17_IE       VARCHAR2(14) PATH 'emit/IE',
                     C19_IM       VARCHAR2(15) PATH 'emit/IM',
                     C21_CRT      VARCHAR2(1)  PATH 'emit/cRegTrib',
                     E02_CNPJ     VARCHAR2(14) PATH 'dest/CNPJ',
                     E03_CPF      VARCHAR2(11) PATH 'dest/CPF',
                     E04_XNOME    VARCHAR2(60) PATH 'dest/xNome',
                     XML_ITENS    XMLTYPE      PATH 'det'
             ) capa,
             -- Itens: sem namespace
             XMLTABLE (
                 '/det'
                 PASSING capa.XML_ITENS
                 COLUMNS
                     H02_NITEM            VARCHAR2(10) PATH '@nItem',
                     I02_CPROD            VARCHAR2(60) PATH 'prod/cProd',
                     I03_CEAN             VARCHAR2(14) PATH 'prod/cEAN',
                     I04_XPROD            VARCHAR2(120) PATH 'prod/xProd',
                     I05_NCM              VARCHAR2(8)  PATH 'prod/NCM',
                     I08_CFOP             VARCHAR2(4)  PATH 'prod/CFOP',
                     I09_UCOM             VARCHAR2(6)  PATH 'prod/uCom',
                     I10_QCOM_STR         VARCHAR2(30) PATH 'prod/qCom',
                     I10A_VUNCOM_STR      VARCHAR2(30) PATH 'prod/vUnCom',
                     I11_VPROD_STR        VARCHAR2(30) PATH 'prod/vItem',
                     I15_VDESC_STR        VARCHAR2(30) PATH 'prod/vDesc',
                     I17B_INDTOT          VARCHAR2(1)  PATH 'prod/indRegra',
                     ICMS_ORIG            VARCHAR2(1)  PATH 'imposto/ICMS/*/Orig',
                     ICMS_CSOSN           VARCHAR2(4)  PATH 'imposto/ICMS/*/CSOSN',
                     ICMS_VBC_STR         VARCHAR2(30) PATH 'imposto/ICMS/*/vBC',
                     ICMS_PICMS_STR       VARCHAR2(30) PATH 'imposto/ICMS/*/pICMS',
                     ICMS_VICMS_STR       VARCHAR2(30) PATH 'imposto/ICMS/*/vICMS',
                     PIS_CST              VARCHAR2(30) PATH 'imposto/PIS/*/CST',
                     PIS_VBC_STR          VARCHAR2(30) PATH 'imposto/PIS/*/vBC',
                     PIS_PPIS_STR         VARCHAR2(30) PATH 'imposto/PIS/*/pPIS',
                     PIS_QBCPROD_STR      VARCHAR2(30) PATH 'imposto/PIS/*/qBCProd',
                     PIS_VALIQPROD_STR    VARCHAR2(30) PATH 'imposto/PIS/*/vAliqProd',
                     PIS_VPIS_STR         VARCHAR2(30) PATH 'imposto/PIS/*/vPIS',
                     COFINS_CST           VARCHAR2(30) PATH 'imposto/COFINS/*/CST',
                     COFINS_VBC_STR       VARCHAR2(30) PATH 'imposto/COFINS/*/vBC',
                     COFINS_PCOFINS_STR   VARCHAR2(30) PATH 'imposto/COFINS/*/pCOFINS',
                     COFINS_QBCPROD_STR   VARCHAR2(30) PATH 'imposto/COFINS/*/qBCProd',
                     COFINS_VALIQPROD_STR VARCHAR2(30) PATH 'imposto/COFINS/*/vAliqProd',
                     COFINS_VCOFINS_STR   VARCHAR2(30) PATH 'imposto/COFINS/*/vCOFINS'
             ) det
        -- Filtro: apenas CFe unitário (raiz <CFe> sem namespace do lote)
        WHERE XMLExists('/CFe' PASSING XMLTYPE(t.conteudo_xml))
          AND NOT XMLExists(
                  'declare default element namespace "http://www.fazenda.sp.gov.br/sat"; /envCFe'
                  PASSING XMLTYPE(t.conteudo_xml))

        UNION ALL

        /* ==================================================
           [B] LOTE DE CFe — raiz <envCFe>
               namespace: http://www.fazenda.sp.gov.br/sat
               Todos os elementos herdam o namespace default.
        ================================================== */
        SELECT
            'LOTE_CFE'                                                               AS TIPO_DOCUMENTO,
            'LOTE'                                                              AS FORMATO_XML,
            t.NOME_ARQUIVO,
            SUBSTR(capa.ID_CORTADO, 4, 44)                                      AS CHAVE_ACESSO,
            -- Grupo B
            capa.B02_CUF, capa.B03_CNF,
            NULL                                                                AS B04_NATOP,
            capa.B06_MOD, capa.B07_SERIE, capa.NUMERO_NF,
            TO_CHAR(TO_DATE(capa.DEMI_RAW || capa.HEMI_RAW,
                'YYYYMMDDHH24MISS'), 'DD/MM/YYYY')                             AS DATA_EMISSAO_NFE,
            NULL  AS B10_DHSAIENT, NULL  AS B11_TPNF,    NULL  AS B11A_IDDEST,
            NULL  AS B12_CMUNFG,   NULL  AS B21_TPIMP,
            capa.B22_TPEMIS, capa.B23_CDV, capa.B24_TPAMB,
            NULL  AS B25_FINNFE,   NULL  AS B25A_INDFINAL, NULL AS B25B_INDPRES,
            NULL  AS B25C_INDINTERMED, NULL AS B26_PROCEMI, NULL AS B27_VERPROC,
            NULL  AS B28_DHCONT,   NULL  AS B29_XJUST,    NULL  AS B_CMUNFGIBS,
            -- nItem
            TO_NUMBER(REGEXP_REPLACE(det.H02_NITEM,'[^0-9]',''))               AS NITEM,
            -- Emitente
            capa.C02_CNPJ, NULL AS C02A_CPF, capa.C03_XNOME, NULL AS C04_XFANT,
            capa.C05_XLGR, capa.C05_NRO, capa.C05_XCPL, capa.C05_XBAIRRO,
            NULL  AS C05_CMUN, capa.C05_XMUN, NULL AS C05_UF, capa.C05_CEP,
            NULL  AS C05_CPAIS, NULL AS C05_XPAIS, NULL AS C05_FONE,
            capa.C17_IE, NULL AS C18_IEST, capa.C19_IM, NULL AS C20_CNAE, capa.C21_CRT,
            -- Destinatário
            capa.E02_CNPJ, capa.E03_CPF,
            NULL  AS E03A_IDESTRANGEIRO, capa.E04_XNOME,
            NULL  AS E05_XLGR,  NULL AS E05_NRO,   NULL AS E05_XCPL,
            NULL  AS E05_XBAIRRO, NULL AS E05_CMUN, NULL AS E05_XMUN,
            NULL  AS E05_UF,    NULL AS E05_CEP,   NULL AS E05_CPAIS,
            NULL  AS E05_XPAIS, NULL AS E05_FONE,
            NULL  AS E16_INDIEDEST, NULL AS E17_IE, NULL AS E18_ISUF,
            NULL  AS E19_IM,    NULL AS E20_EMAIL,
            -- Produtos
            det.I02_CPROD, det.I03_CEAN, det.I04_XPROD, det.I05_NCM,
            det.I08_CFOP,  det.I09_UCOM,
            ROUND(TO_NUMBER(det.I10_QCOM_STR,    '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I10_QCOM,
            ROUND(TO_NUMBER(det.I10A_VUNCOM_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I10A_VUNCOM,
            ROUND(TO_NUMBER(det.I11_VPROD_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I11_VPROD,
            NULL  AS I12_CEANTRIB, NULL AS I13_UTRIB, NULL AS I14_QTRIB, NULL AS I14A_VUNTRIB,
            ROUND(TO_NUMBER(NVL(det.I15_VDESC_STR,'0'),'99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS I15_VDESC,
            det.I17B_INDTOT,
            -- ICMS
            det.ICMS_ORIG, NULL AS ICMS_CST, det.ICMS_CSOSN,
            ROUND(TO_NUMBER(det.ICMS_VBC_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS ICMS_VBC,
            ROUND(TO_NUMBER(det.ICMS_PICMS_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS ICMS_PICMS,
            ROUND(TO_NUMBER(det.ICMS_VICMS_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS ICMS_VICMS,
            NULL  AS ICMS_VBCST, NULL AS ICMS_PICMSST, NULL AS ICMS_VICMSST,
            NULL  AS IPI_CENQ,   NULL AS IPI_CNPJPROD, NULL AS IPI_CST,
            NULL  AS IPI_VBC,    NULL AS IPI_PIPI,     NULL AS IPI_QUNID,
            NULL  AS IPI_VUNID,  NULL AS IPI_VIPI,
            -- PIS
            det.PIS_CST,
            ROUND(TO_NUMBER(det.PIS_VBC_STR,       '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_VBC,
            ROUND(TO_NUMBER(det.PIS_PPIS_STR,      '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_PPIS,
            ROUND(TO_NUMBER(det.PIS_QBCPROD_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_QBCPROD,
            ROUND(TO_NUMBER(det.PIS_VALIQPROD_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_VALIQPROD,
            ROUND(TO_NUMBER(det.PIS_VPIS_STR,      '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS PIS_VPIS,
            NULL  AS PISST_VBC, NULL AS PISST_PPIS, NULL AS PISST_QBCPROD,
            NULL  AS PISST_VALIQPROD, NULL AS PISST_VPIS,
            -- COFINS
            det.COFINS_CST,
            ROUND(TO_NUMBER(det.COFINS_VBC_STR,       '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_VBC,
            ROUND(TO_NUMBER(det.COFINS_PCOFINS_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_PCOFINS,
            ROUND(TO_NUMBER(det.COFINS_QBCPROD_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_QBCPROD,
            ROUND(TO_NUMBER(det.COFINS_VALIQPROD_STR, '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_VALIQPROD,
            ROUND(TO_NUMBER(det.COFINS_VCOFINS_STR,   '99999999999990.9999999999','NLS_NUMERIC_CHARACTERS = ''. '''),2) AS COFINS_VCOFINS,
            NULL  AS COFINSST_VBC,   NULL AS COFINSST_PCOFINS, NULL AS COFINSST_QBCPROD,
            NULL  AS COFINSST_VALIQPROD, NULL AS COFINSST_VCOFINS

        FROM stg_nfe t,
             -- Capa: navega dentro do lote — todos os elementos no namespace SAT
             XMLTABLE (
                 XMLNAMESPACES (DEFAULT 'http://www.fazenda.sp.gov.br/sat'),
                 '/envCFe/LoteCFe/CFe/infCFe'
                 PASSING XMLTYPE(t.conteudo_xml)
                 COLUMNS
                     ID_CORTADO   VARCHAR2(50) PATH '@Id',
                     NUMERO_NF    VARCHAR2(20) PATH 'ide/nCFe',
                     DEMI_RAW     VARCHAR2(8)  PATH 'ide/dEmi',
                     HEMI_RAW     VARCHAR2(6)  PATH 'ide/hEmi',
                     B02_CUF      VARCHAR2(2)  PATH 'ide/cUF',
                     B03_CNF      VARCHAR2(8)  PATH 'ide/cNF',
                     B06_MOD      VARCHAR2(2)  PATH 'ide/mod',
                     B07_SERIE    VARCHAR2(9)  PATH 'ide/nserieSAT',
                     B22_TPEMIS   VARCHAR2(1)  PATH 'ide/tpEmi',
                     B23_CDV      VARCHAR2(1)  PATH 'ide/cDV',
                     B24_TPAMB    VARCHAR2(1)  PATH 'ide/tpAmb',
                     C02_CNPJ     VARCHAR2(14) PATH 'emit/CNPJ',
                     C03_XNOME    VARCHAR2(60) PATH 'emit/xNome',
                     C05_XLGR     VARCHAR2(60) PATH 'emit/enderEmit/xLgr',
                     C05_NRO      VARCHAR2(60) PATH 'emit/enderEmit/nro',
                     C05_XCPL     VARCHAR2(60) PATH 'emit/enderEmit/xCpl',
                     C05_XBAIRRO  VARCHAR2(60) PATH 'emit/enderEmit/xBairro',
                     C05_XMUN     VARCHAR2(60) PATH 'emit/enderEmit/xMun',
                     C05_CEP      VARCHAR2(8)  PATH 'emit/enderEmit/CEP',
                     C17_IE       VARCHAR2(14) PATH 'emit/IE',
                     C19_IM       VARCHAR2(15) PATH 'emit/IM',
                     C21_CRT      VARCHAR2(1)  PATH 'emit/cRegTrib',
                     E02_CNPJ     VARCHAR2(14) PATH 'dest/CNPJ',
                     E03_CPF      VARCHAR2(11) PATH 'dest/CPF',
                     E04_XNOME    VARCHAR2(60) PATH 'dest/xNome',
                     -- Fragment det ainda no namespace SAT
                     XML_ITENS    XMLTYPE      PATH 'det'
             ) capa,
             -- Itens: fragment herdou o namespace SAT — declarar novamente
             XMLTABLE (
                 XMLNAMESPACES (DEFAULT 'http://www.fazenda.sp.gov.br/sat'),
                 '/det'
                 PASSING capa.XML_ITENS
                 COLUMNS
                     H02_NITEM            VARCHAR2(10) PATH '@nItem',
                     I02_CPROD            VARCHAR2(60) PATH 'prod/cProd',
                     I03_CEAN             VARCHAR2(14) PATH 'prod/cEAN',
                     I04_XPROD            VARCHAR2(120) PATH 'prod/xProd',
                     I05_NCM              VARCHAR2(8)  PATH 'prod/NCM',
                     I08_CFOP             VARCHAR2(4)  PATH 'prod/CFOP',
                     I09_UCOM             VARCHAR2(6)  PATH 'prod/uCom',
                     I10_QCOM_STR         VARCHAR2(30) PATH 'prod/qCom',
                     I10A_VUNCOM_STR      VARCHAR2(30) PATH 'prod/vUnCom',
                     I11_VPROD_STR        VARCHAR2(30) PATH 'prod/vItem',
                     I15_VDESC_STR        VARCHAR2(30) PATH 'prod/vDesc',
                     I17B_INDTOT          VARCHAR2(1)  PATH 'prod/indRegra',
                     ICMS_ORIG            VARCHAR2(1)  PATH 'imposto/ICMS/*/Orig',
                     ICMS_CSOSN           VARCHAR2(4)  PATH 'imposto/ICMS/*/CSOSN',
                     ICMS_VBC_STR         VARCHAR2(30) PATH 'imposto/ICMS/*/vBC',
                     ICMS_PICMS_STR       VARCHAR2(30) PATH 'imposto/ICMS/*/pICMS',
                     ICMS_VICMS_STR       VARCHAR2(30) PATH 'imposto/ICMS/*/vICMS',
                     PIS_CST              VARCHAR2(30) PATH 'imposto/PIS/*/CST',
                     PIS_VBC_STR          VARCHAR2(30) PATH 'imposto/PIS/*/vBC',
                     PIS_PPIS_STR         VARCHAR2(30) PATH 'imposto/PIS/*/pPIS',
                     PIS_QBCPROD_STR      VARCHAR2(30) PATH 'imposto/PIS/*/qBCProd',
                     PIS_VALIQPROD_STR    VARCHAR2(30) PATH 'imposto/PIS/*/vAliqProd',
                     PIS_VPIS_STR         VARCHAR2(30) PATH 'imposto/PIS/*/vPIS',
                     COFINS_CST           VARCHAR2(30) PATH 'imposto/COFINS/*/CST',
                     COFINS_VBC_STR       VARCHAR2(30) PATH 'imposto/COFINS/*/vBC',
                     COFINS_PCOFINS_STR   VARCHAR2(30) PATH 'imposto/COFINS/*/pCOFINS',
                     COFINS_QBCPROD_STR   VARCHAR2(30) PATH 'imposto/COFINS/*/qBCProd',
                     COFINS_VALIQPROD_STR VARCHAR2(30) PATH 'imposto/COFINS/*/vAliqProd',
                     COFINS_VCOFINS_STR   VARCHAR2(30) PATH 'imposto/COFINS/*/vCOFINS'
             ) det
        -- Filtro: apenas lotes (raiz <envCFe> com namespace SAT)
        WHERE XMLExists(
                  'declare default element namespace "http://www.fazenda.sp.gov.br/sat"; /envCFe'
                  PASSING XMLTYPE(t.conteudo_xml));

    /* ----------------------------------------------------------
       Tipos e variáveis
    ---------------------------------------------------------- */
    TYPE t_doc_array  IS TABLE OF c_cfe%ROWTYPE;
    v_doc_array       t_doc_array;
    e_bulk_errors     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

    V_ITEM_OK   PLS_INTEGER := 0;
    V_ITEM_ERR  PLS_INTEGER := 0;

    /* ----------------------------------------------------------
       Log autônomo — grava mesmo que o lote sofra rollback
    ---------------------------------------------------------- */
    PROCEDURE gravar_log (
        p_arquivo  IN VARCHAR2,
        p_chave    IN VARCHAR2,
        p_nitem    IN NUMBER,
        p_formato  IN VARCHAR2,
        p_origem   IN VARCHAR2,
        p_cod      IN NUMBER,
        p_msg      IN VARCHAR2,
        p_trace    IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TB_LOG_CFE_REFORMA
            (NOME_ARQUIVO, CHAVE_ACESSO, NITEM, FORMATO_XML,
             ORIGEM, ORA_CODE, ORA_MSG, BACKTRACE)
        VALUES
            (p_arquivo, p_chave, p_nitem, p_formato,
             p_origem, p_cod, SUBSTR(p_msg,1,4000), SUBSTR(p_trace,1,4000));
        COMMIT;
    END gravar_log;

BEGIN
    DBMS_OUTPUT.ENABLE(1000000);
    DBMS_OUTPUT.PUT_LINE('=== INÍCIO === ' || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));

    -- Limpeza total a cada execução
    --EXECUTE IMMEDIATE 'TRUNCATE TABLE TB_LOG_CFE_REFORMA';
    --EXECUTE IMMEDIATE 'TRUNCATE TABLE TB_REFORMA_CONSOLIDADA';
    -- DBMS_OUTPUT.PUT_LINE('Tabelas truncadas.');

    OPEN c_cfe;
    LOOP
        FETCH c_cfe BULK COLLECT INTO v_doc_array LIMIT 1000;
        EXIT WHEN v_doc_array.COUNT = 0;

        BEGIN
            FORALL i IN 1 .. v_doc_array.COUNT SAVE EXCEPTIONS
                INSERT INTO TB_REFORMA_CONSOLIDADA (
                    TIPO_DOCUMENTO, NOME_ARQUIVO, CHAVE_ACESSO,
                    B02_CUF, B03_CNF, B04_NATOP, B06_MOD, B07_SERIE, NUMERO_NF, DATA_EMISSAO_NFE,
                    B10_DHSAIENT, B11_TPNF, B11A_IDDEST, B12_CMUNFG, B21_TPIMP,
                    B22_TPEMIS, B23_CDV, B24_TPAMB, B25_FINNFE, B25A_INDFINAL,
                    B25B_INDPRES, B25C_INDINTERMED, B26_PROCEMI, B27_VERPROC,
                    B28_DHCONT, B29_XJUST, B_CMUNFGIBS,
                    NITEM,
                    C02_CNPJ, C02A_CPF, C03_XNOME, C04_XFANT,
                    C05_XLGR, C05_NRO, C05_XCPL, C05_XBAIRRO, C05_CMUN, C05_XMUN,
                    C05_UF, C05_CEP, C05_CPAIS, C05_XPAIS, C05_FONE,
                    C17_IE, C18_IEST, C19_IM, C20_CNAE, C21_CRT,
                    E02_CNPJ, E03_CPF, E03A_IDESTRANGEIRO, E04_XNOME,
                    E05_XLGR, E05_NRO, E05_XCPL, E05_XBAIRRO, E05_CMUN, E05_XMUN,
                    E05_UF, E05_CEP, E05_CPAIS, E05_XPAIS, E05_FONE,
                    E16_INDIEDEST, E17_IE, E18_ISUF, E19_IM, E20_EMAIL,
                    I02_CPROD, I03_CEAN, I04_XPROD, I05_NCM, I08_CFOP, I09_UCOM,
                    I10_QCOM, I10A_VUNCOM, I11_VPROD, I12_CEANTRIB, I13_UTRIB,
                    I14_QTRIB, I14A_VUNTRIB, I15_VDESC, I17B_INDTOT,
                    ICMS_ORIG, ICMS_CST, ICMS_CSOSN, ICMS_VBC, ICMS_PICMS, ICMS_VICMS,
                    ICMS_VBCST, ICMS_PICMSST, ICMS_VICMSST,
                    IPI_CENQ, IPI_CNPJPROD, IPI_CST, IPI_VBC, IPI_PIPI,
                    IPI_QUNID, IPI_VUNID, IPI_VIPI,
                    PIS_CST, PIS_VBC, PIS_PPIS, PIS_QBCPROD, PIS_VALIQPROD, PIS_VPIS,
                    PISST_VBC, PISST_PPIS, PISST_QBCPROD, PISST_VALIQPROD, PISST_VPIS,
                    COFINS_CST, COFINS_VBC, COFINS_PCOFINS, COFINS_QBCPROD,
                    COFINS_VALIQPROD, COFINS_VCOFINS,
                    COFINSST_VBC, COFINSST_PCOFINS, COFINSST_QBCPROD,
                    COFINSST_VALIQPROD, COFINSST_VCOFINS
                ) VALUES (
                    v_doc_array(i).TIPO_DOCUMENTO,
                    v_doc_array(i).NOME_ARQUIVO,
                    v_doc_array(i).CHAVE_ACESSO,
                    v_doc_array(i).B02_CUF,        v_doc_array(i).B03_CNF,
                    v_doc_array(i).B04_NATOP,       v_doc_array(i).B06_MOD,
                    v_doc_array(i).B07_SERIE,       v_doc_array(i).NUMERO_NF,
                    v_doc_array(i).DATA_EMISSAO_NFE,
                    v_doc_array(i).B10_DHSAIENT,    v_doc_array(i).B11_TPNF,
                    v_doc_array(i).B11A_IDDEST,     v_doc_array(i).B12_CMUNFG,
                    v_doc_array(i).B21_TPIMP,       v_doc_array(i).B22_TPEMIS,
                    v_doc_array(i).B23_CDV,         v_doc_array(i).B24_TPAMB,
                    v_doc_array(i).B25_FINNFE,      v_doc_array(i).B25A_INDFINAL,
                    v_doc_array(i).B25B_INDPRES,    v_doc_array(i).B25C_INDINTERMED,
                    v_doc_array(i).B26_PROCEMI,     v_doc_array(i).B27_VERPROC,
                    v_doc_array(i).B28_DHCONT,      v_doc_array(i).B29_XJUST,
                    v_doc_array(i).B_CMUNFGIBS,
                    v_doc_array(i).NITEM,
                    v_doc_array(i).C02_CNPJ,        v_doc_array(i).C02A_CPF,
                    v_doc_array(i).C03_XNOME,       v_doc_array(i).C04_XFANT,
                    v_doc_array(i).C05_XLGR,        v_doc_array(i).C05_NRO,
                    v_doc_array(i).C05_XCPL,        v_doc_array(i).C05_XBAIRRO,
                    v_doc_array(i).C05_CMUN,        v_doc_array(i).C05_XMUN,
                    v_doc_array(i).C05_UF,          v_doc_array(i).C05_CEP,
                    v_doc_array(i).C05_CPAIS,       v_doc_array(i).C05_XPAIS,
                    v_doc_array(i).C05_FONE,
                    v_doc_array(i).C17_IE,          v_doc_array(i).C18_IEST,
                    v_doc_array(i).C19_IM,          v_doc_array(i).C20_CNAE,
                    v_doc_array(i).C21_CRT,
                    v_doc_array(i).E02_CNPJ,        v_doc_array(i).E03_CPF,
                    v_doc_array(i).E03A_IDESTRANGEIRO, v_doc_array(i).E04_XNOME,
                    v_doc_array(i).E05_XLGR,        v_doc_array(i).E05_NRO,
                    v_doc_array(i).E05_XCPL,        v_doc_array(i).E05_XBAIRRO,
                    v_doc_array(i).E05_CMUN,        v_doc_array(i).E05_XMUN,
                    v_doc_array(i).E05_UF,          v_doc_array(i).E05_CEP,
                    v_doc_array(i).E05_CPAIS,       v_doc_array(i).E05_XPAIS,
                    v_doc_array(i).E05_FONE,
                    v_doc_array(i).E16_INDIEDEST,   v_doc_array(i).E17_IE,
                    v_doc_array(i).E18_ISUF,        v_doc_array(i).E19_IM,
                    v_doc_array(i).E20_EMAIL,
                    v_doc_array(i).I02_CPROD,       v_doc_array(i).I03_CEAN,
                    v_doc_array(i).I04_XPROD,       v_doc_array(i).I05_NCM,
                    v_doc_array(i).I08_CFOP,        v_doc_array(i).I09_UCOM,
                    v_doc_array(i).I10_QCOM,        v_doc_array(i).I10A_VUNCOM,
                    v_doc_array(i).I11_VPROD,       v_doc_array(i).I12_CEANTRIB,
                    v_doc_array(i).I13_UTRIB,       v_doc_array(i).I14_QTRIB,
                    v_doc_array(i).I14A_VUNTRIB,    v_doc_array(i).I15_VDESC,
                    v_doc_array(i).I17B_INDTOT,
                    v_doc_array(i).ICMS_ORIG,       v_doc_array(i).ICMS_CST,
                    v_doc_array(i).ICMS_CSOSN,      v_doc_array(i).ICMS_VBC,
                    v_doc_array(i).ICMS_PICMS,      v_doc_array(i).ICMS_VICMS,
                    v_doc_array(i).ICMS_VBCST,      v_doc_array(i).ICMS_PICMSST,
                    v_doc_array(i).ICMS_VICMSST,
                    v_doc_array(i).IPI_CENQ,        v_doc_array(i).IPI_CNPJPROD,
                    v_doc_array(i).IPI_CST,         v_doc_array(i).IPI_VBC,
                    v_doc_array(i).IPI_PIPI,        v_doc_array(i).IPI_QUNID,
                    v_doc_array(i).IPI_VUNID,       v_doc_array(i).IPI_VIPI,
                    v_doc_array(i).PIS_CST,         v_doc_array(i).PIS_VBC,
                    v_doc_array(i).PIS_PPIS,        v_doc_array(i).PIS_QBCPROD,
                    v_doc_array(i).PIS_VALIQPROD,   v_doc_array(i).PIS_VPIS,
                    v_doc_array(i).PISST_VBC,       v_doc_array(i).PISST_PPIS,
                    v_doc_array(i).PISST_QBCPROD,   v_doc_array(i).PISST_VALIQPROD,
                    v_doc_array(i).PISST_VPIS,
                    v_doc_array(i).COFINS_CST,      v_doc_array(i).COFINS_VBC,
                    v_doc_array(i).COFINS_PCOFINS,  v_doc_array(i).COFINS_QBCPROD,
                    v_doc_array(i).COFINS_VALIQPROD, v_doc_array(i).COFINS_VCOFINS,
                    v_doc_array(i).COFINSST_VBC,    v_doc_array(i).COFINSST_PCOFINS,
                    v_doc_array(i).COFINSST_QBCPROD, v_doc_array(i).COFINSST_VALIQPROD,
                    v_doc_array(i).COFINSST_VCOFINS
                );

            V_ITEM_OK := V_ITEM_OK + SQL%ROWCOUNT;

        EXCEPTION
            WHEN e_bulk_errors THEN
                FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                    V_ITEM_ERR := V_ITEM_ERR + 1;
                    gravar_log(
                        p_arquivo => v_doc_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).NOME_ARQUIVO,
                        p_chave   => v_doc_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).CHAVE_ACESSO,
                        p_nitem   => v_doc_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).NITEM,
                        p_formato => v_doc_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).FORMATO_XML,
                        p_origem  => 'BLOCO_TESTE_CFE > FORALL INSERT',
                        p_cod     => SQL%BULK_EXCEPTIONS(i).ERROR_CODE,
                        p_msg     => SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE),
                        p_trace   => DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
                    );
                END LOOP;
        END;

        COMMIT;
    END LOOP;
    CLOSE c_cfe;

    -- Resumo final
    DECLARE V_UNIT NUMBER; V_LOTE NUMBER; V_TOTAL NUMBER;
    BEGIN
        SELECT COUNT(*) INTO V_UNIT  FROM TB_REFORMA_CONSOLIDADA WHERE TIPO_DOCUMENTO = 'CFE';
        SELECT COUNT(*) INTO V_LOTE  FROM TB_LOG_CFE_REFORMA WHERE FORMATO_XML = 'LOTE_CFE';
        SELECT COUNT(*) INTO V_TOTAL FROM TB_LOG_CFE_REFORMA;
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('====== RESUMO FINAL ======');
        DBMS_OUTPUT.PUT_LINE('Itens inseridos (OK) : ' || V_ITEM_OK);
        DBMS_OUTPUT.PUT_LINE('Itens com erro (LOG) : ' || V_ITEM_ERR);
        DBMS_OUTPUT.PUT_LINE('Total em destino     : ' || V_UNIT);
        DBMS_OUTPUT.PUT_LINE('Erros de lote no log : ' || V_LOTE);
        DBMS_OUTPUT.PUT_LINE('Total erros no log   : ' || V_TOTAL);
        DBMS_OUTPUT.PUT_LINE('==========================');
        DBMS_OUTPUT.PUT_LINE('Fim: ' || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    END;
    
    
    
/* ============================================================
   CONSULTAS DE VERIFICAÇÃO PÓS-EXECUÇÃO
   ============================================================ */

-- Contagem por formato processado
--SELECT TIPO_DOCUMENTO, COUNT(*) AS QTD_ITENS
--FROM TB_REFORMA_CONSOLIDADA
--WHERE TIPO_DOCUMENTO <> 'CFE'
--GROUP BY TIPO_DOCUMENTO;
--
---- Log de erros com detalhe do formato
--SELECT ID_LOG, DT_PROCESSAMENTO, NOME_ARQUIVO, CHAVE_ACESSO,
--       NITEM, FORMATO_XML, ORIGEM, ORA_CODE, ORA_MSG
--FROM TB_LOG_CFE_REFORMA
--ORDER BY DT_PROCESSAMENTO DESC;
    

END  PRC_CFE_REFORMA_CONSOLIDADA;
/
