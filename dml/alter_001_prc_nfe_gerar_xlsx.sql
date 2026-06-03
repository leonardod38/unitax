-- ============================================================
-- Tipo    : ALTER PROCEDURE (script completo de alteracao)
-- Objeto  : PRC_NFE_GERAR_XLSX
-- Schema  : USER_XMLS
-- Arquivo : alter_001_prc_nfe_gerar_xlsx.sql
-- Descricao: Substitui I15_VDESC por I16_VFRETE no bloco CSV
--            (header, SELECT e UTL_FILE.PUT grupo 2).
--            Bloco XLSX nao alterado — usa SELECT * FROM
--            VW_UNIFICADA_RF e absorve a mudanca automaticamente.
-- Execucao : Compilar diretamente no banco Oracle.
--            Apos execucao rodar: EXEC PRC_RECOMPILAR_OBJETOS;
-- ------------------------------------------------------------
-- Historico de alteracoes:
-- 001 - 2026-06-03 - Substituida coluna I15_VDESC por I16_VFRETE
--                    no bloco CSV (header, SELECT e dados)
-- ============================================================

CREATE OR REPLACE PROCEDURE USER_XMLS.PRC_NFE_GERAR_XLSX AS
-- ============================================================
-- Tipo    : PROCEDURE
-- Objeto  : PRC_NFE_GERAR_XLSX
-- Schema  : USER_XMLS
-- Descricao: Exporta VW_UNIFICADA_RF para XLSX formatado
--            (volume < 700k) ou CSV via UTL_FILE (>= 700k).
--            XLSX: AS_XLSX com formatacao profissional,
--            freeze pane, autofilter e coluna STATUS_AUDITORIA.
--            CSV: separador ponto-e-virgula (padrao BR).
-- Fonte   : VW_UNIFICADA_RF
-- Destino : DIR_XMLSDOCS (arquivo .xlsx ou .csv)
-- ------------------------------------------------------------
-- Historico de alteracoes:
-- v1.5.0 - 2026-05-14 - Log de auditoria: usuario Oracle e timestamp de inicio
-- v1.4.0 - 2026-05-14 - Condicional CSV (>= 700k registros) via UTL_FILE
-- v1.3.0 - 2026-05-14 - Formatacao profissional: Calibri, bordas, alinhamento
-- v1.2.0 - 2026-05-13 - Corrigido list_validation
-- v1.1.0 - 2026-05-13 - Constantes para colunas, DBMS_OUTPUT completo
-- v1.0.0 - 2026-05-13 - Versao inicial
-- 001    - 2026-06-03 - Substituida I15_VDESC por I16_VFRETE no bloco CSV
-- ============================================================

   -- Constantes de estrutura
   -- INVARIANTE: c_total_colunas deve refletir exatamente o numero de colunas de VW_UNIFICADA_RF.
   -- Se a view mudar, atualizar este valor e revisar os intervalos de cor no passo 5.
   c_total_colunas   CONSTANT PLS_INTEGER := 143;
   c_col_auditoria   CONSTANT PLS_INTEGER := c_total_colunas + 1;
   c_max_valid_rows  CONSTANT PLS_INTEGER := 10000;
   c_limite_csv      CONSTANT PLS_INTEGER := 700000;

   -- Configuracao do arquivo
   v_dir             VARCHAR2(30)  := 'DIR_XMLSDOCS';
   v_file            VARCHAR2(100) := 'AUDITORIA_CONCILIACAO_FISCAL_RF_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.xlsx';
   v_file_csv        VARCHAR2(100);

   -- Parametrizacao centralizada de fonte
   v_nome_fonte          VARCHAR2(30) := 'Calibri';
   v_tamanho_fonte_dados NUMBER       := 10;
   v_tamanho_fonte_cabec NUMBER       := 11;
   v_largura_padrao      NUMBER       := 20;

   -- Identificadores de fonte
   v_font_dados          PLS_INTEGER;
   v_font_cabec_branca   PLS_INTEGER;
   v_font_cabec_preta    PLS_INTEGER;

   -- Identificadores de cor de fundo
   v_fill_padrao         PLS_INTEGER;
   v_fill_verm_claro     PLS_INTEGER;
   v_fill_verde_esm      PLS_INTEGER;
   v_fill_amar_claro     PLS_INTEGER;
   v_fill_cinza_claro    PLS_INTEGER;

   -- Borda e alinhamento
   v_border_cabec        PLS_INTEGER;
   v_align_cabec         AS_XLSX.tp_alignment;
   v_align_dados         AS_XLSX.tp_alignment;

   -- Controle do laco de cabecalho
   v_fundo_atual         PLS_INTEGER;
   v_fonte_atual         PLS_INTEGER;

   -- Total de linhas e handle para CSV
   v_total_linhas        PLS_INTEGER := 0;
   v_handle              UTL_FILE.FILE_TYPE;
   v_linhas_csv          PLS_INTEGER := 0;

   -- Auditoria de execucao
   v_usuario             VARCHAR2(30) := SYS_CONTEXT('USERENV', 'SESSION_USER');
   v_inicio              TIMESTAMP    := SYSTIMESTAMP;

