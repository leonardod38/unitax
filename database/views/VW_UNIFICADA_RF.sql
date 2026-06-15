-- =============================================================================
-- View.......: USER_XMLS.VW_UNIFICADA_RF
-- Resumo.....: Visao curada sobre TB_UNIFICADA_RF (renomeia campos para nomes
--              amigaveis, aplica UPPER em alguns e ordena). Consumida por
--              PRC_NFE_GERAR_XLSX. Dependencia: TB_UNIFICADA_RF.
--
-- Historico:
--   v1.1.0 - 2026-06-15 - Adiciona INFO_COMPLEMENTAR (Z03_INFCPL) e
--                         QR_CODE (ZX02_QRCODE) ao final (colunas 144 e 145).
--   v1.0.0 - (baseline)  - Versao inicial (001 - ajuste frete I16_VFRETE).
-- =============================================================================

CREATE OR REPLACE FORCE VIEW VW_UNIFICADA_RF
(
    NOME_ARQUIVO
  , TIPO_DOCUMENTO
  , CHAVE_ACESSO
  , NUMERO_NF
  , NITEM
  , DATA_EMISSAO
  , MODELO_NOTA
  , EMIT_CNPJ
  , EMIT_CPF
  , EMIT_NOME
  , EMIT_FANTASIA
  , EMIT_LOGRADOURO
  , EMIT_NRO
  , EMIT_COMPLEMENTO
  , EMIT_BAIRRO
  , EMIT_MUN
  , EMIT_UF
  , EMIT_CEP
  , EMIT_PAIS
  , EMIT_IE
  , EMIT_IM
  , DEST_CNPJ
  , DEST_CPF
  , DEST_NOME
  , DEST_LOGRADOURO
  , DEST_NRO
  , DEST_COMPLEMENTO
  , DEST_BAIRRO
  , DEST_MUN
  , DEST_UF
  , DEST_CEP
  , DEST_PAIS
  , DEST_IE
  , DEST_IM
  , COD_PROD
  , COD_EAN
  , DESC_PROD
  , I05_NCM
  , I08_CFOP
  , I08_CFOP_DESC
  , I09_UCOM
  , I10_QCOM
  , I10A_VUNCOM
  , I11_VPROD
  , I14_QTRIB
  , I14A_VUNTRIB
  , I16_VFRETE
  , ICMS_ORIG
  , ICMS_CST
  , ICMS_CSOSN
  , ICMS_VBC
  , ICMS_PICMS
  , ICMS_VICMS
  , ICMS_VBCST
  , ICMS_PICMSST
  , ICMS_VICMSST
  , IPI_CENQ
  , IPI_CST
  , IPI_VBC
  , IPI_PIPI
  , IPI_QUNID
  , IPI_VUNID
  , IPI_VIPI
  , PIS_CST
  , PIS_VBC
  , PIS_PPIS
  , PIS_VPIS
  , PISST_VBC
  , PISST_PPIS
  , PISST_VPIS
  , COFINS_CST
  , COFINS_VBC
  , COFINS_PCOFINS
  , COFINS_VCOFINS
  , COFINSST_VBC
  , COFINSST_PCOFINS
  , COFINSST_VCOFINS
  , IS_CST
  , IS_CCLASS_TRIB
  , IS_VBC
  , IS_PIS
  , IS_PIS_ESPEC
  , IS_UTRIB
  , IS_QTRIB
  , IS_VIS
  , IBSCBS_CST
  , IBSCBS_CCLASS_TRIB
  , IBS_VBC
  , IBS_VIBS
  , IBS_PIBSUF
  , IBS_VIBSUF
  , DEV_VTRIB
  , RED_PREDALIQ
  , RED_PALIQEFET
  , IBS_PIBSMUN
  , IBS_VIBSMUN
  , CBS_VBC
  , CBS_PCBS
  , CBS_VCBS
  , TRIB_REG_CST
  , TRIB_REG_CCLASS_TRIB
  , TRIB_REG_PALIQ_IBSUF
  , TRIB_REG_VTRIB_IBSUF
  , TRIB_REG_PALIQ_IBSMUN
  , TRIB_REG_VTRIB_IBSMUN
  , TRIB_REG_PALIQ_CBS
  , TRIB_REG_VTRIB_CBS
  , COMP_GOV_PALIQ_IBSUF
  , COMP_GOV_VTRIB_IBSUF
  , COMP_GOV_PALIQ_IBSMUN
  , COMP_GOV_VTRIB_IBSMUN
  , COMP_GOV_PALIQ_CBS
  , COMP_GOV_VTRIB_CBS
  , MONO_QBCMONO
  , MONO_ADREMIBS
  , MONO_ADREMCBS
  , MONO_VIBSMONO
  , MONO_VCBSMONO
  , MONO_RET_VBC
  , MONO_RET_QBCMONO
  , MONO_RET_ADREMIBS
  , MONO_RET_ADREMCBS
  , MONO_RET_VIBS
  , MONO_ANT_VBC
  , MONO_ANT_QBCMONO
  , MONO_ANT_ADREMIBS
  , MONO_ANT_ADREMCBS
  , MONO_ANT_VIBS
  , MONO_ANT_VCBS
  , MONO_DIF_PIBS
  , MONO_DIF_VIBS
  , MONO_DIF_PCBS
  , MONO_DIF_VCBS
  , TRANSF_VIBS
  , TRANSF_VCBS
  , ZFM_PIBS
  , ZFM_VIBS
  , ZFM_PCBS
  , ZFM_VCBS
  , AJ_COMP_VIBS
  , AJ_COMP_VCBS
  , ESTORNO_VIBS
  , ESTORNO_VCBS
  , INFO_COMPLEMENTAR
  , QR_CODE
)
BEQUEATH DEFINER
AS
      SELECT UPPER (NOME_ARQUIVO)       AS NOME_ARQUIVO
           , UPPER (TIPO_DOCUMENTO)     AS TIPO_DOCUMENTO
           , CHAVE_ACESSO               AS CHAVE_ACESSO
           , NUMERO_NF                  AS NUMERO_NF
           , NITEM                      AS NITEM
           , DATA_EMISSAO               AS DATA_EMISSAO                     --
           , B06_MOD                    AS MODELO_NOTA
           , C02_CNPJ                   AS EMIT_CNPJ
           , C02A_CPF                   AS EMIT_CPF
           , C03_XNOME                  AS EMIT_NOME
           , C04_XFANT                  AS EMIT_FANTASIA
           , C05_XLGR                   AS EMIT_LOGRADOURO
           , C05_NRO                    AS EMIT_NRO
           , C05_XCPL                   AS EMIT_COMPLEMENTO
           , C05_XBAIRRO                AS EMIT_BAIRRO
           , C05_XMUN                   AS EMIT_MUN
           , C05_UF                     AS EMIT_UF
           , C05_CEP                    AS EMIT_CEP
           , C05_XPAIS                  AS EMIT_PAIS
           , C17_IE                     AS EMIT_IE
           , C19_IM                     AS EMIT_IM
           , E02_CNPJ                   AS DEST_CNPJ
           , E03_CPF                    AS DEST_CPF
           , E04_XNOME                  AS DEST_NOME
           , E05_XLGR                   AS DEST_LOGRADOURO
           , E05_NRO                    AS DEST_NRO
           , E05_XCPL                   AS DEST_COMPLEMENTO
           , E05_XBAIRRO                AS DEST_BAIRRO
           , E05_XMUN                   AS DEST_MUN
           , E05_UF                     AS DEST_UF
           , E05_CEP                    AS DEST_CEP
           , E05_XPAIS                  AS DEST_PAIS
           , E17_IE                     AS DEST_IE
           , E19_IM                     AS DEST_IM
           , I02_CPROD                  AS COD_PROD
           , I03_CEAN                   AS COD_EAN
           , I04_XPROD                  AS DESC_PROD
           , I05_NCM
           , I08_CFOP
           , I08_CFOP_DESC
           , I09_UCOM
           , I10_QCOM
           , I10A_VUNCOM
           , I11_VPROD
           , I14_QTRIB
           , I14A_VUNTRIB
           -- 001 - ajuste no campo frete (substituiu I15_VDESC)
           , I16_VFRETE
           , ICMS_ORIG
           , ICMS_CST
           , ICMS_CSOSN
           , ICMS_VBC
           , ICMS_PICMS
           , ICMS_VICMS
           , ICMS_VBCST
           , ICMS_PICMSST
           , ICMS_VICMSST
           , IPI_CENQ
           , IPI_CST
           , IPI_VBC
           , IPI_PIPI
           , IPI_QUNID
           , IPI_VUNID
           , IPI_VIPI
           , PIS_CST
           , PIS_VBC
           , PIS_PPIS
           , PIS_VPIS
           , PISST_VBC
           , PISST_PPIS
           , PISST_VPIS
           , COFINS_CST
           , COFINS_VBC
           , COFINS_PCOFINS
           , COFINS_VCOFINS
           , COFINSST_VBC
           , COFINSST_PCOFINS
           , COFINSST_VCOFINS
           , IS_CST
           , IS_CCLASS_TRIB
           , IS_VBC
           , IS_PIS
           , IS_PIS_ESPEC
           , IS_UTRIB
           , IS_QTRIB
           , IS_VIS
           , IBSCBS_CST
           , IBSCBS_CCLASS_TRIB
           , IBS_VBC
           , IBS_VIBS
           , IBS_PIBSUF
           , IBS_VIBSUF
           , DEV_VTRIB
           , RED_PREDALIQ
           , RED_PALIQEFET
           , IBS_PIBSMUN
           , IBS_VIBSMUN
           , CBS_VBC
           , CBS_PCBS
           , CBS_VCBS
           , TRIB_REG_CST
           , TRIB_REG_CCLASS_TRIB
           , TRIB_REG_PALIQ_IBSUF
           , TRIB_REG_VTRIB_IBSUF
           , TRIB_REG_PALIQ_IBSMUN
           , TRIB_REG_VTRIB_IBSMUN
           , TRIB_REG_PALIQ_CBS
           , TRIB_REG_VTRIB_CBS
           , COMP_GOV_PALIQ_IBSUF
           , COMP_GOV_VTRIB_IBSUF
           , COMP_GOV_PALIQ_IBSMUN
           , COMP_GOV_VTRIB_IBSMUN
           , COMP_GOV_PALIQ_CBS
           , COMP_GOV_VTRIB_CBS
           , MONO_QBCMONO
           , MONO_ADREMIBS
           , MONO_ADREMCBS
           , MONO_VIBSMONO
           , MONO_VCBSMONO
           , MONO_RET_VBC
           , MONO_RET_QBCMONO
           , MONO_RET_ADREMIBS
           , MONO_RET_ADREMCBS
           , MONO_RET_VIBS
           , MONO_ANT_VBC
           , MONO_ANT_QBCMONO
           , MONO_ANT_ADREMIBS
           , MONO_ANT_ADREMCBS
           , MONO_ANT_VIBS
           , MONO_ANT_VCBS
           , MONO_DIF_PIBS
           , MONO_DIF_VIBS
           , MONO_DIF_PCBS
           , MONO_DIF_VCBS
           , TRANSF_VIBS
           , TRANSF_VCBS
           , ZFM_PIBS
           , ZFM_VIBS
           , ZFM_PCBS
           , ZFM_VCBS
           , AJ_COMP_VIBS
           , AJ_COMP_VCBS
           , ESTORNO_VIBS
           , ESTORNO_VCBS
           , Z03_INFCPL                 AS INFO_COMPLEMENTAR
           , ZX02_QRCODE                AS QR_CODE
        FROM TB_UNIFICADA_RF
    ORDER BY 1
           , 2
           , 3
           , 4
/

SHOW ERRORS;
