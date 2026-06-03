-- Tipo   : BLOCO ANONIMO
-- Objeto : blk_orbita_analise
-- Salvo  : 2026-05-14
-- Origem : Análise de dados ORBITA com cursor estruturado
-- Objetivo: Processar registros de DADOS_ORBITA filtrando por data,
--           hora e scores de modelos ML (DNA10 / DNA2)
-- ------------------------------------------------------------
-- SET SERVEROUTPUT ON SIZE UNLIMITED;
-- ------------------------------------------------------------

DECLARE

   -- -------------------------------------------------------
   -- Datas e horários de filtro (parametrizar aqui)
   -- -------------------------------------------------------
   v_data_ref       DATE          := TRUNC(SYSDATE - 1);   -- ontem
   v_ts_inicio      TIMESTAMP     := v_data_ref + 18/24;   -- 18:00
   v_ts_fim         TIMESTAMP     := v_data_ref + 19/24;   -- 19:00 (exclusive)

   -- -------------------------------------------------------
   -- Contadores e controle
   -- -------------------------------------------------------
   v_total_lidos    PLS_INTEGER   := 0;
   v_total_proc     PLS_INTEGER   := 0;
   v_total_skip     PLS_INTEGER   := 0;
   v_inicio         TIMESTAMP     := SYSTIMESTAMP;
   v_usuario        VARCHAR2(30)  := SYS_CONTEXT('USERENV', 'SESSION_USER');

   -- -------------------------------------------------------
   -- Cursor principal com CTE — view consultada uma única vez
   -- -------------------------------------------------------
   CURSOR c_orbita IS
      WITH DNA10 AS (
         SELECT MIN_SCORE_ISOLATION_FOREST, MAX_SCORE_ISOLATION_FOREST
              , MIN_PROB_CATBOOST,           MAX_PROB_CATBOOST
              , MIN_PROB_LIGHTGBM,           MAX_PROB_LIGHTGBM
              , MIN_PROB_XGBOOST,            MAX_PROB_XGBOOST
         FROM VW_DNA10
      ),
      DNA2 AS (
         SELECT MIN_SCORE_ISOLATION_FOREST, MAX_SCORE_ISOLATION_FOREST
              , MIN_PROB_CATBOOST,           MAX_PROB_CATBOOST
              , MIN_PROB_LIGHTGBM,           MAX_PROB_LIGHTGBM
              , MIN_PROB_XGBOOST,            MAX_PROB_XGBOOST
         FROM VW_DNA2
      )
      SELECT DD.ID_DADOS_ORBITA
           , TRUNC(DD.TIMESTAMP_EXECUCAO_INS)   DATA_EXECUCAO
           , DD.CORRIDA
           , DD.PREMIO
           , DD.MILHAR
           , DD.TXT                             CONTEUDO_TXT
           , DD.TIMESTAMP_EXECUCAO_INS
           , DD.BICHO
        FROM DADOS_ORBITA               DD
        JOIN TB_METAMODELO_DNA10_BACKUP DN10 ON DN10.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
        JOIN TB_METAMODELO_DNA2         DN2  ON DN2.ID_DADOS_ORBITA  = DD.ID_DADOS_ORBITA
        JOIN ORBITA_MILHARES_FILTRADAS  F    ON F.ID_DADOS_ORBITA    = DD.ID_DADOS_ORBITA
        CROSS JOIN DNA10
        CROSS JOIN DNA2
       WHERE DD.TIMESTAMP_EXECUCAO_INS  >= v_ts_inicio
         AND DD.TIMESTAMP_EXECUCAO_INS  <  v_ts_fim
         AND NOT EXISTS (
                SELECT 1
                  FROM TB_CALCULADORES_FUNIL FN
                 WHERE FN.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
             )
         AND DN10.SCORE_ISOLATION_FOREST BETWEEN DNA10.MIN_SCORE_ISOLATION_FOREST AND DNA10.MAX_SCORE_ISOLATION_FOREST
         AND DN10.PROB_CATBOOST           BETWEEN DNA10.MIN_PROB_CATBOOST           AND DNA10.MAX_PROB_CATBOOST
         AND DN10.PROB_LIGHTGBM           BETWEEN DNA10.MIN_PROB_LIGHTGBM           AND DNA10.MAX_PROB_LIGHTGBM
         AND DN10.PROB_XGBOOST            BETWEEN DNA10.MIN_PROB_XGBOOST            AND DNA10.MAX_PROB_XGBOOST
         AND DN2.SCORE_ISOLATION_FOREST   BETWEEN DNA2.MIN_SCORE_ISOLATION_FOREST   AND DNA2.MAX_SCORE_ISOLATION_FOREST
         AND DN2.PROB_CATBOOST             BETWEEN DNA2.MIN_PROB_CATBOOST             AND DNA2.MAX_PROB_CATBOOST
         AND DN2.PROB_LIGHTGBM             BETWEEN DNA2.MIN_PROB_LIGHTGBM             AND DNA2.MAX_PROB_LIGHTGBM
         AND DN2.PROB_XGBOOST              BETWEEN DNA2.MIN_PROB_XGBOOST              AND DNA2.MAX_PROB_XGBOOST
         AND FNC_CONTAR_MILHARES(F.TXT) = 1
       ORDER BY DD.TIMESTAMP_EXECUCAO_INS;

   -- Tipo ancorado no cursor
   r_orbita c_orbita%ROWTYPE;