BEGIN
   DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Iniciando geracao: ' || v_file);
   DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Usuario  : ' || v_usuario);
   DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Inicio   : ' || TO_CHAR(v_inicio, 'DD/MM/YYYY HH24:MI:SS'));

   SELECT COUNT(*) INTO v_total_linhas FROM VW_UNIFICADA_RF;
   DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Registros na view: ' || v_total_linhas);

   -- ==========================================================================
   -- BLOCO CSV: volume >= 700.000 registros
   -- ==========================================================================
   IF v_total_linhas >= c_limite_csv THEN

      v_file_csv := REPLACE(v_file, '.xlsx', '.csv');
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Volume >= ' || c_limite_csv || ' registros. Gerando CSV: ' || v_file_csv);

      v_handle := UTL_FILE.FOPEN(v_dir, v_file_csv, 'W', 32767);

      -- Header
      UTL_FILE.PUT(v_handle,
         'NOME_ARQUIVO;TIPO_DOCUMENTO;CHAVE_ACESSO;NUMERO_NF;NITEM;DATA_EMISSAO;MODELO_NOTA;' ||
         'EMIT_CNPJ;EMIT_CPF;EMIT_NOME;EMIT_FANTASIA;EMIT_LOGRADOURO;EMIT_NRO;' ||
         'EMIT_COMPLEMENTO;EMIT_BAIRRO;EMIT_MUN;EMIT_UF;EMIT_CEP;EMIT_PAIS;EMIT_IE;EMIT_IM;'
      );
      UTL_FILE.PUT(v_handle,
         'DEST_CNPJ;DEST_CPF;DEST_NOME;DEST_LOGRADOURO;DEST_NRO;DEST_COMPLEMENTO;' ||
         'DEST_BAIRRO;DEST_MUN;DEST_UF;DEST_CEP;DEST_PAIS;DEST_IE;DEST_IM;' ||
         'COD_PROD;COD_EAN;DESC_PROD;I05_NCM;I08_CFOP;I08_CFOP_DESC;I09_UCOM;' ||
         'I10_QCOM;I10A_VUNCOM;I11_VPROD;I14_QTRIB;I14A_VUNTRIB;I16_VFRETE;'  -- 001 - ajuste no campo frete
      );
      UTL_FILE.PUT(v_handle,
         'ICMS_ORIG;ICMS_CST;ICMS_CSOSN;ICMS_VBC;ICMS_PICMS;ICMS_VICMS;' ||
         'ICMS_VBCST;ICMS_PICMSST;ICMS_VICMSST;' ||
         'IPI_CENQ;IPI_CST;IPI_VBC;IPI_PIPI;IPI_QUNID;IPI_VUNID;IPI_VIPI;' ||
         'PIS_CST;PIS_VBC;PIS_PPIS;PIS_VPIS;PISST_VBC;PISST_PPIS;PISST_VPIS;' ||
         'COFINS_CST;COFINS_VBC;COFINS_PCOFINS;COFINS_VCOFINS;COFINSST_VBC;COFINSST_PCOFINS;COFINSST_VCOFINS;'
      );
      UTL_FILE.PUT(v_handle,
         'IS_CST;IS_CCLASS_TRIB;IS_VBC;IS_PIS;IS_PIS_ESPEC;IS_UTRIB;IS_QTRIB;IS_VIS;' ||
         'IBSCBS_CST;IBSCBS_CCLASS_TRIB;IBS_VBC;IBS_VIBS;IBS_PIBSUF;IBS_VIBSUF;' ||
         'DEV_VTRIB;RED_PREDALIQ;RED_PALIQEFET;IBS_PIBSMUN;IBS_VIBSMUN;' ||
         'CBS_VBC;CBS_PCBS;CBS_VCBS;'
      );
      UTL_FILE.PUT(v_handle,
         'TRIB_REG_CST;TRIB_REG_CCLASS_TRIB;TRIB_REG_PALIQ_IBSUF;TRIB_REG_VTRIB_IBSUF;' ||
         'TRIB_REG_PALIQ_IBSMUN;TRIB_REG_VTRIB_IBSMUN;TRIB_REG_PALIQ_CBS;TRIB_REG_VTRIB_CBS;' ||
         'COMP_GOV_PALIQ_IBSUF;COMP_GOV_VTRIB_IBSUF;COMP_GOV_PALIQ_IBSMUN;COMP_GOV_VTRIB_IBSMUN;' ||
         'COMP_GOV_PALIQ_CBS;COMP_GOV_VTRIB_CBS;' ||
         'MONO_QBCMONO;MONO_ADREMIBS;MONO_ADREMCBS;MONO_VIBSMONO;MONO_VCBSMONO;' ||
         'MONO_RET_VBC;MONO_RET_QBCMONO;MONO_RET_ADREMIBS;MONO_RET_ADREMCBS;MONO_RET_VIBS;' ||
         'MONO_ANT_VBC;MONO_ANT_QBCMONO;MONO_ANT_ADREMIBS;MONO_ANT_ADREMCBS;MONO_ANT_VIBS;MONO_ANT_VCBS;' ||
         'MONO_DIF_PIBS;MONO_DIF_VIBS;MONO_DIF_PCBS;MONO_DIF_VCBS;' ||
         'TRANSF_VIBS;TRANSF_VCBS;ZFM_PIBS;ZFM_VIBS;ZFM_PCBS;ZFM_VCBS;' ||
         'AJ_COMP_VIBS;AJ_COMP_VCBS;ESTORNO_VIBS;ESTORNO_VCBS'
      );
      UTL_FILE.NEW_LINE(v_handle);

      -- Dados
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Gravando dados no CSV...');

      FOR rec IN (
         SELECT
            NOME_ARQUIVO, TIPO_DOCUMENTO, CHAVE_ACESSO,
            NUMERO_NF, NITEM, DATA_EMISSAO,
            MODELO_NOTA, EMIT_CNPJ, EMIT_CPF,
            EMIT_NOME, EMIT_FANTASIA, EMIT_LOGRADOURO,
            EMIT_NRO, EMIT_COMPLEMENTO, EMIT_BAIRRO,
            EMIT_MUN, EMIT_UF, EMIT_CEP,
            EMIT_PAIS, EMIT_IE, EMIT_IM,
            DEST_CNPJ, DEST_CPF, DEST_NOME,
            DEST_LOGRADOURO, DEST_NRO, DEST_COMPLEMENTO,
            DEST_BAIRRO, DEST_MUN, DEST_UF,
            DEST_CEP, DEST_PAIS, DEST_IE,
            DEST_IM, COD_PROD, COD_EAN,
            DESC_PROD, I05_NCM, I08_CFOP,
            I08_CFOP_DESC, I09_UCOM, I10_QCOM,
            I10A_VUNCOM, I11_VPROD, I14_QTRIB,
            I14A_VUNTRIB, I16_VFRETE, ICMS_ORIG,  -- 001 - ajuste no campo frete
            ICMS_CST, ICMS_CSOSN, ICMS_VBC,
            ICMS_PICMS, ICMS_VICMS, ICMS_VBCST,
            ICMS_PICMSST, ICMS_VICMSST, IPI_CENQ,
            IPI_CST, IPI_VBC, IPI_PIPI,
            IPI_QUNID, IPI_VUNID, IPI_VIPI,
            PIS_CST, PIS_VBC, PIS_PPIS,
            PIS_VPIS, PISST_VBC, PISST_PPIS,
            PISST_VPIS, COFINS_CST, COFINS_VBC,
            COFINS_PCOFINS, COFINS_VCOFINS, COFINSST_VBC,
            COFINSST_PCOFINS, COFINSST_VCOFINS, IS_CST,
            IS_CCLASS_TRIB, IS_VBC, IS_PIS,
            IS_PIS_ESPEC, IS_UTRIB, IS_QTRIB,
            IS_VIS, IBSCBS_CST, IBSCBS_CCLASS_TRIB,
            IBS_VBC, IBS_VIBS, IBS_PIBSUF,
            IBS_VIBSUF, DEV_VTRIB, RED_PREDALIQ,
            RED_PALIQEFET, IBS_PIBSMUN, IBS_VIBSMUN,
            CBS_VBC, CBS_PCBS, CBS_VCBS,
            TRIB_REG_CST, TRIB_REG_CCLASS_TRIB, TRIB_REG_PALIQ_IBSUF,
            TRIB_REG_VTRIB_IBSUF, TRIB_REG_PALIQ_IBSMUN, TRIB_REG_VTRIB_IBSMUN,
            TRIB_REG_PALIQ_CBS, TRIB_REG_VTRIB_CBS, COMP_GOV_PALIQ_IBSUF,
            COMP_GOV_VTRIB_IBSUF, COMP_GOV_PALIQ_IBSMUN, COMP_GOV_VTRIB_IBSMUN,
            COMP_GOV_PALIQ_CBS, COMP_GOV_VTRIB_CBS, MONO_QBCMONO,
            MONO_ADREMIBS, MONO_ADREMCBS, MONO_VIBSMONO,
            MONO_VCBSMONO, MONO_RET_VBC, MONO_RET_QBCMONO,
            MONO_RET_ADREMIBS, MONO_RET_ADREMCBS, MONO_RET_VIBS,
            MONO_ANT_VBC, MONO_ANT_QBCMONO, MONO_ANT_ADREMIBS,
            MONO_ANT_ADREMCBS, MONO_ANT_VIBS, MONO_ANT_VCBS,
            MONO_DIF_PIBS, MONO_DIF_VIBS, MONO_DIF_PCBS,
            MONO_DIF_VCBS, TRANSF_VIBS, TRANSF_VCBS,
            ZFM_PIBS, ZFM_VIBS, ZFM_PCBS,
            ZFM_VCBS, AJ_COMP_VIBS, AJ_COMP_VCBS,
            ESTORNO_VIBS, ESTORNO_VCBS
         FROM VW_UNIFICADA_RF
      ) LOOP

         -- Grupo 1: identificacao e emitente
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.NOME_ARQUIVO),     '') || ';' || NVL(TO_CHAR(rec.TIPO_DOCUMENTO),  '') || ';' ||
            NVL(TO_CHAR(rec.CHAVE_ACESSO),     '') || ';' || NVL(TO_CHAR(rec.NUMERO_NF),        '') || ';' ||
            NVL(TO_CHAR(rec.NITEM),            '') || ';' || NVL(TO_CHAR(rec.DATA_EMISSAO),     '') || ';' ||
            NVL(TO_CHAR(rec.MODELO_NOTA),      '') || ';' || NVL(TO_CHAR(rec.EMIT_CNPJ),        '') || ';' ||
            NVL(TO_CHAR(rec.EMIT_CPF),         '') || ';' || NVL(TO_CHAR(rec.EMIT_NOME),        '') || ';' ||
            NVL(TO_CHAR(rec.EMIT_FANTASIA),    '') || ';' || NVL(TO_CHAR(rec.EMIT_LOGRADOURO),  '') || ';' ||
            NVL(TO_CHAR(rec.EMIT_NRO),         '') || ';' || NVL(TO_CHAR(rec.EMIT_COMPLEMENTO), '') || ';' ||
            NVL(TO_CHAR(rec.EMIT_BAIRRO),      '') || ';' || NVL(TO_CHAR(rec.EMIT_MUN),         '') || ';' ||
            NVL(TO_CHAR(rec.EMIT_UF),          '') || ';' || NVL(TO_CHAR(rec.EMIT_CEP),         '') || ';' ||
            NVL(TO_CHAR(rec.EMIT_PAIS),        '') || ';' || NVL(TO_CHAR(rec.EMIT_IE),          '') || ';' ||
            NVL(TO_CHAR(rec.EMIT_IM),          '') || ';'
         );

         -- Grupo 2: destinatario e produto
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.DEST_CNPJ),        '') || ';' || NVL(TO_CHAR(rec.DEST_CPF),         '') || ';' ||
            NVL(TO_CHAR(rec.DEST_NOME),        '') || ';' || NVL(TO_CHAR(rec.DEST_LOGRADOURO),   '') || ';' ||
            NVL(TO_CHAR(rec.DEST_NRO),         '') || ';' || NVL(TO_CHAR(rec.DEST_COMPLEMENTO),  '') || ';' ||
            NVL(TO_CHAR(rec.DEST_BAIRRO),      '') || ';' || NVL(TO_CHAR(rec.DEST_MUN),          '') || ';' ||
            NVL(TO_CHAR(rec.DEST_UF),          '') || ';' || NVL(TO_CHAR(rec.DEST_CEP),          '') || ';' ||
            NVL(TO_CHAR(rec.DEST_PAIS),        '') || ';' || NVL(TO_CHAR(rec.DEST_IE),           '') || ';' ||
            NVL(TO_CHAR(rec.DEST_IM),          '') || ';' || NVL(TO_CHAR(rec.COD_PROD),          '') || ';' ||
            NVL(TO_CHAR(rec.COD_EAN),          '') || ';' || NVL(TO_CHAR(rec.DESC_PROD),         '') || ';' ||
            NVL(TO_CHAR(rec.I05_NCM),          '') || ';' || NVL(TO_CHAR(rec.I08_CFOP),          '') || ';' ||
            NVL(TO_CHAR(rec.I08_CFOP_DESC),    '') || ';' || NVL(TO_CHAR(rec.I09_UCOM),          '') || ';' ||
            NVL(TO_CHAR(rec.I10_QCOM),         '') || ';' || NVL(TO_CHAR(rec.I10A_VUNCOM),       '') || ';' ||
            NVL(TO_CHAR(rec.I11_VPROD),        '') || ';' || NVL(TO_CHAR(rec.I14_QTRIB),         '') || ';' ||
            NVL(TO_CHAR(rec.I14A_VUNTRIB),     '') || ';' || NVL(TO_CHAR(rec.I16_VFRETE),        '') || ';'  -- 001 - ajuste no campo frete
         );

         -- Grupo 3: ICMS, IPI, PIS, COFINS
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.ICMS_ORIG),        '') || ';' || NVL(TO_CHAR(rec.ICMS_CST),          '') || ';' ||
            NVL(TO_CHAR(rec.ICMS_CSOSN),       '') || ';' || NVL(TO_CHAR(rec.ICMS_VBC),          '') || ';' ||
            NVL(TO_CHAR(rec.ICMS_PICMS),       '') || ';' || NVL(TO_CHAR(rec.ICMS_VICMS),        '') || ';' ||
            NVL(TO_CHAR(rec.ICMS_VBCST),       '') || ';' || NVL(TO_CHAR(rec.ICMS_PICMSST),      '') || ';' ||
            NVL(TO_CHAR(rec.ICMS_VICMSST),     '') || ';' || NVL(TO_CHAR(rec.IPI_CENQ),          '') || ';' ||
            NVL(TO_CHAR(rec.IPI_CST),          '') || ';' || NVL(TO_CHAR(rec.IPI_VBC),           '') || ';' ||
            NVL(TO_CHAR(rec.IPI_PIPI),         '') || ';' || NVL(TO_CHAR(rec.IPI_QUNID),         '') || ';' ||
            NVL(TO_CHAR(rec.IPI_VUNID),        '') || ';' || NVL(TO_CHAR(rec.IPI_VIPI),          '') || ';' ||
            NVL(TO_CHAR(rec.PIS_CST),          '') || ';' || NVL(TO_CHAR(rec.PIS_VBC),           '') || ';' ||
            NVL(TO_CHAR(rec.PIS_PPIS),         '') || ';' || NVL(TO_CHAR(rec.PIS_VPIS),          '') || ';' ||
            NVL(TO_CHAR(rec.PISST_VBC),        '') || ';' || NVL(TO_CHAR(rec.PISST_PPIS),        '') || ';' ||
            NVL(TO_CHAR(rec.PISST_VPIS),       '') || ';' || NVL(TO_CHAR(rec.COFINS_CST),        '') || ';' ||
            NVL(TO_CHAR(rec.COFINS_VBC),       '') || ';' || NVL(TO_CHAR(rec.COFINS_PCOFINS),    '') || ';' ||
            NVL(TO_CHAR(rec.COFINS_VCOFINS),   '') || ';' || NVL(TO_CHAR(rec.COFINSST_VBC),      '') || ';' ||
            NVL(TO_CHAR(rec.COFINSST_PCOFINS), '') || ';' || NVL(TO_CHAR(rec.COFINSST_VCOFINS),  '') || ';'
         );

         -- Grupo 4: IS, IBS, CBS
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.IS_CST),           '') || ';' || NVL(TO_CHAR(rec.IS_CCLASS_TRIB),    '') || ';' ||
            NVL(TO_CHAR(rec.IS_VBC),           '') || ';' || NVL(TO_CHAR(rec.IS_PIS),            '') || ';' ||
            NVL(TO_CHAR(rec.IS_PIS_ESPEC),     '') || ';' || NVL(TO_CHAR(rec.IS_UTRIB),          '') || ';' ||
            NVL(TO_CHAR(rec.IS_QTRIB),         '') || ';' || NVL(TO_CHAR(rec.IS_VIS),            '') || ';' ||
            NVL(TO_CHAR(rec.IBSCBS_CST),       '') || ';' || NVL(TO_CHAR(rec.IBSCBS_CCLASS_TRIB),'') || ';' ||
            NVL(TO_CHAR(rec.IBS_VBC),          '') || ';' || NVL(TO_CHAR(rec.IBS_VIBS),          '') || ';' ||
            NVL(TO_CHAR(rec.IBS_PIBSUF),       '') || ';' || NVL(TO_CHAR(rec.IBS_VIBSUF),        '') || ';' ||
            NVL(TO_CHAR(rec.DEV_VTRIB),        '') || ';' || NVL(TO_CHAR(rec.RED_PREDALIQ),       '') || ';' ||
            NVL(TO_CHAR(rec.RED_PALIQEFET),    '') || ';' || NVL(TO_CHAR(rec.IBS_PIBSMUN),       '') || ';' ||
            NVL(TO_CHAR(rec.IBS_VIBSMUN),      '') || ';' || NVL(TO_CHAR(rec.CBS_VBC),           '') || ';' ||
            NVL(TO_CHAR(rec.CBS_PCBS),         '') || ';' || NVL(TO_CHAR(rec.CBS_VCBS),          '') || ';'
         );

         -- Grupo 5: tributacao reforma, monofasico, transferencias, ajustes
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.TRIB_REG_CST),           '') || ';' || NVL(TO_CHAR(rec.TRIB_REG_CCLASS_TRIB),   '') || ';' ||
            NVL(TO_CHAR(rec.TRIB_REG_PALIQ_IBSUF),   '') || ';' || NVL(TO_CHAR(rec.TRIB_REG_VTRIB_IBSUF),   '') || ';' ||
            NVL(TO_CHAR(rec.TRIB_REG_PALIQ_IBSMUN),  '') || ';' || NVL(TO_CHAR(rec.TRIB_REG_VTRIB_IBSMUN),  '') || ';' ||
            NVL(TO_CHAR(rec.TRIB_REG_PALIQ_CBS),     '') || ';' || NVL(TO_CHAR(rec.TRIB_REG_VTRIB_CBS),     '') || ';' ||
            NVL(TO_CHAR(rec.COMP_GOV_PALIQ_IBSUF),   '') || ';' || NVL(TO_CHAR(rec.COMP_GOV_VTRIB_IBSUF),   '') || ';' ||
            NVL(TO_CHAR(rec.COMP_GOV_PALIQ_IBSMUN),  '') || ';' || NVL(TO_CHAR(rec.COMP_GOV_VTRIB_IBSMUN),  '') || ';' ||
            NVL(TO_CHAR(rec.COMP_GOV_PALIQ_CBS),     '') || ';' || NVL(TO_CHAR(rec.COMP_GOV_VTRIB_CBS),     '') || ';' ||
            NVL(TO_CHAR(rec.MONO_QBCMONO),           '') || ';' || NVL(TO_CHAR(rec.MONO_ADREMIBS),           '') || ';' ||
            NVL(TO_CHAR(rec.MONO_ADREMCBS),          '') || ';' || NVL(TO_CHAR(rec.MONO_VIBSMONO),           '') || ';' ||
            NVL(TO_CHAR(rec.MONO_VCBSMONO),          '') || ';' || NVL(TO_CHAR(rec.MONO_RET_VBC),            '') || ';' ||
            NVL(TO_CHAR(rec.MONO_RET_QBCMONO),       '') || ';' || NVL(TO_CHAR(rec.MONO_RET_ADREMIBS),       '') || ';' ||
            NVL(TO_CHAR(rec.MONO_RET_ADREMCBS),      '') || ';' || NVL(TO_CHAR(rec.MONO_RET_VIBS),           '') || ';' ||
            NVL(TO_CHAR(rec.MONO_ANT_VBC),           '') || ';' || NVL(TO_CHAR(rec.MONO_ANT_QBCMONO),        '') || ';' ||
            NVL(TO_CHAR(rec.MONO_ANT_ADREMIBS),      '') || ';' || NVL(TO_CHAR(rec.MONO_ANT_ADREMCBS),       '') || ';' ||
            NVL(TO_CHAR(rec.MONO_ANT_VIBS),          '') || ';' || NVL(TO_CHAR(rec.MONO_ANT_VCBS),           '') || ';' ||
            NVL(TO_CHAR(rec.MONO_DIF_PIBS),          '') || ';' || NVL(TO_CHAR(rec.MONO_DIF_VIBS),           '') || ';' ||
            NVL(TO_CHAR(rec.MONO_DIF_PCBS),          '') || ';' || NVL(TO_CHAR(rec.MONO_DIF_VCBS),           '') || ';' ||
            NVL(TO_CHAR(rec.TRANSF_VIBS),            '') || ';' || NVL(TO_CHAR(rec.TRANSF_VCBS),             '') || ';' ||
            NVL(TO_CHAR(rec.ZFM_PIBS),               '') || ';' || NVL(TO_CHAR(rec.ZFM_VIBS),               '') || ';' ||
            NVL(TO_CHAR(rec.ZFM_PCBS),               '') || ';' || NVL(TO_CHAR(rec.ZFM_VCBS),               '') || ';' ||
            NVL(TO_CHAR(rec.AJ_COMP_VIBS),           '') || ';' || NVL(TO_CHAR(rec.AJ_COMP_VCBS),           '') || ';' ||
            NVL(TO_CHAR(rec.ESTORNO_VIBS),           '') || ';' || NVL(TO_CHAR(rec.ESTORNO_VCBS),           '')
         );
         UTL_FILE.NEW_LINE(v_handle);

         v_linhas_csv := v_linhas_csv + 1;
      END LOOP;

      UTL_FILE.FCLOSE(v_handle);
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] CSV gerado com sucesso: ' || v_file_csv || ' (' || v_linhas_csv || ' linhas)');

   -- ==========================================================================
   -- BLOCO XLSX: volume < 700.000 registros
   -- Nao alterado — usa SELECT * FROM VW_UNIFICADA_RF (absorve mudancas da view)
   -- ==========================================================================
   ELSE

      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Volume < ' || c_limite_csv || ' registros. Gerando XLSX: ' || v_file);

      as_xlsx.clear_workbook;
      as_xlsx.new_sheet('RF_UNIFICADA');

      -- 1. Fontes
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Configurando fontes, bordas e alinhamentos');

      as_xlsx.set_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_dados);

      v_font_dados        := as_xlsx.get_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_dados, p_rgb => 'FF000000');
      v_font_cabec_branca := as_xlsx.get_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_cabec, p_bold => true, p_rgb => 'FFFFFFFF');
      v_font_cabec_preta  := as_xlsx.get_font(v_nome_fonte, p_fontsize => v_tamanho_fonte_cabec, p_bold => true, p_rgb => 'FF000000');

      -- 2. Paletas de cor
      v_fill_padrao      := as_xlsx.get_fill('solid', 'FF1F497D');
      v_fill_verm_claro  := as_xlsx.get_fill('solid', 'FFFF9999');
      v_fill_verde_esm   := as_xlsx.get_fill('solid', 'FF50C878');
      v_fill_amar_claro  := as_xlsx.get_fill('solid', 'FFFFFF99');
      v_fill_cinza_claro := as_xlsx.get_fill('solid', 'FFD9D9D9');

      -- 3. Borda e alinhamentos
      v_border_cabec := as_xlsx.get_border(p_top => 'thin', p_bottom => 'thin', p_left => 'thin', p_right => 'thin');

      v_align_cabec := as_xlsx.get_alignment(p_vertical => 'center', p_horizontal => 'center', p_wrapText => true);
      v_align_dados := as_xlsx.get_alignment(p_vertical => 'center', p_horizontal => 'left');

      -- 4. Estrutura das colunas
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Configurando estrutura de ' || c_col_auditoria || ' colunas');

      FOR i IN 1..c_col_auditoria LOOP
         as_xlsx.set_column_width(p_col => i, p_width => v_largura_padrao, p_sheet => 1);
         as_xlsx.set_column(p_col => i, p_fontId => v_font_dados, p_alignment => v_align_dados, p_sheet => 1);
      END LOOP;

      as_xlsx.set_row(p_row => 1, p_height => 30, p_sheet => 1);
      as_xlsx.freeze_pane(p_col => 2, p_row => 2, p_sheet => 1);

      -- 5. Dados
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Despejando dados da view');

      as_xlsx.query2sheet(p_sql => 'SELECT * FROM VW_UNIFICADA_RF', p_column_headers => true, p_sheet => 1, p_UseXf => true);

      -- 6. Cabecalho com cores, bordas e alinhamento
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Reescrevendo cabecalho com formatacao profissional');

      FOR rec IN (SELECT column_name, column_id FROM user_tab_columns WHERE table_name = 'VW_UNIFICADA_RF' ORDER BY column_id) LOOP
         CASE
            WHEN rec.column_id BETWEEN 1  AND 7   THEN v_fundo_atual := v_fill_verm_claro;  v_fonte_atual := v_font_cabec_preta;
            WHEN rec.column_id BETWEEN 8  AND 21  THEN v_fundo_atual := v_fill_verde_esm;   v_fonte_atual := v_font_cabec_preta;
            WHEN rec.column_id BETWEEN 22 AND 37  THEN v_fundo_atual := v_fill_amar_claro;  v_fonte_atual := v_font_cabec_preta;
            WHEN rec.column_id BETWEEN 38 AND 143 THEN v_fundo_atual := v_fill_cinza_claro; v_fonte_atual := v_font_cabec_preta;
            ELSE                                        v_fundo_atual := v_fill_padrao;       v_fonte_atual := v_font_cabec_branca;
         END CASE;

         as_xlsx.cell(p_col => rec.column_id, p_row => 1, p_value => rec.column_name,
                      p_fontId => v_fonte_atual, p_fillId => v_fundo_atual,
                      p_borderId => v_border_cabec, p_alignment => v_align_cabec, p_sheet => 1);
      END LOOP;

      -- 7. Coluna customizada STATUS_AUDITORIA
      as_xlsx.cell(p_col => c_col_auditoria, p_row => 1, p_value => 'STATUS_AUDITORIA',
                   p_fontId => v_font_cabec_branca, p_fillId => v_fill_padrao,
                   p_borderId => v_border_cabec, p_alignment => v_align_cabec, p_sheet => 1);

      -- 8. Validacao, comentarios e filtros
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] Aplicando validacoes e filtros');

      IF v_total_linhas > c_max_valid_rows THEN
         DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] AVISO: validacao aplicada ate a linha ' || (c_max_valid_rows + 1) || '.');
      END IF;

      FOR v_row IN 2..LEAST(v_total_linhas + 1, c_max_valid_rows + 1) LOOP
         as_xlsx.list_validation(p_sqref_col => c_col_auditoria, p_sqref_row => v_row,
                                 p_defined_name => '"Validado,Pendente,Ajustar"', p_style => 'stop',
                                 p_title => 'Status', p_prompt => 'Selecione o status',
                                 p_show_error => true, p_error_title => 'Erro',
                                 p_error_txt => 'Opcao invalida', p_sheet => 1);
      END LOOP;

      as_xlsx.comment(p_col => 62, p_row => 1, p_text => 'Base legal: Validar cruzamento com SPED Fiscal.', p_author => 'Auditoria', p_sheet => 1);

      as_xlsx.set_autofilter(p_column_start => 1, p_column_end => c_col_auditoria,
                             p_row_start => 1, p_row_end => v_total_linhas + 1, p_sheet => 1);

      as_xlsx.save(v_dir, v_file);
      as_xlsx.clear_workbook;

      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] XLSX gerado com sucesso: ' || v_file);

   END IF;

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] ERRO: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('[PRC_NFE_GERAR_XLSX] TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      BEGIN
         IF UTL_FILE.IS_OPEN(v_handle) THEN
            UTL_FILE.FCLOSE(v_handle);
         END IF;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
      as_xlsx.clear_workbook;
      RAISE;

END PRC_NFE_GERAR_XLSX;
/

SHOW ERRORS;
