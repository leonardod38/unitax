-- =============================================================================
-- Procedure..: USER_XMLS.PRC_NFE_UNIFICAR_DADOS
-- Resumo.....: Unifica TB_REFORMA_CONSOLIDADA (c) com TB_REFORMA_TRIBUTARIA (t)
--              via LEFT JOIN (CHAVE_ACESSO + NITEM + TIPO_DOCUMENTO) e grava em
--              TB_UNIFICADA_RF (TRUNCATE + BULK COLLECT + FORALL SAVE EXCEPTIONS,
--              log em TB_LOG_NFE_REFORMA).
--
-- Historico:
--   v1.2.0 - 2026-06-15 - Removido o TRUNCATE da TB_UNIFICADA_RF (limpeza passa
--                         a ser externa). Ver comentario no corpo (BEGIN).
--   v1.1.0 - 2026-06-15 - Propaga Z03_INFCPL e ZX02_QRCODE da consolidada para
--                         a TB_UNIFICADA_RF (cursor, INSERT e VALUES).
--   v1.0.0 - 2026-05-19 - Versao inicial.
-- =============================================================================
CREATE OR REPLACE PROCEDURE USER_XMLS.PRC_NFE_UNIFICAR_DADOS AS
    CURSOR c_unificado IS
        SELECT /*+ PARALLEL(8) */
            c.TIPO_DOCUMENTO, c.NOME_ARQUIVO, c.CHAVE_ACESSO, c.NUMERO_NF, c.DATA_EMISSAO_NFE AS DATA_EMISSAO, c.NITEM,

            c.B02_CUF, c.B03_CNF, c.B04_NATOP, c.B06_MOD, c.B07_SERIE, c.B10_DHSAIENT, c.B11_TPNF, c.B11A_IDDEST, c.B12_CMUNFG, c.B21_TPIMP, c.B22_TPEMIS, c.B23_CDV, c.B24_TPAMB, c.B25_FINNFE, c.B25A_INDFINAL, c.B25B_INDPRES, c.B25C_INDINTERMED, c.B26_PROCEMI, c.B27_VERPROC, c.B28_DHCONT, c.B29_XJUST, c.B_CMUNFGIBS,

            c.C02_CNPJ, c.C02A_CPF, c.C03_XNOME, c.C04_XFANT, c.C05_XLGR, c.C05_NRO, c.C05_XCPL, c.C05_XBAIRRO, c.C05_CMUN, c.C05_XMUN, c.C05_UF, c.C05_CEP, c.C05_CPAIS, c.C05_XPAIS, c.C05_FONE, c.C17_IE, c.C18_IEST, c.C19_IM, c.C20_CNAE, c.C21_CRT,
            c.E02_CNPJ, c.E03_CPF, c.E03A_IDESTRANGEIRO, c.E04_XNOME, c.E05_XLGR, c.E05_NRO, c.E05_XCPL, c.E05_XBAIRRO, c.E05_CMUN, c.E05_XMUN, c.E05_UF, c.E05_CEP, c.E05_CPAIS, c.E05_XPAIS, c.E05_FONE, c.E16_INDIEDEST, c.E17_IE, c.E18_ISUF, c.E19_IM, c.E20_EMAIL,

            -- Informacoes Adicionais (Z) e Suplementares (ZX) - vindas da consolidada
            c.Z03_INFCPL, c.ZX02_QRCODE,

            c.I02_CPROD, c.I03_CEAN, c.I04_XPROD, c.I05_NCM, c.I08_CFOP, c.I09_UCOM, c.I10_QCOM, c.I10A_VUNCOM, c.I11_VPROD, c.I12_CEANTRIB, c.I13_UTRIB, c.I14_QTRIB, c.I14A_VUNTRIB, c.I15_VDESC, c.I17B_INDTOT,
            c.ICMS_ORIG, c.ICMS_CST, c.ICMS_CSOSN, c.ICMS_VBC, c.ICMS_PICMS, c.ICMS_VICMS, c.ICMS_VBCST, c.ICMS_PICMSST, c.ICMS_VICMSST,
            c.IPI_CENQ, c.IPI_CNPJPROD, c.IPI_CST, c.IPI_VBC, c.IPI_PIPI, c.IPI_QUNID, c.IPI_VUNID, c.IPI_VIPI,
            c.PIS_CST, c.PIS_VBC, c.PIS_PPIS, c.PIS_QBCPROD, c.PIS_VALIQPROD, c.PIS_VPIS, c.PISST_VBC, c.PISST_PPIS, c.PISST_QBCPROD, c.PISST_VALIQPROD, c.PISST_VPIS,
            c.COFINS_CST, c.COFINS_VBC, c.COFINS_PCOFINS, c.COFINS_QBCPROD, c.COFINS_VALIQPROD, c.COFINS_VCOFINS, c.COFINSST_VBC, c.COFINSST_PCOFINS, c.COFINSST_QBCPROD, c.COFINSST_VALIQPROD, c.COFINSST_VCOFINS,

            t.IS_CST, t.IS_CCLASS_TRIB, t.IS_VBC, t.IS_PIS, t.IS_PIS_ESPEC, t.IS_UTRIB, t.IS_QTRIB, t.IS_VIS,
            t.IBSCBS_CST, t.IBSCBS_CCLASS_TRIB, t.IBS_VBC, t.IBS_VIBS, t.IBS_PIBSUF, t.IBS_VIBSUF, t.DEV_VTRIB,
            t.RED_PREDALIQ, t.RED_PALIQEFET, t.IBS_PIBSMUN, t.IBS_VIBSMUN, t.CBS_VBC, t.CBS_PCBS, t.CBS_VCBS,
            t.TRIB_REG_CST, t.TRIB_REG_CCLASS_TRIB, t.TRIB_REG_PALIQ_IBSUF, t.TRIB_REG_VTRIB_IBSUF, t.TRIB_REG_PALIQ_IBSMUN, t.TRIB_REG_VTRIB_IBSMUN, t.TRIB_REG_PALIQ_CBS, t.TRIB_REG_VTRIB_CBS,
            t.COMP_GOV_PALIQ_IBSUF, t.COMP_GOV_VTRIB_IBSUF, t.COMP_GOV_PALIQ_IBSMUN, t.COMP_GOV_VTRIB_IBSMUN, t.COMP_GOV_PALIQ_CBS, t.COMP_GOV_VTRIB_CBS,
            t.MONO_QBCMONO, t.MONO_ADREMIBS, t.MONO_ADREMCBS, t.MONO_VIBSMONO, t.MONO_VCBSMONO,
            t.MONO_RET_VBC, t.MONO_RET_QBCMONO, t.MONO_RET_ADREMIBS, t.MONO_RET_ADREMCBS, t.MONO_RET_VIBS, t.MONO_RET_VCBS,
            t.MONO_ANT_VBC, t.MONO_ANT_QBCMONO, t.MONO_ANT_ADREMIBS, t.MONO_ANT_ADREMCBS, t.MONO_ANT_VIBS, t.MONO_ANT_VCBS,
            t.MONO_DIF_PIBS, t.MONO_DIF_VIBS, t.MONO_DIF_PCBS, t.MONO_DIF_VCBS,
            t.TRANSF_VIBS, t.TRANSF_VCBS,
            t.ZFM_PIBS, t.ZFM_VIBS, t.ZFM_PCBS, t.ZFM_VCBS,
            t.AJ_COMP_VIBS, t.AJ_COMP_VCBS, t.ESTORNO_VIBS, t.ESTORNO_VCBS

        FROM TB_REFORMA_CONSOLIDADA c
        LEFT JOIN TB_REFORMA_TRIBUTARIA t
               ON c.CHAVE_ACESSO = t.CHAVE_ACESSO
              AND c.NITEM = t.NITEM
              AND c.TIPO_DOCUMENTO = t.TIPO_DOCUMENTO;

    TYPE t_unificado_array IS TABLE OF c_unificado%ROWTYPE;
    v_array t_unificado_array;

    e_bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bulk_errors, -24381);

    PROCEDURE gravar_log(p_chave IN VARCHAR2, p_nitem IN NUMBER, p_cod IN NUMBER, p_msg IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO TB_LOG_NFE_REFORMA (CHAVE_ACESSO, NOME_PROCEDURE, NITEM, CODIGO_ERRO, MENSAGEM_ERRO)
        VALUES (p_chave, 'PRC_NFE_UNIFICAR_DADOS', p_nitem, p_cod, SUBSTR(p_msg, 1, 4000));
        COMMIT;
    END gravar_log;

BEGIN
    -- TRUNCATE removido (v1.2.0): a procedure NAO limpa mais a TB_UNIFICADA_RF.
    -- A limpeza/controle de carga da tabela passa a ser responsabilidade externa
    -- (orquestrador / job). Atencao: sem essa limpeza, execucoes repetidas
    -- acumulam/duplicam linhas na TB_UNIFICADA_RF.
    -- EXECUTE IMMEDIATE 'TRUNCATE TABLE TB_UNIFICADA_RF';

    OPEN c_unificado;
    LOOP
        FETCH c_unificado BULK COLLECT INTO v_array LIMIT 100;
        EXIT WHEN v_array.COUNT = 0;

        BEGIN
            FORALL i IN 1 .. v_array.COUNT SAVE EXCEPTIONS
                INSERT INTO TB_UNIFICADA_RF (
                    TIPO_DOCUMENTO, NOME_ARQUIVO, CHAVE_ACESSO, NUMERO_NF, DATA_EMISSAO, NITEM,

                    B02_CUF, B03_CNF, B04_NATOP, B06_MOD, B07_SERIE, B10_DHSAIENT, B11_TPNF, B11A_IDDEST, B12_CMUNFG, B21_TPIMP, B22_TPEMIS, B23_CDV, B24_TPAMB, B25_FINNFE, B25A_INDFINAL, B25B_INDPRES, B25C_INDINTERMED, B26_PROCEMI, B27_VERPROC, B28_DHCONT, B29_XJUST, B_CMUNFGIBS,

                    C02_CNPJ, C02A_CPF, C03_XNOME, C04_XFANT, C05_XLGR, C05_NRO, C05_XCPL, C05_XBAIRRO, C05_CMUN, C05_XMUN, C05_UF, C05_CEP, C05_CPAIS, C05_XPAIS, C05_FONE, C17_IE, C18_IEST, C19_IM, C20_CNAE, C21_CRT,
                    E02_CNPJ, E03_CPF, E03A_IDESTRANGEIRO, E04_XNOME, E05_XLGR, E05_NRO, E05_XCPL, E05_XBAIRRO, E05_CMUN, E05_XMUN, E05_UF, E05_CEP, E05_CPAIS, E05_XPAIS, E05_FONE, E16_INDIEDEST, E17_IE, E18_ISUF, E19_IM, E20_EMAIL,

                    -- Informacoes Adicionais (Z) e Suplementares (ZX)
                    Z03_INFCPL, ZX02_QRCODE,

                    I02_CPROD, I03_CEAN, I04_XPROD, I05_NCM, I08_CFOP, I09_UCOM, I10_QCOM, I10A_VUNCOM, I11_VPROD, I12_CEANTRIB, I13_UTRIB, I14_QTRIB, I14A_VUNTRIB, I15_VDESC, I17B_INDTOT,
                    ICMS_ORIG, ICMS_CST, ICMS_CSOSN, ICMS_VBC, ICMS_PICMS, ICMS_VICMS, ICMS_VBCST, ICMS_PICMSST, ICMS_VICMSST,
                    IPI_CENQ, IPI_CNPJPROD, IPI_CST, IPI_VBC, IPI_PIPI, IPI_QUNID, IPI_VUNID, IPI_VIPI,
                    PIS_CST, PIS_VBC, PIS_PPIS, PIS_QBCPROD, PIS_VALIQPROD, PIS_VPIS, PISST_VBC, PISST_PPIS, PISST_QBCPROD, PISST_VALIQPROD, PISST_VPIS,
                    COFINS_CST, COFINS_VBC, COFINS_PCOFINS, COFINS_QBCPROD, COFINS_VALIQPROD, COFINS_VCOFINS, COFINSST_VBC, COFINSST_PCOFINS, COFINSST_QBCPROD, COFINSST_VALIQPROD, COFINSST_VCOFINS,

                    IS_CST, IS_CCLASS_TRIB, IS_VBC, IS_PIS, IS_PIS_ESPEC, IS_UTRIB, IS_QTRIB, IS_VIS,
                    IBSCBS_CST, IBSCBS_CCLASS_TRIB, IBS_VBC, IBS_VIBS, IBS_PIBSUF, IBS_VIBSUF, DEV_VTRIB,
                    RED_PREDALIQ, RED_PALIQEFET, IBS_PIBSMUN, IBS_VIBSMUN, CBS_VBC, CBS_PCBS, CBS_VCBS,
                    TRIB_REG_CST, TRIB_REG_CCLASS_TRIB, TRIB_REG_PALIQ_IBSUF, TRIB_REG_VTRIB_IBSUF, TRIB_REG_PALIQ_IBSMUN, TRIB_REG_VTRIB_IBSMUN, TRIB_REG_PALIQ_CBS, TRIB_REG_VTRIB_CBS,
                    COMP_GOV_PALIQ_IBSUF, COMP_GOV_VTRIB_IBSUF, COMP_GOV_PALIQ_IBSMUN, COMP_GOV_VTRIB_IBSMUN, COMP_GOV_PALIQ_CBS, COMP_GOV_VTRIB_CBS,
                    MONO_QBCMONO, MONO_ADREMIBS, MONO_ADREMCBS, MONO_VIBSMONO, MONO_VCBSMONO,
                    MONO_RET_VBC, MONO_RET_QBCMONO, MONO_RET_ADREMIBS, MONO_RET_ADREMCBS, MONO_RET_VIBS, MONO_RET_VCBS,
                    MONO_ANT_VBC, MONO_ANT_QBCMONO, MONO_ANT_ADREMIBS, MONO_ANT_ADREMCBS, MONO_ANT_VIBS, MONO_ANT_VCBS,
                    MONO_DIF_PIBS, MONO_DIF_VIBS, MONO_DIF_PCBS, MONO_DIF_VCBS,
                    TRANSF_VIBS, TRANSF_VCBS,
                    ZFM_PIBS, ZFM_VIBS, ZFM_PCBS, ZFM_VCBS,
                    AJ_COMP_VIBS, AJ_COMP_VCBS, ESTORNO_VIBS, ESTORNO_VCBS
                ) VALUES (
                    v_array(i).TIPO_DOCUMENTO, v_array(i).NOME_ARQUIVO, v_array(i).CHAVE_ACESSO, v_array(i).NUMERO_NF, v_array(i).DATA_EMISSAO, v_array(i).NITEM,

                    v_array(i).B02_CUF, v_array(i).B03_CNF, v_array(i).B04_NATOP, v_array(i).B06_MOD, v_array(i).B07_SERIE, v_array(i).B10_DHSAIENT, v_array(i).B11_TPNF, v_array(i).B11A_IDDEST, v_array(i).B12_CMUNFG, v_array(i).B21_TPIMP, v_array(i).B22_TPEMIS, v_array(i).B23_CDV, v_array(i).B24_TPAMB, v_array(i).B25_FINNFE, v_array(i).B25A_INDFINAL, v_array(i).B25B_INDPRES, v_array(i).B25C_INDINTERMED, v_array(i).B26_PROCEMI, v_array(i).B27_VERPROC, v_array(i).B28_DHCONT, v_array(i).B29_XJUST, v_array(i).B_CMUNFGIBS,

                    v_array(i).C02_CNPJ, v_array(i).C02A_CPF, v_array(i).C03_XNOME, v_array(i).C04_XFANT, v_array(i).C05_XLGR, v_array(i).C05_NRO, v_array(i).C05_XCPL, v_array(i).C05_XBAIRRO, v_array(i).C05_CMUN, v_array(i).C05_XMUN, v_array(i).C05_UF, v_array(i).C05_CEP, v_array(i).C05_CPAIS, v_array(i).C05_XPAIS, v_array(i).C05_FONE, v_array(i).C17_IE, v_array(i).C18_IEST, v_array(i).C19_IM, v_array(i).C20_CNAE, v_array(i).C21_CRT,
                    v_array(i).E02_CNPJ, v_array(i).E03_CPF, v_array(i).E03A_IDESTRANGEIRO, v_array(i).E04_XNOME, v_array(i).E05_XLGR, v_array(i).E05_NRO, v_array(i).E05_XCPL, v_array(i).E05_XBAIRRO, v_array(i).E05_CMUN, v_array(i).E05_XMUN, v_array(i).E05_UF, v_array(i).E05_CEP, v_array(i).E05_CPAIS, v_array(i).E05_XPAIS, v_array(i).E05_FONE, v_array(i).E16_INDIEDEST, v_array(i).E17_IE, v_array(i).E18_ISUF, v_array(i).E19_IM, v_array(i).E20_EMAIL,

                    -- Informacoes Adicionais (Z) e Suplementares (ZX)
                    v_array(i).Z03_INFCPL, v_array(i).ZX02_QRCODE,

                    v_array(i).I02_CPROD, v_array(i).I03_CEAN, v_array(i).I04_XPROD, v_array(i).I05_NCM, v_array(i).I08_CFOP, v_array(i).I09_UCOM, v_array(i).I10_QCOM, v_array(i).I10A_VUNCOM, v_array(i).I11_VPROD, v_array(i).I12_CEANTRIB, v_array(i).I13_UTRIB, v_array(i).I14_QTRIB, v_array(i).I14A_VUNTRIB, v_array(i).I15_VDESC, v_array(i).I17B_INDTOT,
                    v_array(i).ICMS_ORIG, v_array(i).ICMS_CST, v_array(i).ICMS_CSOSN, v_array(i).ICMS_VBC, v_array(i).ICMS_PICMS, v_array(i).ICMS_VICMS, v_array(i).ICMS_VBCST, v_array(i).ICMS_PICMSST, v_array(i).ICMS_VICMSST,
                    v_array(i).IPI_CENQ, v_array(i).IPI_CNPJPROD, v_array(i).IPI_CST, v_array(i).IPI_VBC, v_array(i).IPI_PIPI, v_array(i).IPI_QUNID, v_array(i).IPI_VUNID, v_array(i).IPI_VIPI,
                    v_array(i).PIS_CST, v_array(i).PIS_VBC, v_array(i).PIS_PPIS, v_array(i).PIS_QBCPROD, v_array(i).PIS_VALIQPROD, v_array(i).PIS_VPIS, v_array(i).PISST_VBC, v_array(i).PISST_PPIS, v_array(i).PISST_QBCPROD, v_array(i).PISST_VALIQPROD, v_array(i).PISST_VPIS,
                    v_array(i).COFINS_CST, v_array(i).COFINS_VBC, v_array(i).COFINS_PCOFINS, v_array(i).COFINS_QBCPROD, v_array(i).COFINS_VALIQPROD, v_array(i).COFINS_VCOFINS, v_array(i).COFINSST_VBC, v_array(i).COFINSST_PCOFINS, v_array(i).COFINSST_QBCPROD, v_array(i).COFINSST_VALIQPROD, v_array(i).COFINSST_VCOFINS,

                    v_array(i).IS_CST, v_array(i).IS_CCLASS_TRIB, v_array(i).IS_VBC, v_array(i).IS_PIS, v_array(i).IS_PIS_ESPEC, v_array(i).IS_UTRIB, v_array(i).IS_QTRIB, v_array(i).IS_VIS,
                    v_array(i).IBSCBS_CST, v_array(i).IBSCBS_CCLASS_TRIB, v_array(i).IBS_VBC, v_array(i).IBS_VIBS, v_array(i).IBS_PIBSUF, v_array(i).IBS_VIBSUF, v_array(i).DEV_VTRIB,
                    v_array(i).RED_PREDALIQ, v_array(i).RED_PALIQEFET, v_array(i).IBS_PIBSMUN, v_array(i).IBS_VIBSMUN, v_array(i).CBS_VBC, v_array(i).CBS_PCBS, v_array(i).CBS_VCBS,
                    v_array(i).TRIB_REG_CST, v_array(i).TRIB_REG_CCLASS_TRIB, v_array(i).TRIB_REG_PALIQ_IBSUF, v_array(i).TRIB_REG_VTRIB_IBSUF, v_array(i).TRIB_REG_PALIQ_IBSMUN, v_array(i).TRIB_REG_VTRIB_IBSMUN, v_array(i).TRIB_REG_PALIQ_CBS, v_array(i).TRIB_REG_VTRIB_CBS,
                    v_array(i).COMP_GOV_PALIQ_IBSUF, v_array(i).COMP_GOV_VTRIB_IBSUF, v_array(i).COMP_GOV_PALIQ_IBSMUN, v_array(i).COMP_GOV_VTRIB_IBSMUN, v_array(i).COMP_GOV_PALIQ_CBS, v_array(i).COMP_GOV_VTRIB_CBS,
                    v_array(i).MONO_QBCMONO, v_array(i).MONO_ADREMIBS, v_array(i).MONO_ADREMCBS, v_array(i).MONO_VIBSMONO, v_array(i).MONO_VCBSMONO,
                    v_array(i).MONO_RET_VBC, v_array(i).MONO_RET_QBCMONO, v_array(i).MONO_RET_ADREMIBS, v_array(i).MONO_RET_ADREMCBS, v_array(i).MONO_RET_VIBS, v_array(i).MONO_RET_VCBS,
                    v_array(i).MONO_ANT_VBC, v_array(i).MONO_ANT_QBCMONO, v_array(i).MONO_ANT_ADREMIBS, v_array(i).MONO_ANT_ADREMCBS, v_array(i).MONO_ANT_VIBS, v_array(i).MONO_ANT_VCBS,
                    v_array(i).MONO_DIF_PIBS, v_array(i).MONO_DIF_VIBS, v_array(i).MONO_DIF_PCBS, v_array(i).MONO_DIF_VCBS,
                    v_array(i).TRANSF_VIBS, v_array(i).TRANSF_VCBS,
                    v_array(i).ZFM_PIBS, v_array(i).ZFM_VIBS, v_array(i).ZFM_PCBS, v_array(i).ZFM_VCBS,
                    v_array(i).AJ_COMP_VIBS, v_array(i).AJ_COMP_VCBS, v_array(i).ESTORNO_VIBS, v_array(i).ESTORNO_VCBS
                );
        EXCEPTION
            WHEN e_bulk_errors THEN
                FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT LOOP
                    gravar_log(
                        v_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).CHAVE_ACESSO,
                        v_array(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).NITEM,
                        SQL%BULK_EXCEPTIONS(i).ERROR_CODE,
                        SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE)
                    );
                END LOOP;
        END;
        COMMIT;
    END LOOP;
    CLOSE c_unificado;
END PRC_NFE_UNIFICAR_DADOS;
/

SHOW ERRORS;
