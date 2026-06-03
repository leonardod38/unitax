CREATE OR REPLACE PROCEDURE USER_XMLS.PRC_NFE_REFORMA_TRIBUTARIA AS
--DECLARE
    CURSOR c_docs IS
        SELECT
            'NFE'                                                           AS TIPO_DOCUMENTO,
            SUBSTR(capa.CHAVE_ACESSO_RAW, 4, 44)                           AS CHAVE_ACESSO,
            capa.NUMERO_NF,
            TO_CHAR(TO_TIMESTAMP_TZ(capa.DATA_EMISSAO_RAW,
                'YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'), 'DD/MM/YYYY')          AS DATA_EMISSAO,
            -- [FIX 1] COALESCE: atributo @nItem tem prioridade; se nulo usa elemento nItem
            TO_NUMBER(REGEXP_REPLACE(
                COALESCE(det.H02_NITEM_ATTR, det.H02_NITEM_ELEM),
            '[^0-9]', ''))                                                  AS NITEM,

            -- IS
            det.IS_CST,
            det.IS_CCLASS_TRIB,
            ROUND(USER_XMLS.F_TO_NUM(det.IS_VBC_STR),       2)             AS IS_VBC,
            ROUND(USER_XMLS.F_TO_NUM(det.IS_PIS_STR),       2)             AS IS_PIS,
            ROUND(USER_XMLS.F_TO_NUM(det.IS_PIS_ESPEC_STR), 4)             AS IS_PIS_ESPEC,
            det.IS_UTRIB,
            ROUND(USER_XMLS.F_TO_NUM(det.IS_QTRIB_STR),     4)             AS IS_QTRIB,
            ROUND(USER_XMLS.F_TO_NUM(det.IS_VIS_STR),       2)             AS IS_VIS,

            -- IBS / CBS
            det.IBSCBS_CST,
            det.IBSCBS_CCLASS_TRIB,
            ROUND(USER_XMLS.F_TO_NUM(det.IBS_VBC_STR),      2)             AS IBS_VBC,
            ROUND(USER_XMLS.F_TO_NUM(det.IBS_VIBS_STR),     2)             AS IBS_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.IBS_PIBSUF_STR),   4)             AS IBS_PIBSUF,
            ROUND(USER_XMLS.F_TO_NUM(det.IBS_VIBSUF_STR),   2)             AS IBS_VIBSUF,
            ROUND(USER_XMLS.F_TO_NUM(det.IBS_PIBSMUN_STR),  4)             AS IBS_PIBSMUN,
            ROUND(USER_XMLS.F_TO_NUM(det.IBS_VIBSMUN_STR),  2)             AS IBS_VIBSMUN,
            ROUND(USER_XMLS.F_TO_NUM(det.CBS_VBC_STR),      2)             AS CBS_VBC,
            ROUND(USER_XMLS.F_TO_NUM(det.CBS_PCBS_STR),     4)             AS CBS_PCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.CBS_VCBS_STR),     2)             AS CBS_VCBS,

            -- Devolução / Redução
            ROUND(USER_XMLS.F_TO_NUM(det.DEV_VTRIB_STR),    2)             AS DEV_VTRIB,
            ROUND(USER_XMLS.F_TO_NUM(det.RED_PREDALIQ_STR), 4)             AS RED_PREDALIQ,
            ROUND(USER_XMLS.F_TO_NUM(det.RED_PALIQEFET_STR),4)             AS RED_PALIQEFET,

            -- Regime Específico
            det.TRIB_REG_CST,
            det.TRIB_REG_CCLASS_TRIB,
            ROUND(USER_XMLS.F_TO_NUM(det.TRIB_REG_P_IBSUF), 4)            AS TRIB_REG_PALIQ_IBSUF,
            ROUND(USER_XMLS.F_TO_NUM(det.TRIB_REG_V_IBSUF), 2)            AS TRIB_REG_VTRIB_IBSUF,
            ROUND(USER_XMLS.F_TO_NUM(det.TRIB_REG_P_IBSMUN),4)            AS TRIB_REG_PALIQ_IBSMUN,
            ROUND(USER_XMLS.F_TO_NUM(det.TRIB_REG_V_IBSMUN),2)            AS TRIB_REG_VTRIB_IBSMUN,
            ROUND(USER_XMLS.F_TO_NUM(det.TRIB_REG_P_CBS),   4)            AS TRIB_REG_PALIQ_CBS,
            ROUND(USER_XMLS.F_TO_NUM(det.TRIB_REG_V_CBS),   2)            AS TRIB_REG_VTRIB_CBS,

            -- Comp. Governamental
            ROUND(USER_XMLS.F_TO_NUM(det.CG_P_IBSUF),       4)            AS COMP_GOV_PALIQ_IBSUF,
            ROUND(USER_XMLS.F_TO_NUM(det.CG_V_IBSUF),       2)            AS COMP_GOV_VTRIB_IBSUF,
            ROUND(USER_XMLS.F_TO_NUM(det.CG_P_IBSMUN),      4)            AS COMP_GOV_PALIQ_IBSMUN,
            ROUND(USER_XMLS.F_TO_NUM(det.CG_V_IBSMUN),      2)            AS COMP_GOV_VTRIB_IBSMUN,
            ROUND(USER_XMLS.F_TO_NUM(det.CG_P_CBS),         4)            AS COMP_GOV_PALIQ_CBS,
            ROUND(USER_XMLS.F_TO_NUM(det.CG_V_CBS),         2)            AS COMP_GOV_VTRIB_CBS,

            -- Monofásico
            ROUND(USER_XMLS.F_TO_NUM(det.M_QBC),            4)            AS MONO_QBCMONO,
            ROUND(USER_XMLS.F_TO_NUM(det.M_AD_IBS),         4)            AS MONO_ADREMIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.M_AD_CBS),         4)            AS MONO_ADREMCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.M_V_IBS),          2)            AS MONO_VIBSMONO,
            ROUND(USER_XMLS.F_TO_NUM(det.M_V_CBS),          2)            AS MONO_VCBSMONO,

            -- Mono Retenção
            ROUND(USER_XMLS.F_TO_NUM(det.MR_VBC),           2)            AS MONO_RET_VBC,
            ROUND(USER_XMLS.F_TO_NUM(det.MR_QBC),           4)            AS MONO_RET_QBCMONO,
            ROUND(USER_XMLS.F_TO_NUM(det.MR_AD_IBS),        4)            AS MONO_RET_ADREMIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MR_AD_CBS),        4)            AS MONO_RET_ADREMCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MR_V_IBS),         2)            AS MONO_RET_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MR_V_CBS),         2)            AS MONO_RET_VCBS,

            -- Mono Antecipação
            ROUND(USER_XMLS.F_TO_NUM(det.MA_VBC),           2)            AS MONO_ANT_VBC,
            ROUND(USER_XMLS.F_TO_NUM(det.MA_QBC),           4)            AS MONO_ANT_QBCMONO,
            ROUND(USER_XMLS.F_TO_NUM(det.MA_AD_IBS),        4)            AS MONO_ANT_ADREMIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MA_AD_CBS),        4)            AS MONO_ANT_ADREMCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MA_V_IBS),         2)            AS MONO_ANT_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MA_V_CBS),         2)            AS MONO_ANT_VCBS,

            -- Mono Diferimento
            ROUND(USER_XMLS.F_TO_NUM(det.MD_P_IBS),         4)            AS MONO_DIF_PIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MD_V_IBS),         2)            AS MONO_DIF_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MD_P_CBS),         4)            AS MONO_DIF_PCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.MD_V_CBS),         2)            AS MONO_DIF_VCBS,

            -- Transferência / ZFM / Ajuste / Estorno
            ROUND(USER_XMLS.F_TO_NUM(det.TR_V_IBS),         2)            AS TRANSF_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.TR_V_CBS),         2)            AS TRANSF_VCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.Z_P_IBS),          4)            AS ZFM_PIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.Z_V_IBS),          2)            AS ZFM_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.Z_P_CBS),          4)            AS ZFM_PCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.Z_V_CBS),          2)            AS ZFM_VCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.AJ_V_IBS),         2)            AS AJ_COMP_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.AJ_V_CBS),         2)            AS AJ_COMP_VCBS,
            ROUND(USER_XMLS.F_TO_NUM(det.ES_V_IBS),         2)            AS ESTORNO_VIBS,
            ROUND(USER_XMLS.F_TO_NUM(det.ES_V_CBS),         2)            AS ESTORNO_VCBS

        FROM STG_NFE t,
             XMLTABLE (
                 XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                 '/nfeProc/NFe/infNFe'
                 PASSING XMLTYPE(t.CONTEUDO_XML)
                 COLUMNS
                     CHAVE_ACESSO_RAW  VARCHAR2(50) PATH '@Id',
                     NUMERO_NF         VARCHAR2(20) PATH 'ide/nNF',
                     DATA_EMISSAO_RAW  VARCHAR2(30) PATH 'ide/dhEmi'
             ) capa,
             XMLTABLE (
                 XMLNAMESPACES (DEFAULT 'http://www.portalfiscal.inf.br/nfe'),
                 '/nfeProc/NFe/infNFe/det'
                 PASSING XMLTYPE(t.CONTEUDO_XML)
                 COLUMNS
                     -- [FIX 1] dois campos para cobrir @nItem (atributo) e nItem (elemento filho)
                     H02_NITEM_ATTR       VARCHAR2(10) PATH '@nItem',
                     H02_NITEM_ELEM       VARCHAR2(10) PATH 'nItem',
                     -- IS
                     IS_CST               VARCHAR2(3)  PATH 'imposto/IS/CSTIS',
                     IS_CCLASS_TRIB       VARCHAR2(6)  PATH 'imposto/IS/cClassTribIS',
                     IS_VBC_STR           VARCHAR2(30) PATH 'imposto/IS/vBCIS',
                     IS_PIS_STR           VARCHAR2(30) PATH 'imposto/IS/pIS',
                     IS_PIS_ESPEC_STR     VARCHAR2(30) PATH 'imposto/IS/pISEspec',
                     IS_UTRIB             VARCHAR2(20) PATH 'imposto/IS/uTrib',
                     IS_QTRIB_STR         VARCHAR2(30) PATH 'imposto/IS/qTrib',
                     IS_VIS_STR           VARCHAR2(30) PATH 'imposto/IS/vIS',
                     -- IBS / CBS
                     IBSCBS_CST           VARCHAR2(3)  PATH 'imposto/IBSCBS/CST',
                     IBSCBS_CCLASS_TRIB   VARCHAR2(6)  PATH 'imposto/IBSCBS/cClassTrib',
                     IBS_VBC_STR          VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/vBC',
                     IBS_VIBS_STR         VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/vIBS',
                     IBS_PIBSUF_STR       VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/gIBSUF/pIBSUF',
                     IBS_VIBSUF_STR       VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/gIBSUF/vIBSUF',
                     IBS_PIBSMUN_STR      VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/gIBSMun/pIBSMun',
                     IBS_VIBSMUN_STR      VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/gIBSMun/vIBSMun',
                     CBS_VBC_STR          VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/gCBS/vBC',
                     CBS_PCBS_STR         VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/gCBS/pCBS',
                     CBS_VCBS_STR         VARCHAR2(30) PATH 'imposto/IBSCBS/gIBSCBS/gCBS/vCBS',
                     -- Devolução / Redução
                     DEV_VTRIB_STR        VARCHAR2(30) PATH 'imposto/IBSCBS/vDevTrib',
                     RED_PREDALIQ_STR     VARCHAR2(30) PATH 'imposto/IBSCBS/pRedAliq',
                     RED_PALIQEFET_STR    VARCHAR2(30) PATH 'imposto/IBSCBS/pAliqEfet',
                     -- Regime Específico
                     TRIB_REG_CST         VARCHAR2(3)  PATH 'imposto/IBSCBS/tribRegIBSCBS/CSTReg',
                     TRIB_REG_CCLASS_TRIB VARCHAR2(6)  PATH 'imposto/IBSCBS/tribRegIBSCBS/cClassTribReg',
                     TRIB_REG_P_IBSUF     VARCHAR2(30) PATH 'imposto/IBSCBS/tribRegIBSCBS/pAliqEfetRegIBSUF',
                     TRIB_REG_V_IBSUF     VARCHAR2(30) PATH 'imposto/IBSCBS/tribRegIBSCBS/vTribRegIBSUF',
                     TRIB_REG_P_IBSMUN    VARCHAR2(30) PATH 'imposto/IBSCBS/tribRegIBSCBS/pAliqEfetRegIBSMun',
                     TRIB_REG_V_IBSMUN    VARCHAR2(30) PATH 'imposto/IBSCBS/tribRegIBSCBS/vTribRegIBSMun',
                     TRIB_REG_P_CBS       VARCHAR2(30) PATH 'imposto/IBSCBS/tribRegIBSCBS/pAliqEfetRegCBS',
                     TRIB_REG_V_CBS       VARCHAR2(30) PATH 'imposto/IBSCBS/tribRegIBSCBS/vTribRegCBS',
                     -- Comp. Governamental
                     CG_P_IBSUF           VARCHAR2(30) PATH 'imposto/IBSCBS/compGovIBSCBS/pAliqIBSUF',
                     CG_V_IBSUF           VARCHAR2(30) PATH 'imposto/IBSCBS/compGovIBSCBS/vTribIBSUF',
                     CG_P_IBSMUN          VARCHAR2(30) PATH 'imposto/IBSCBS/compGovIBSCBS/pAliqIBSMun',
                     CG_V_IBSMUN          VARCHAR2(30) PATH 'imposto/IBSCBS/compGovIBSCBS/vTribIBSMun',
                     CG_P_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/compGovIBSCBS/pAliqCBS',
                     CG_V_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/compGovIBSCBS/vTribCBS',
                     -- Monofásico
                     M_QBC                VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoIBSCBS/qBCMono',
                     M_AD_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoIBSCBS/adRemIBS',
                     M_AD_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoIBSCBS/adRemCBS',
                     M_V_IBS              VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoIBSCBS/vIBSMono',
                     M_V_CBS              VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoIBSCBS/vCBSMono',
                     -- Mono Retenção
                     MR_VBC               VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetenIBSCBS/vBCMonoReten',
                     MR_QBC               VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetenIBSCBS/qBCMonoReten',
                     MR_AD_IBS            VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetenIBSCBS/adRemIBSReten',
                     MR_AD_CBS            VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetenIBSCBS/adRemCBSReten',
                     MR_V_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetenIBSCBS/vIBSMonoReten',
                     MR_V_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetenIBSCBS/vCBSMonoReten',
                     -- Mono Antecipação
                     MA_VBC               VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetAntIBSCBS/vBCMonoRetAnt',
                     MA_QBC               VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetAntIBSCBS/qBCMonoRetAnt',
                     MA_AD_IBS            VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetAntIBSCBS/adRemIBSRetAnt',
                     MA_AD_CBS            VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetAntIBSCBS/adRemCBSRetAnt',
                     MA_V_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetAntIBSCBS/vIBSMonoRetAnt',
                     MA_V_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoRetAntIBSCBS/vCBSMonoRetAnt',
                     -- Mono Diferimento
                     MD_P_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoDifIBSCBS/pIBSMonoDif',
                     MD_V_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoDifIBSCBS/vIBSMonoDif',
                     MD_P_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoDifIBSCBS/pCBSMonoDif',
                     MD_V_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/tribMonoDifIBSCBS/vCBSMonoDif',
                     -- Transferência
                     TR_V_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/vTransfCredIBSCBS/vTransfCredIBS',
                     TR_V_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/vTransfCredIBSCBS/vTransfCredCBS',
                     -- ZFM
                     Z_P_IBS              VARCHAR2(30) PATH 'imposto/IBSCBS/vCredPresIBSCBSZFM/pCredPresIBSZFM',
                     Z_V_IBS              VARCHAR2(30) PATH 'imposto/IBSCBS/vCredPresIBSCBSZFM/vCredPresIBSZFM',
                     Z_P_CBS              VARCHAR2(30) PATH 'imposto/IBSCBS/vCredPresIBSCBSZFM/pCredPresCBSZFM',
                     Z_V_CBS              VARCHAR2(30) PATH 'imposto/IBSCBS/vCredPresIBSCBSZFM/vCredPresCBSZFM',
                     -- Ajuste / Estorno
                     AJ_V_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/vAjCompIBSCBS/vAjCompIBS',
                     AJ_V_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/vAjCompIBSCBS/vAjCompCBS',
                     ES_V_IBS             VARCHAR2(30) PATH 'imposto/IBSCBS/vEstCredIBSCBS/vEstCredIBS',
                     ES_V_CBS             VARCHAR2(30) PATH 'imposto/IBSCBS/vEstCredIBSCBS/vEstCredCBS'
             ) det
        WHERE t.CONTEUDO_XML IS NOT NULL;

    TYPE t_doc_array IS TABLE OF c_docs%ROWTYPE;
    v_doc_array     t_doc_array;
    e_bulk_errors   EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

    PROCEDURE gravar_log (
        p_chave IN VARCHAR2,
        p_nitem IN NUMBER,
        p_cod   IN NUMBER,
        p_msg   IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TB_REFORMA_TRIBUTARIA_LOG
            (CHAVE_ACESSO, NITEM, ORA_CODE, ORA_MSG)
        VALUES
            (p_chave, p_nitem, p_cod, SUBSTR(p_msg, 1, 4000));
        COMMIT;
    END gravar_log;

BEGIN
    

    OPEN c_docs;
    LOOP
        FETCH c_docs BULK COLLECT INTO v_doc_array LIMIT 1000;
        EXIT WHEN v_doc_array.COUNT = 0;

        BEGIN
            FORALL i IN 1 .. v_doc_array.COUNT SAVE EXCEPTIONS
                INSERT INTO TB_REFORMA_TRIBUTARIA (
                    TIPO_DOCUMENTO,  CHAVE_ACESSO,    NUMERO_NF,
                    DATA_EMISSAO,    NITEM,
                    IS_CST,          IS_CCLASS_TRIB,
                    IS_VBC,          IS_PIS,          IS_PIS_ESPEC,
                    IS_UTRIB,        IS_QTRIB,        IS_VIS,
                    IBSCBS_CST,      IBSCBS_CCLASS_TRIB,
                    IBS_VBC,         IBS_VIBS,
                    IBS_PIBSUF,      IBS_VIBSUF,
                    IBS_PIBSMUN,     IBS_VIBSMUN,
                    CBS_VBC,         CBS_PCBS,        CBS_VCBS,
                    DEV_VTRIB,
                    RED_PREDALIQ,    RED_PALIQEFET,
                    TRIB_REG_CST,    TRIB_REG_CCLASS_TRIB,
                    TRIB_REG_PALIQ_IBSUF,  TRIB_REG_VTRIB_IBSUF,
                    TRIB_REG_PALIQ_IBSMUN, TRIB_REG_VTRIB_IBSMUN,
                    TRIB_REG_PALIQ_CBS,    TRIB_REG_VTRIB_CBS,
                    COMP_GOV_PALIQ_IBSUF,  COMP_GOV_VTRIB_IBSUF,
                    COMP_GOV_PALIQ_IBSMUN, COMP_GOV_VTRIB_IBSMUN,
                    COMP_GOV_PALIQ_CBS,    COMP_GOV_VTRIB_CBS,
                    MONO_QBCMONO,    MONO_ADREMIBS,   MONO_ADREMCBS,
                    MONO_VIBSMONO,   MONO_VCBSMONO,
                    MONO_RET_VBC,    MONO_RET_QBCMONO,
                    MONO_RET_ADREMIBS, MONO_RET_ADREMCBS,
                    MONO_RET_VIBS,   MONO_RET_VCBS,
                    MONO_ANT_VBC,    MONO_ANT_QBCMONO,
                    MONO_ANT_ADREMIBS, MONO_ANT_ADREMCBS,
                    MONO_ANT_VIBS,   MONO_ANT_VCBS,
                    MONO_DIF_PIBS,   MONO_DIF_VIBS,
                    MONO_DIF_PCBS,   MONO_DIF_VCBS,
                    TRANSF_VIBS,     TRANSF_VCBS,
                    ZFM_PIBS,        ZFM_VIBS,
                    ZFM_PCBS,        ZFM_VCBS,
                    AJ_COMP_VIBS,    AJ_COMP_VCBS,
                    ESTORNO_VIBS,    ESTORNO_VCBS
                ) VALUES (
                    v_doc_array(i).TIPO_DOCUMENTO,
                    v_doc_array(i).CHAVE_ACESSO,
                    v_doc_array(i).NUMERO_NF,
                    v_doc_array(i).DATA_EMISSAO,
                    v_doc_array(i).NITEM,
                    v_doc_array(i).IS_CST,
                    v_doc_array(i).IS_CCLASS_TRIB,
                    v_doc_array(i).IS_VBC,
                    v_doc_array(i).IS_PIS,
                    v_doc_array(i).IS_PIS_ESPEC,
                    v_doc_array(i).IS_UTRIB,
                    v_doc_array(i).IS_QTRIB,
                    v_doc_array(i).IS_VIS,
                    v_doc_array(i).IBSCBS_CST,
                    v_doc_array(i).IBSCBS_CCLASS_TRIB,
                    v_doc_array(i).IBS_VBC,
                    v_doc_array(i).IBS_VIBS,
                    v_doc_array(i).IBS_PIBSUF,
                    v_doc_array(i).IBS_VIBSUF,
                    v_doc_array(i).IBS_PIBSMUN,
                    v_doc_array(i).IBS_VIBSMUN,
                    v_doc_array(i).CBS_VBC,
                    v_doc_array(i).CBS_PCBS,
                    v_doc_array(i).CBS_VCBS,
                    v_doc_array(i).DEV_VTRIB,
                    v_doc_array(i).RED_PREDALIQ,
                    v_doc_array(i).RED_PALIQEFET,
                    v_doc_array(i).TRIB_REG_CST,
                    v_doc_array(i).TRIB_REG_CCLASS_TRIB,
                    v_doc_array(i).TRIB_REG_PALIQ_IBSUF,
                    v_doc_array(i).TRIB_REG_VTRIB_IBSUF,
                    v_doc_array(i).TRIB_REG_PALIQ_IBSMUN,
                    v_doc_array(i).TRIB_REG_VTRIB_IBSMUN,
                    v_doc_array(i).TRIB_REG_PALIQ_CBS,
                    v_doc_array(i).TRIB_REG_VTRIB_CBS,
                    v_doc_array(i).COMP_GOV_PALIQ_IBSUF,
                    v_doc_array(i).COMP_GOV_VTRIB_IBSUF,
                    v_doc_array(i).COMP_GOV_PALIQ_IBSMUN,
                    v_doc_array(i).COMP_GOV_VTRIB_IBSMUN,
                    v_doc_array(i).COMP_GOV_PALIQ_CBS,
                    v_doc_array(i).COMP_GOV_VTRIB_CBS,
                    v_doc_array(i).MONO_QBCMONO,
                    v_doc_array(i).MONO_ADREMIBS,
                    v_doc_array(i).MONO_ADREMCBS,
                    v_doc_array(i).MONO_VIBSMONO,
                    v_doc_array(i).MONO_VCBSMONO,
                    v_doc_array(i).MONO_RET_VBC,
                    v_doc_array(i).MONO_RET_QBCMONO,
                    v_doc_array(i).MONO_RET_ADREMIBS,
                    v_doc_array(i).MONO_RET_ADREMCBS,
                    v_doc_array(i).MONO_RET_VIBS,
                    v_doc_array(i).MONO_RET_VCBS,
                    v_doc_array(i).MONO_ANT_VBC,
                    v_doc_array(i).MONO_ANT_QBCMONO,
                    v_doc_array(i).MONO_ANT_ADREMIBS,
                    v_doc_array(i).MONO_ANT_ADREMCBS,
                    v_doc_array(i).MONO_ANT_VIBS,
                    v_doc_array(i).MONO_ANT_VCBS,
                    v_doc_array(i).MONO_DIF_PIBS,
                    v_doc_array(i).MONO_DIF_VIBS,
                    v_doc_array(i).MONO_DIF_PCBS,
                    v_doc_array(i).MONO_DIF_VCBS,
                    v_doc_array(i).TRANSF_VIBS,
                    v_doc_array(i).TRANSF_VCBS,
                    v_doc_array(i).ZFM_PIBS,
                    v_doc_array(i).ZFM_VIBS,
                    v_doc_array(i).ZFM_PCBS,
                    v_doc_array(i).ZFM_VCBS,
                    v_doc_array(i).AJ_COMP_VIBS,
                    v_doc_array(i).AJ_COMP_VCBS,
                    v_doc_array(i).ESTORNO_VIBS,
                    v_doc_array(i).ESTORNO_VCBS
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

END PRC_NFE_REFORMA_TRIBUTARIA;
/
