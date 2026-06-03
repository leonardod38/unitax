-- Tipo   : BLOCO ANONIMO
-- Objeto : blk_test_prc_nfe_csv
-- Salvo  : 2026-05-14
-- Origem : Teste do bloco CSV da PRC_NFE_GERAR_XLSX (v1.5.0)
-- Objetivo: Simular volume >= 700.000 registros e validar geração do CSV
-- Alteração: adicionado log de usuário Oracle, timestamp e duração do teste
-- ------------------------------------------------------------

-- ============================================================
-- PRE-REQUISITO: habilitar saída DBMS_OUTPUT antes de executar
-- SET SERVEROUTPUT ON SIZE UNLIMITED;
-- ============================================================

DECLARE
   -- Espelha as constantes da procedure para validação isolada
   c_limite_csv     CONSTANT PLS_INTEGER := 700000;
   c_dir            CONSTANT VARCHAR2(30) := 'DIR_XMLSDOCS';

   v_total_linhas   PLS_INTEGER := 0;
   v_file_csv       VARCHAR2(100);
   v_handle         UTL_FILE.FILE_TYPE;
   v_linhas_csv     PLS_INTEGER := 0;
   v_existe_dir     BOOLEAN := FALSE;

   -- Auditoria do teste
   v_usuario        VARCHAR2(30)  := SYS_CONTEXT('USERENV', 'SESSION_USER');
   v_inicio         TIMESTAMP     := SYSTIMESTAMP;
   v_fim            TIMESTAMP;
   v_duracao_seg    NUMBER;