BEGIN

   -- -------------------------------------------------------
   -- Cabeçalho de execução
   -- -------------------------------------------------------
   DBMS_OUTPUT.PUT_LINE('================================================');
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] Iniciando processamento');
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] Usuário   : ' || v_usuario);
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] Data ref  : ' || TO_CHAR(v_data_ref,  'DD/MM/YYYY'));
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] Janela    : ' || TO_CHAR(v_ts_inicio, 'HH24:MI') || ' até ' || TO_CHAR(v_ts_fim, 'HH24:MI'));
   DBMS_OUTPUT.PUT_LINE('================================================');

   -- -------------------------------------------------------
   -- Abertura e processamento do cursor
   -- -------------------------------------------------------
   OPEN c_orbita;

   LOOP
      FETCH c_orbita INTO r_orbita;
      EXIT WHEN c_orbita%NOTFOUND;

      v_total_lidos := v_total_lidos + 1;

      -- Lógica de classificação por MILHAR
      IF r_orbita.MILHAR IS NULL THEN

         v_total_skip := v_total_skip + 1;
         DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] SKIP  ID=' || r_orbita.ID_DADOS_ORBITA || ' - MILHAR nulo');

      ELSE

         v_total_proc := v_total_proc + 1;

         DBMS_OUTPUT.PUT_LINE(
            '[BLK_ORBITA] OK  '                                                ||
            ' ID='      || RPAD(r_orbita.ID_DADOS_ORBITA, 10)                  ||
            ' DATA='    || TO_CHAR(r_orbita.DATA_EXECUCAO, 'DD/MM/YYYY')       ||
            ' HORA='    || TO_CHAR(r_orbita.TIMESTAMP_EXECUCAO_INS, 'HH24:MI') ||
            ' CORRIDA=' || RPAD(NVL(TO_CHAR(r_orbita.CORRIDA), '-'), 6)        ||
            ' PREMIO='  || RPAD(NVL(TO_CHAR(r_orbita.PREMIO),  '-'), 6)        ||
            ' MILHAR='  || RPAD(NVL(TO_CHAR(r_orbita.MILHAR),  '-'), 5)        ||
            ' BICHO='   || NVL(TO_CHAR(r_orbita.BICHO), '-')
         );

         -- *** Insira aqui lógica adicional por registro ***
         -- Exemplo: INSERT, UPDATE, chamada de procedure, etc.

      END IF;

   END LOOP;

   CLOSE c_orbita;

   -- -------------------------------------------------------
   -- Resumo final
   -- -------------------------------------------------------
   DBMS_OUTPUT.PUT_LINE('================================================');
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] Resumo do processamento:');
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA]   Lidos      : ' || v_total_lidos);
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA]   Processados: ' || v_total_proc);
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA]   Ignorados  : ' || v_total_skip);
   DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA]   Duração    : ' ||
      ROUND(EXTRACT(SECOND FROM (SYSTIMESTAMP - v_inicio)), 2) || 's');
   DBMS_OUTPUT.PUT_LINE('================================================');

EXCEPTION
   WHEN CURSOR_ALREADY_OPEN THEN
      DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] ERRO: cursor já está aberto');
      IF c_orbita%ISOPEN THEN CLOSE c_orbita; END IF;
      RAISE;
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] ERRO: ' || SQLERRM);
      DBMS_OUTPUT.PUT_LINE('[BLK_ORBITA] TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      IF c_orbita%ISOPEN THEN CLOSE c_orbita; END IF;
      RAISE;
END;
/
