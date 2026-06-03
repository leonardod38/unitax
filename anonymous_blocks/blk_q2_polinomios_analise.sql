-- Tipo   : BLOCO ANÔNIMO
-- Objeto : blk_q2_polinomios_analise
-- Salvo  : 2026-05-16
-- Origem : Análise exploratória das colunas POLINOMIAL__ sobre os aprovados do Q1
-- Objetivo: responder 4 questões comparando 3 runs antes de construir filtros
--   Q-R2  : Winners têm R² mais alto? (qualidade do ajuste polinomial)
--   Q-CON : Winners são mais frequentemente CIMA?
--   Q-D2M : Winners têm D2_NO_MEIO positivo?
--   Q-INF : A inflexão dos winners cai em faixa de milhar específica?
-- Metodologia:
--   Run 1: d-30 sem prêmio  → ver padrão dos não-premiados
--   Run 2: d-30 com prêmio  → ver padrão dos premiados
--   Run 3: dia normal        → ver padrão misto
--   Comparar seção ANÁLISE entre os 3 runs para calibrar os filtros do Q2
-- Base: os mesmos 275 aprovados do Q1 (filtros de derivadas embutidos no cursor)
-- ------------------------------------------------------------
DECLARE
   -- Cursor: parte dos 275 aprovados do Q1 (derivadas embutidas no WHERE)
   -- CTE q1_base → 1 ID representante por padrão único de derivadas
   -- JOIN em T3 → busca colunas polinomiais desse representante
   CURSOR c_q2 IS
      WITH q1_base AS (
         SELECT MIN(T3.ID_DADOS_ORBITA) AS id_repr
           FROM DADOS_ORBITA     DD
           JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
          WHERE DD.TIMESTAMP_EXECUCAO_INS >= TRUNC(SYSDATE - 1) + 18/24
            AND DD.TIMESTAMP_EXECUCAO_INS <  TRUNC(SYSDATE - 1) + 19/24
            -- filtro base derivadas
            AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)         >= 100
            -- P1: sem forte desaceleração
            AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)         >= -300
            -- P5: abismo confirmado
            AND STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)       != -1
            -- P6: queda profunda
            AND STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO) <= -2000
            -- P7: milhar alto no abismo
            AND STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NO_ABISMO) >= 6000
          GROUP BY T3.DERIVADAS__D1_MEDIA
                 , T3.DERIVADAS__D1_MAX
                 , T3.DERIVADAS__D1_MIN
                 , T3.DERIVADAS__D1_DESVIO
                 , T3.DERIVADAS__D2_MEDIA
                 , T3.DERIVADAS__MILHAR_NA_PARADA
                 , T3.DERIVADAS__IDX_ABISMO
                 , T3.DERIVADAS__MAGNITUDE_ABISMO
                 , T3.DERIVADAS__MILHAR_NO_ABISMO
      )
      SELECT P.ID_DADOS_ORBITA
           , STR_PARA_NUMERO(P.POLINOMIAL__R2)                  AS v_r2
           , P.POLINOMIAL__CONCAVIDADE                          AS v_concavidade
           , STR_PARA_NUMERO(P.POLINOMIAL__D2_NO_MEIO)          AS v_d2_meio
           , STR_PARA_NUMERO(P.POLINOMIAL__PONTO_INFLEXAO_MIL)  AS v_inf_mil
           , STR_PARA_NUMERO(P.POLINOMIAL__COEF_A)              AS v_coef_a
        FROM q1_base
        JOIN ORBITAS_TABELAO1 P ON P.ID_DADOS_ORBITA = q1_base.id_repr
       ORDER BY STR_PARA_NUMERO(P.POLINOMIAL__R2) DESC;

   -- Contadores gerais
   v_total   NUMBER := 0;

   -- ── Q-R2: Qualidade do ajuste (R²) ──────────────────────────────────────
   v_r2_soma   NUMBER := 0;
   v_r2_min    NUMBER :=  999;
   v_r2_max    NUMBER := -999;
   v_r2_lt01   NUMBER := 0;   -- R² < 0.1  (ajuste muito ruim)
   v_r2_01_03  NUMBER := 0;   -- 0.1 <= R² < 0.3 (fraco)
   v_r2_03_05  NUMBER := 0;   -- 0.3 <= R² < 0.5 (moderado)
   v_r2_ge05   NUMBER := 0;   -- R² >= 0.5 (bom ajuste)

   -- ── Q-CON: Concavidade ──────────────────────────────────────────────────
   v_con_cima  NUMBER := 0;
   v_con_baixo NUMBER := 0;

   -- ── Q-D2M: D2 no meio da série ─────────────────────────────────────────
   v_d2m_soma   NUMBER := 0;
   v_d2m_min    NUMBER :=  999999;
   v_d2m_max    NUMBER := -999999;
   v_d2m_pos    NUMBER := 0;   -- D2_MEIO > 0  (acelerando no meio)
   v_d2m_neg    NUMBER := 0;   -- D2_MEIO < 0  (desacelerando no meio)
   v_d2m_lt_m100 NUMBER := 0;  -- < -100 (forte desacel.)
   v_d2m_m100_0  NUMBER := 0;  -- -100 a 0 (leve desacel.)
   v_d2m_0_100   NUMBER := 0;  -- 0 a 100 (leve acel.)
   v_d2m_gt100   NUMBER := 0;  -- > 100 (forte acel.)

   -- ── Q-INF: Ponto de inflexão em milhar ─────────────────────────────────
   v_inf_soma   NUMBER := 0;
   v_inf_min    NUMBER :=  999999;
   v_inf_max    NUMBER := -999999;
   v_inf_valid  NUMBER := 0;   -- milhar no domínio real (0–9999)
   v_inf_out    NUMBER := 0;   -- outlier: < 0 ou > 9999 (ajuste extrapolado)
   v_inf_lt3k   NUMBER := 0;   -- 0 – 2999
   v_inf_3_5k   NUMBER := 0;   -- 3000 – 4999
   v_inf_5_7k   NUMBER := 0;   -- 5000 – 6999
   v_inf_7_9k   NUMBER := 0;   -- 7000 – 8999
   v_inf_gt9k   NUMBER := 0;   -- 9000 – 9999