BEGIN
   DBMS_OUTPUT.PUT_LINE('==============================================');
   DBMS_OUTPUT.PUT_LINE('[TESTE CSV] Iniciando validação do bloco CSV');
   DBMS_OUTPUT.PUT_LINE('[TESTE CSV] Usuário : ' || v_usuario);
   DBMS_OUTPUT.PUT_LINE('[TESTE CSV] Início  : ' || TO_CHAR(v_inicio, 'DD/MM/YYYY HH24:MI:SS'));
   DBMS_OUTPUT.PUT_LINE('==============================================');

   -- ------------------------------------------------------------
   -- TESTE 1: Verificar se o diretório Oracle existe e está acessível
   -- ------------------------------------------------------------
   DBMS_OUTPUT.PUT_LINE('[TESTE 1] Verificando diretório: ' || c_dir);
   BEGIN
      SELECT COUNT(*) INTO v_total_linhas
      FROM   all_directories
      WHERE  directory_name = c_dir;

      IF v_total_linhas > 0 THEN
         DBMS_OUTPUT.PUT_LINE('[TESTE 1] OK - Diretório encontrado: ' || c_dir);
         v_existe_dir := TRUE;
      ELSE
         DBMS_OUTPUT.PUT_LINE('[TESTE 1] FALHOU - Diretório não encontrado: ' || c_dir);
         DBMS_OUTPUT.PUT_LINE('[TESTE 1] Crie com: CREATE OR REPLACE DIRECTORY ' || c_dir || ' AS ''/caminho/no/servidor'';');
      END IF;
      v_total_linhas := 0;
   END;

   -- ------------------------------------------------------------
   -- TESTE 2: Contar registros da view e verificar se rota CSV seria ativada
   -- ------------------------------------------------------------
   DBMS_OUTPUT.PUT_LINE('[TESTE 2] Contando registros em VW_UNIFICADA_RF...');
   SELECT COUNT(*) INTO v_total_linhas FROM VW_UNIFICADA_RF;
   DBMS_OUTPUT.PUT_LINE('[TESTE 2] Registros encontrados: ' || v_total_linhas);

   IF v_total_linhas >= c_limite_csv THEN
      DBMS_OUTPUT.PUT_LINE('[TESTE 2] OK - Volume >= ' || c_limite_csv || '. Rota CSV seria ativada.');
   ELSE
      DBMS_OUTPUT.PUT_LINE('[TESTE 2] AVISO - Volume atual (' || v_total_linhas || ') < ' || c_limite_csv || '.');
      DBMS_OUTPUT.PUT_LINE('[TESTE 2] Forçando execução do bloco CSV com volume real para validar a lógica...');
   END IF;

   -- ------------------------------------------------------------
   -- TESTE 3: Geração real do CSV (executa independente do volume)
   -- Valida: abertura do arquivo, header, dados e fechamento
   -- ------------------------------------------------------------
   IF NOT v_existe_dir THEN
      DBMS_OUTPUT.PUT_LINE('[TESTE 3] PULADO - Diretório ' || c_dir || ' indisponível.');
   ELSE
      DBMS_OUTPUT.PUT_LINE('[TESTE 3] Iniciando geração do CSV de teste...');

      v_file_csv := 'TESTE_CSV_PRC_NFE_' || TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') || '.csv';
      v_handle   := UTL_FILE.FOPEN(c_dir, v_file_csv, 'W', 32767);

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
         'I10_QCOM;I10A_VUNCOM;I11_VPROD;I14_QTRIB;I14A_VUNTRIB;I15_VDESC;'
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
      DBMS_OUTPUT.PUT_LINE('[TESTE 3] Header gravado com sucesso.');

      -- Dados: limita a 100 linhas para teste rápido e seguro
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
            I14A_VUNTRIB, I15_VDESC, ICMS_ORIG,
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
         WHERE ROWNUM <= 100  -- limite de segurança para teste
      ) LOOP
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.NOME_ARQUIVO),'')     || ';' || NVL(TO_CHAR(rec.TIPO_DOCUMENTO),'')  || ';' ||
            NVL(TO_CHAR(rec.CHAVE_ACESSO),'')     || ';' || NVL(TO_CHAR(rec.NUMERO_NF),'')        || ';' ||
            NVL(TO_CHAR(rec.NITEM),'')            || ';' || NVL(TO_CHAR(rec.DATA_EMISSAO),'')     || ';' ||
            NVL(TO_CHAR(rec.MODELO_NOTA),'')      || ';' || NVL(TO_CHAR(rec.EMIT_CNPJ),'')        || ';' ||
            NVL(TO_CHAR(rec.EMIT_CPF),'')         || ';' || NVL(TO_CHAR(rec.EMIT_NOME),'')        || ';' ||
            NVL(TO_CHAR(rec.EMIT_FANTASIA),'')    || ';' || NVL(TO_CHAR(rec.EMIT_LOGRADOURO),'')  || ';' ||
            NVL(TO_CHAR(rec.EMIT_NRO),'')         || ';' || NVL(TO_CHAR(rec.EMIT_COMPLEMENTO),'') || ';' ||
            NVL(TO_CHAR(rec.EMIT_BAIRRO),'')      || ';' || NVL(TO_CHAR(rec.EMIT_MUN),'')         || ';' ||
            NVL(TO_CHAR(rec.EMIT_UF),'')          || ';' || NVL(TO_CHAR(rec.EMIT_CEP),'')         || ';' ||
            NVL(TO_CHAR(rec.EMIT_PAIS),'')        || ';' || NVL(TO_CHAR(rec.EMIT_IE),'')          || ';' ||
            NVL(TO_CHAR(rec.EMIT_IM),'')          || ';'
         );
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.DEST_CNPJ),'')        || ';' || NVL(TO_CHAR(rec.DEST_CPF),'')         || ';' ||
            NVL(TO_CHAR(rec.DEST_NOME),'')        || ';' || NVL(TO_CHAR(rec.DEST_LOGRADOURO),'')   || ';' ||
            NVL(TO_CHAR(rec.DEST_NRO),'')         || ';' || NVL(TO_CHAR(rec.DEST_COMPLEMENTO),'')  || ';' ||
            NVL(TO_CHAR(rec.DEST_BAIRRO),'')      || ';' || NVL(TO_CHAR(rec.DEST_MUN),'')          || ';' ||
            NVL(TO_CHAR(rec.DEST_UF),'')          || ';' || NVL(TO_CHAR(rec.DEST_CEP),'')          || ';' ||
            NVL(TO_CHAR(rec.DEST_PAIS),'')        || ';' || NVL(TO_CHAR(rec.DEST_IE),'')           || ';' ||
            NVL(TO_CHAR(rec.DEST_IM),'')          || ';' || NVL(TO_CHAR(rec.COD_PROD),'')          || ';' ||
            NVL(TO_CHAR(rec.COD_EAN),'')          || ';' || NVL(TO_CHAR(rec.DESC_PROD),'')         || ';' ||
            NVL(TO_CHAR(rec.I05_NCM),'')          || ';' || NVL(TO_CHAR(rec.I08_CFOP),'')          || ';' ||
            NVL(TO_CHAR(rec.I08_CFOP_DESC),'')    || ';' || NVL(TO_CHAR(rec.I09_UCOM),'')          || ';' ||
            NVL(TO_CHAR(rec.I10_QCOM),'')         || ';' || NVL(TO_CHAR(rec.I10A_VUNCOM),'')       || ';' ||
            NVL(TO_CHAR(rec.I11_VPROD),'')        || ';' || NVL(TO_CHAR(rec.I14_QTRIB),'')         || ';' ||
            NVL(TO_CHAR(rec.I14A_VUNTRIB),'')     || ';' || NVL(TO_CHAR(rec.I15_VDESC),'')         || ';'
         );
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.ICMS_ORIG),'')        || ';' || NVL(TO_CHAR(rec.ICMS_CST),'')          || ';' ||
            NVL(TO_CHAR(rec.ICMS_CSOSN),'')       || ';' || NVL(TO_CHAR(rec.ICMS_VBC),'')          || ';' ||
            NVL(TO_CHAR(rec.ICMS_PICMS),'')       || ';' || NVL(TO_CHAR(rec.ICMS_VICMS),'')        || ';' ||
            NVL(TO_CHAR(rec.ICMS_VBCST),'')       || ';' || NVL(TO_CHAR(rec.ICMS_PICMSST),'')      || ';' ||
            NVL(TO_CHAR(rec.ICMS_VICMSST),'')     || ';' || NVL(TO_CHAR(rec.IPI_CENQ),'')          || ';' ||
            NVL(TO_CHAR(rec.IPI_CST),'')          || ';' || NVL(TO_CHAR(rec.IPI_VBC),'')           || ';' ||
            NVL(TO_CHAR(rec.IPI_PIPI),'')         || ';' || NVL(TO_CHAR(rec.IPI_QUNID),'')         || ';' ||
            NVL(TO_CHAR(rec.IPI_VUNID),'')        || ';' || NVL(TO_CHAR(rec.IPI_VIPI),'')          || ';' ||
            NVL(TO_CHAR(rec.PIS_CST),'')          || ';' || NVL(TO_CHAR(rec.PIS_VBC),'')           || ';' ||
            NVL(TO_CHAR(rec.PIS_PPIS),'')         || ';' || NVL(TO_CHAR(rec.PIS_VPIS),'')          || ';' ||
            NVL(TO_CHAR(rec.PISST_VBC),'')        || ';' || NVL(TO_CHAR(rec.PISST_PPIS),'')        || ';' ||
            NVL(TO_CHAR(rec.PISST_VPIS),'')       || ';' || NVL(TO_CHAR(rec.COFINS_CST),'')        || ';' ||
            NVL(TO_CHAR(rec.COFINS_VBC),'')       || ';' || NVL(TO_CHAR(rec.COFINS_PCOFINS),'')    || ';' ||
            NVL(TO_CHAR(rec.COFINS_VCOFINS),'')   || ';' || NVL(TO_CHAR(rec.COFINSST_VBC),'')      || ';' ||
            NVL(TO_CHAR(rec.COFINSST_PCOFINS),'') || ';' || NVL(TO_CHAR(rec.COFINSST_VCOFINS),'')  || ';'
         );
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.IS_CST),'')              || ';' || NVL(TO_CHAR(rec.IS_CCLASS_TRIB),'')    || ';' ||
            NVL(TO_CHAR(rec.IS_VBC),'')              || ';' || NVL(TO_CHAR(rec.IS_PIS),'')            || ';' ||
            NVL(TO_CHAR(rec.IS_PIS_ESPEC),'')        || ';' || NVL(TO_CHAR(rec.IS_UTRIB),'')          || ';' ||
            NVL(TO_CHAR(rec.IS_QTRIB),'')            || ';' || NVL(TO_CHAR(rec.IS_VIS),'')            || ';' ||
            NVL(TO_CHAR(rec.IBSCBS_CST),'')          || ';' || NVL(TO_CHAR(rec.IBSCBS_CCLASS_TRIB),'')|| ';' ||
            NVL(TO_CHAR(rec.IBS_VBC),'')             || ';' || NVL(TO_CHAR(rec.IBS_VIBS),'')          || ';' ||
            NVL(TO_CHAR(rec.IBS_PIBSUF),'')          || ';' || NVL(TO_CHAR(rec.IBS_VIBSUF),'')        || ';' ||
            NVL(TO_CHAR(rec.DEV_VTRIB),'')           || ';' || NVL(TO_CHAR(rec.RED_PREDALIQ),'')       || ';' ||
            NVL(TO_CHAR(rec.RED_PALIQEFET),'')       || ';' || NVL(TO_CHAR(rec.IBS_PIBSMUN),'')       || ';' ||
            NVL(TO_CHAR(rec.IBS_VIBSMUN),'')         || ';' || NVL(TO_CHAR(rec.CBS_VBC),'')           || ';' ||
            NVL(TO_CHAR(rec.CBS_PCBS),'')            || ';' || NVL(TO_CHAR(rec.CBS_VCBS),'')          || ';'
         );
         UTL_FILE.PUT(v_handle,
            NVL(TO_CHAR(rec.TRIB_REG_CST),'')           || ';' || NVL(TO_CHAR(rec.TRIB_REG_CCLASS_TRIB),'')   || ';' ||
            NVL(TO_CHAR(rec.TRIB_REG_PALIQ_IBSUF),'')   || ';' || NVL(TO_CHAR(rec.TRIB_REG_VTRIB_IBSUF),'')   || ';' ||
            NVL(TO_CHAR(rec.TRIB_REG_PALIQ_IBSMUN),'')  || ';' || NVL(TO_CHAR(rec.TRIB_REG_VTRIB_IBSMUN),'')  || ';' ||
            NVL(TO_CHAR(rec.TRIB_REG_PALIQ_CBS),'')     || ';' || NVL(TO_CHAR(rec.TRIB_REG_VTRIB_CBS),'')     || ';' ||
            NVL(TO_CHAR(rec.COMP_GOV_PALIQ_IBSUF),'')   || ';' || NVL(TO_CHAR(rec.COMP_GOV_VTRIB_IBSUF),'')   || ';' ||
            NVL(TO_CHAR(rec.COMP_GOV_PALIQ_IBSMUN),'')  || ';' || NVL(TO_CHAR(rec.COMP_GOV_VTRIB_IBSMUN),'')  || ';' ||
            NVL(TO_CHAR(rec.COMP_GOV_PALIQ_CBS),'')     || ';' || NVL(TO_CHAR(rec.COMP_GOV_VTRIB_CBS),'')     || ';' ||
            NVL(TO_CHAR(rec.MONO_QBCMONO),'')           || ';' || NVL(TO_CHAR(rec.MONO_ADREMIBS),'')           || ';' ||
            NVL(TO_CHAR(rec.MONO_ADREMCBS),'')          || ';' || NVL(TO_CHAR(rec.MONO_VIBSMONO),'')           || ';' ||
            NVL(TO_CHAR(rec.MONO_VCBSMONO),'')          || ';' || NVL(TO_CHAR(rec.MONO_RET_VBC),'')            || ';' ||
            NVL(TO_CHAR(rec.MONO_RET_QBCMONO),'')       || ';' || NVL(TO_CHAR(rec.MONO_RET_ADREMIBS),'')       || ';' ||
            NVL(TO_CHAR(rec.MONO_RET_ADREMCBS),'')      || ';' || NVL(TO_CHAR(rec.MONO_RET_VIBS),'')           || ';' ||
            NVL(TO_CHAR(rec.MONO_ANT_VBC),'')           || ';' || NVL(TO_CHAR(rec.MONO_ANT_QBCMONO),'')        || ';' ||
            NVL(TO_CHAR(rec.MONO_ANT_ADREMIBS),'')      || ';' || NVL(TO_CHAR(rec.MONO_ANT_ADREMCBS),'')       || ';' ||
            NVL(TO_CHAR(rec.MONO_ANT_VIBS),'')          || ';' || NVL(TO_CHAR(rec.MONO_ANT_VCBS),'')           || ';' ||
            NVL(TO_CHAR(rec.MONO_DIF_PIBS),'')          || ';' || NVL(TO_CHAR(rec.MONO_DIF_VIBS),'')           || ';' ||
            NVL(TO_CHAR(rec.MONO_DIF_PCBS),'')          || ';' || NVL(TO_CHAR(rec.MONO_DIF_VCBS),'')           || ';' ||
            NVL(TO_CHAR(rec.TRANSF_VIBS),'')            || ';' || NVL(TO_CHAR(rec.TRANSF_VCBS),'')             || ';' ||
            NVL(TO_CHAR(rec.ZFM_PIBS),'')               || ';' || NVL(TO_CHAR(rec.ZFM_VIBS),'')               || ';' ||
            NVL(TO_CHAR(rec.ZFM_PCBS),'')               || ';' || NVL(TO_CHAR(rec.ZFM_VCBS),'')               || ';' ||
            NVL(TO_CHAR(rec.AJ_COMP_VIBS),'')           || ';' || NVL(TO_CHAR(rec.AJ_COMP_VCBS),'')           || ';' ||
            NVL(TO_CHAR(rec.ESTORNO_VIBS),'')           || ';' || NVL(TO_CHAR(rec.ESTORNO_VCBS),'')
         );
         UTL_FILE.NEW_LINE(v_handle);
         v_linhas_csv := v_linhas_csv + 1;
      END LOOP;

      UTL_FILE.FCLOSE(v_handle);

      DBMS_OUTPUT.PUT_LINE('[TESTE 3] OK - CSV gravado: ' || v_file_csv);
      DBMS_OUTPUT.PUT_LINE('[TESTE 3] Linhas de dados gravadas: ' || v_linhas_csv);

   END IF;

   -- ------------------------------------------------------------
   -- TESTE 4: Verificar se o arquivo foi criado no diretório
   -- ------------------------------------------------------------
   IF v_existe_dir AND v_linhas_csv > 0 THEN
      DBMS_OUTPUT.PUT_LINE('[TESTE 4] Verificar manualmente no servidor se o arquivo existe em: ' || c_dir);
      DBMS_OUTPUT.PUT_LINE('[TESTE 4] Nome esperado: TESTE_CSV_PRC_NFE_<YYYYMMDD_HH24MISS>.csv');
      DBMS_OUTPUT.PUT_LINE('[TESTE 4] Linhas esperadas: 1 header + ' || v_linhas_csv || ' dados');
   END IF;

   -- Duração total do teste
   v_fim          := SYSTIMESTAMP;
   v_duracao_seg  := ROUND(EXTRACT(SECOND FROM (v_fim - v_inicio)), 2);

   DBMS_OUTPUT.PUT_LINE('==============================================');
   DBMS_OUTPUT.PUT_LINE('[TESTE CSV] Concluído.');
   DBMS_OUTPUT.PUT_LINE('[TESTE CSV] Término  : ' || TO_CHAR(v_fim, 'DD/MM/YYYY HH24:MI:SS'));
   DBMS_OUTPUT.PUT_LINE('[TESTE CSV] Duração  : ' || v_duracao_seg || ' segundos');
   DBMS_OUTPUT.PUT_LINE('==============================================');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[TESTE CSV] ERRO: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('[TESTE CSV] TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      BEGIN
         IF UTL_FILE.IS_OPEN(v_handle) THEN
            UTL_FILE.FCLOSE(v_handle);
         END IF;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
      RAISE;
END;
/