BEGIN
   DBMS_OUTPUT.PUT_LINE('[BLK_Q2_POLINOMIOS] Análise exploratória — POLINOMIAL__');
   DBMS_OUTPUT.PUT_LINE('[BLK_Q2_POLINOMIOS] Referência: ' || TO_CHAR(SYSDATE-1,'DD/MM/YYYY') || ' 18h–19h');
   DBMS_OUTPUT.PUT_LINE('[BLK_Q2_POLINOMIOS] Base: aprovados Q1 (D1>=100, P1+P5+P6+P7 embutidos)');

   FOR r IN c_q2 LOOP
      v_total := v_total + 1;

      -- ── Q-R2 ──
      IF r.v_r2 IS NOT NULL THEN
         v_r2_soma := v_r2_soma + r.v_r2;
         IF r.v_r2 < v_r2_min THEN v_r2_min := r.v_r2; END IF;
         IF r.v_r2 > v_r2_max THEN v_r2_max := r.v_r2; END IF;
         IF    r.v_r2 < 0.1  THEN v_r2_lt01  := v_r2_lt01  + 1;
         ELSIF r.v_r2 < 0.3  THEN v_r2_01_03 := v_r2_01_03 + 1;
         ELSIF r.v_r2 < 0.5  THEN v_r2_03_05 := v_r2_03_05 + 1;
         ELSE                      v_r2_ge05  := v_r2_ge05  + 1;
         END IF;
      END IF;

      -- ── Q-CON ──
      IF    r.v_concavidade = 'CIMA'  THEN v_con_cima  := v_con_cima  + 1;
      ELSIF r.v_concavidade = 'BAIXO' THEN v_con_baixo := v_con_baixo + 1;
      END IF;

      -- ── Q-D2M ──
      IF r.v_d2_meio IS NOT NULL THEN
         v_d2m_soma := v_d2m_soma + r.v_d2_meio;
         IF r.v_d2_meio < v_d2m_min THEN v_d2m_min := r.v_d2_meio; END IF;
         IF r.v_d2_meio > v_d2m_max THEN v_d2m_max := r.v_d2_meio; END IF;
         IF r.v_d2_meio > 0 THEN v_d2m_pos := v_d2m_pos + 1;
                             ELSE v_d2m_neg := v_d2m_neg + 1;
         END IF;
         IF    r.v_d2_meio < -100 THEN v_d2m_lt_m100 := v_d2m_lt_m100 + 1;
         ELSIF r.v_d2_meio <    0 THEN v_d2m_m100_0  := v_d2m_m100_0  + 1;
         ELSIF r.v_d2_meio <  100 THEN v_d2m_0_100   := v_d2m_0_100   + 1;
         ELSE                          v_d2m_gt100   := v_d2m_gt100   + 1;
         END IF;
      END IF;

      -- ── Q-INF ──
      IF r.v_inf_mil IS NOT NULL THEN
         IF r.v_inf_mil < 0 OR r.v_inf_mil > 9999 THEN
            v_inf_out := v_inf_out + 1;   -- fora do domínio real de milhares
         ELSE
            v_inf_valid := v_inf_valid + 1;
            v_inf_soma  := v_inf_soma + r.v_inf_mil;
            IF r.v_inf_mil < v_inf_min THEN v_inf_min := r.v_inf_mil; END IF;
            IF r.v_inf_mil > v_inf_max THEN v_inf_max := r.v_inf_mil; END IF;
            IF    r.v_inf_mil < 3000 THEN v_inf_lt3k := v_inf_lt3k + 1;
            ELSIF r.v_inf_mil < 5000 THEN v_inf_3_5k := v_inf_3_5k + 1;
            ELSIF r.v_inf_mil < 7000 THEN v_inf_5_7k := v_inf_5_7k + 1;
            ELSIF r.v_inf_mil < 9000 THEN v_inf_7_9k := v_inf_7_9k + 1;
            ELSE                          v_inf_gt9k := v_inf_gt9k + 1;
            END IF;
         END IF;
      END IF;

      -- Linha detalhada por corrida
      DBMS_OUTPUT.PUT_LINE(
         '[Q2] ID=' || LPAD(TO_CHAR(r.ID_DADOS_ORBITA), 10) ||
         '  R2='    || LPAD(TO_CHAR(r.v_r2,      'FM0.9999'), 7) ||
         '  CON='   || RPAD(NVL(r.v_concavidade, '?'), 5)        ||
         '  D2M='   || LPAD(TO_CHAR(r.v_d2_meio,  'FM999990.99'), 9) ||
         '  INF_MIL=' || LPAD(TO_CHAR(r.v_inf_mil, 'FM999990.99'), 9) ||
         '  A='     || LPAD(TO_CHAR(r.v_coef_a,  'FM990.99'), 7)
      );
   END LOOP;

   -- ============================================================
   -- ANÁLISE ESTATÍSTICA — respostas às 4 questões
   -- Compare esta seção entre os 3 runs
   -- ============================================================
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════╗');
   DBMS_OUTPUT.PUT_LINE('║  ANÁLISE POLINOMIAL — BASE Q1 (' || LPAD(v_total,3) || ' corridas)         ║');
   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-R2
   DBMS_OUTPUT.PUT_LINE('║  Q-R2: Qualidade do ajuste polinomial (R²)          ║');
   DBMS_OUTPUT.PUT_LINE('║    R² < 0.1  (muito ruim) : ' || LPAD(v_r2_lt01,  3) || ' (' || LPAD(ROUND(100*v_r2_lt01 /NULLIF(v_total,0)),3) || '%)                   ║');
   DBMS_OUTPUT.PUT_LINE('║    R² 0.1–0.3 (fraco)    : ' || LPAD(v_r2_01_03, 3) || ' (' || LPAD(ROUND(100*v_r2_01_03/NULLIF(v_total,0)),3) || '%)                   ║');
   DBMS_OUTPUT.PUT_LINE('║    R² 0.3–0.5 (moderado) : ' || LPAD(v_r2_03_05, 3) || ' (' || LPAD(ROUND(100*v_r2_03_05/NULLIF(v_total,0)),3) || '%)                   ║');
   DBMS_OUTPUT.PUT_LINE('║    R² >= 0.5  (bom)      : ' || LPAD(v_r2_ge05,  3) || ' (' || LPAD(ROUND(100*v_r2_ge05 /NULLIF(v_total,0)),3) || '%)                   ║');
   DBMS_OUTPUT.PUT_LINE('║    Mínimo: ' || LPAD(TO_CHAR(v_r2_min,'FM0.9999'),7) ||
                        '  Máximo: ' || LPAD(TO_CHAR(v_r2_max,'FM0.9999'),7) ||
                        '  Média: ' || LPAD(TO_CHAR(ROUND(v_r2_soma/NULLIF(v_total,0),4),'FM0.9999'),7) || '  ║');

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-CON
   DBMS_OUTPUT.PUT_LINE('║  Q-CON: Concavidade da curva polinomial             ║');
   DBMS_OUTPUT.PUT_LINE('║    CIMA  (curva abre p/ cima)  : ' || LPAD(v_con_cima,  3) || ' (' || LPAD(ROUND(100*v_con_cima /NULLIF(v_total,0)),3) || '%)             ║');
   DBMS_OUTPUT.PUT_LINE('║    BAIXO (curva abre p/ baixo) : ' || LPAD(v_con_baixo, 3) || ' (' || LPAD(ROUND(100*v_con_baixo/NULLIF(v_total,0)),3) || '%)             ║');

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-D2M
   DBMS_OUTPUT.PUT_LINE('║  Q-D2M: Segunda derivada no meio da série           ║');
   DBMS_OUTPUT.PUT_LINE('║    Positivo (acelerando no meio) : ' || LPAD(v_d2m_pos, 3) || ' (' || LPAD(ROUND(100*v_d2m_pos/NULLIF(v_total,0)),3) || '%)            ║');
   DBMS_OUTPUT.PUT_LINE('║    Negativo (desacel. no meio)   : ' || LPAD(v_d2m_neg, 3) || ' (' || LPAD(ROUND(100*v_d2m_neg/NULLIF(v_total,0)),3) || '%)            ║');
   DBMS_OUTPUT.PUT_LINE('║    < -100 (forte desacel.)  : ' || LPAD(v_d2m_lt_m100, 3) || '              ║');
   DBMS_OUTPUT.PUT_LINE('║    -100 a 0 (leve desacel.) : ' || LPAD(v_d2m_m100_0,  3) || '              ║');
   DBMS_OUTPUT.PUT_LINE('║    0 a 100  (leve acel.)    : ' || LPAD(v_d2m_0_100,   3) || '              ║');
   DBMS_OUTPUT.PUT_LINE('║    > 100    (forte acel.)   : ' || LPAD(v_d2m_gt100,   3) || '              ║');
   DBMS_OUTPUT.PUT_LINE('║    Mínimo: ' || LPAD(TO_CHAR(v_d2m_min,'FM999990.99'),9) ||
                        '  Máximo: ' || LPAD(TO_CHAR(v_d2m_max,'FM999990.99'),9) || '         ║');
   DBMS_OUTPUT.PUT_LINE('║    Média:  ' || LPAD(TO_CHAR(ROUND(v_d2m_soma/NULLIF(v_total,0),2),'FM999990.99'),9) || '                              ║');

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-INF
   DBMS_OUTPUT.PUT_LINE('║  Q-INF: Ponto de inflexão em milhar                 ║');
   DBMS_OUTPUT.PUT_LINE('║    Dentro do domínio (0–9999) : ' || LPAD(v_inf_valid, 3) || '                    ║');
   DBMS_OUTPUT.PUT_LINE('║    Fora do domínio (outlier)  : ' || LPAD(v_inf_out,   3) || ' (ajuste extrapolado)  ║');
   DBMS_OUTPUT.PUT_LINE('║    0 – 2999   : ' || LPAD(v_inf_lt3k, 3) || ' (' || LPAD(ROUND(100*v_inf_lt3k/NULLIF(v_inf_valid,0)),3) || '%)                       ║');
   DBMS_OUTPUT.PUT_LINE('║    3000–4999  : ' || LPAD(v_inf_3_5k, 3) || ' (' || LPAD(ROUND(100*v_inf_3_5k/NULLIF(v_inf_valid,0)),3) || '%)                       ║');
   DBMS_OUTPUT.PUT_LINE('║    5000–6999  : ' || LPAD(v_inf_5_7k, 3) || ' (' || LPAD(ROUND(100*v_inf_5_7k/NULLIF(v_inf_valid,0)),3) || '%)                       ║');
   DBMS_OUTPUT.PUT_LINE('║    7000–8999  : ' || LPAD(v_inf_7_9k, 3) || ' (' || LPAD(ROUND(100*v_inf_7_9k/NULLIF(v_inf_valid,0)),3) || '%)                       ║');
   DBMS_OUTPUT.PUT_LINE('║    9000–9999  : ' || LPAD(v_inf_gt9k, 3) || ' (' || LPAD(ROUND(100*v_inf_gt9k/NULLIF(v_inf_valid,0)),3) || '%)                       ║');
   IF v_inf_valid > 0 THEN
      DBMS_OUTPUT.PUT_LINE('║    Mínimo: ' || LPAD(TO_CHAR(v_inf_min,'FM999990'),6) ||
                           '  Máximo: ' || LPAD(TO_CHAR(v_inf_max,'FM999990'),6) ||
                           '  Média: ' || LPAD(TO_CHAR(ROUND(v_inf_soma/v_inf_valid,0),'FM999990'),6) || '        ║');
   END IF;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');
   DBMS_OUTPUT.PUT_LINE('║  RESUMO                                              ║');
   DBMS_OUTPUT.PUT_LINE('║  Base Q1 analisada : ' || LPAD(v_total, 4) || ' corridas                    ║');
   DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════╝');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[BLK_Q2_POLINOMIOS] Erro: ' || SQLERRM);
      RAISE;
END;
/
