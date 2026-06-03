-- Tipo   : BLOCO ANÔNIMO
-- Objeto : blk_q2_padrao_milhar
-- Salvo  : 2026-05-16
-- Origem : Investigação Opção C — PADRAO_MILHAR como atalho para 10:1
-- Objetivo: Verificar se PADRAO_MILHAR__ colunas discriminam premiados vs não-premiados
--   Hipótese original: PADRAO_MILHAR__RESULTADO prediz o milhar vencedor diretamente
--   Resultado CSV   : RESULTADO = BASICO__MILHAR_FINAL arredondado (100% match) → tautológico
--   Sinal real      : PARADA_FINAL por zona (Z4: +9%, Z1: +7% nos premiados)
--   Bonus descoberto: SUFIXO__TENDENCIA_CRESCENTE e PERCENTIS__FINAL_NO_IQR (delta ~10%)
-- Metodologia: run único d-30 com estratificação interna por PREMIO > 0 vs PREMIO = 0
-- Base: 275 aprovados/dia do Q1 (filtros embutidos no cursor via CTE)
-- ------------------------------------------------------------
DECLARE
   CURSOR c_q2 IS
      WITH q1_base AS (
         SELECT MIN(T3.ID_DADOS_ORBITA) AS id_repr
           FROM DADOS_ORBITA     DD
           JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
          WHERE DD.TIMESTAMP_EXECUCAO_INS >= TRUNC(SYSDATE - 30) + 18/24
            AND DD.TIMESTAMP_EXECUCAO_INS <  TRUNC(SYSDATE)     + 19/24
            AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)         >= 100
            AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)         >= -300
            AND STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)       != -1
            AND STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO) <= -2000
            AND STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NO_ABISMO) >= 6000
          GROUP BY T3.DERIVADAS__D1_MEDIA, T3.DERIVADAS__D1_MAX
                 , T3.DERIVADAS__D1_MIN,   T3.DERIVADAS__D1_DESVIO
                 , T3.DERIVADAS__D2_MEDIA, T3.DERIVADAS__MILHAR_NA_PARADA
                 , T3.DERIVADAS__IDX_ABISMO
                 , T3.DERIVADAS__MAGNITUDE_ABISMO
                 , T3.DERIVADAS__MILHAR_NO_ABISMO
      )
      SELECT P.ID_DADOS_ORBITA
           , STR_PARA_NUMERO(P.PREMIO)                           AS v_premio
           , STR_PARA_NUMERO(P.BASICO__MILHAR_FINAL)             AS v_milhar_final
           -- PADRAO_MILHAR
           , STR_PARA_NUMERO(P.PADRAO_MILHAR__RESULTADO)         AS v_pm_resultado
           , P.PADRAO_MILHAR__RESULTADO_REDON                    AS v_pm_redon
           , STR_PARA_NUMERO(P.PADRAO_MILHAR__PARADA_FINAL)      AS v_pm_parada
           , STR_PARA_NUMERO(P.PADRAO_MILHAR__SUFIXO_FINAL)      AS v_pm_sufixo
           , P.PADRAO_MILHAR__TEM_PADRAO_25                      AS v_pm_tem25
           , STR_PARA_NUMERO(P.PADRAO_MILHAR__TOTAL_SUFIXO_25)   AS v_pm_total25
           , STR_PARA_NUMERO(P.PADRAO_MILHAR__RASTRO_TAMANHO)    AS v_pm_rastro
           -- Colunas bonus descobertas na varredura CSV
           , P.SUFIXO__TENDENCIA_CRESCENTE                       AS v_suf_tend
           , P.PERCENTIS__FINAL_NO_IQR                           AS v_perc_iqr
           , P.COMP_APOS_PICO__DESCIDA_TIPO                      AS v_descida_tipo
           , P.VOLAT_SEGMENTO__VOL_PADRAO                        AS v_vol_padrao
        FROM q1_base
        JOIN ORBITAS_TABELAO1 P ON P.ID_DADOS_ORBITA = q1_base.id_repr
       ORDER BY STR_PARA_NUMERO(P.PREMIO) DESC, STR_PARA_NUMERO(P.DERIVADAS__D1_MEDIA) DESC;

   v_total    NUMBER := 0;
   v_winners  NUMBER := 0;
   v_nao      NUMBER := 0;

   -- Hipótese resultado == milhar_final
   v_w_match  NUMBER := 0;
   v_n_match  NUMBER := 0;

   -- PARADA_FINAL por zona (0-9)
   TYPE t_zona IS TABLE OF NUMBER INDEX BY VARCHAR2(5);
   v_w_pz  t_zona;
   v_n_pz  t_zona;

   -- TEM_PADRAO_25 e RESULTADO_REDON (esperado: constantes)
   v_w_tem25_s  NUMBER := 0;  v_n_tem25_s  NUMBER := 0;
   v_w_redon_s  NUMBER := 0;  v_n_redon_s  NUMBER := 0;

   -- SUFIXO__TENDENCIA_CRESCENTE (descoberta: delta -11% em val=0.5)
   TYPE t_freq IS TABLE OF NUMBER INDEX BY VARCHAR2(20);
   v_w_tend  t_freq;
   v_n_tend  t_freq;

   -- PERCENTIS__FINAL_NO_IQR (descoberta: delta -10% em val=S)
   v_w_iqr_s  NUMBER := 0;  v_n_iqr_s  NUMBER := 0;

   -- COMP_APOS_PICO__DESCIDA_TIPO (descoberta: QUEDA_IRREGULAR +9%)
   v_w_irreg  NUMBER := 0;  v_n_irreg  NUMBER := 0;

   -- VOLAT_SEGMENTO__VOL_PADRAO (DECRESCENTE -7% nos premiados)
   v_w_decr  NUMBER := 0;  v_n_decr  NUMBER := 0;

   v_zona_key  VARCHAR2(5);
   v_is_w      BOOLEAN;

BEGIN
   DBMS_OUTPUT.PUT_LINE('=== Q2: PADRAO_MILHAR + Varredura Bonus ===');
   DBMS_OUTPUT.PUT_LINE('Janela: d-30 | Estratificação: PREMIO > 0 vs PREMIO = 0');
   DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------');

   FOR r IN c_q2 LOOP
      v_total := v_total + 1;
      v_is_w  := (r.v_premio > 0);

      IF v_is_w THEN v_winners := v_winners + 1;
      ELSE           v_nao     := v_nao     + 1;
      END IF;

      -- Hipótese: resultado == milhar_final?
      IF r.v_pm_resultado IS NOT NULL AND r.v_milhar_final IS NOT NULL THEN
         IF r.v_pm_resultado = r.v_milhar_final THEN
            IF v_is_w THEN v_w_match := v_w_match + 1;
            ELSE           v_n_match := v_n_match + 1;
            END IF;
         END IF;
      END IF;

      -- PARADA_FINAL por zona
      IF r.v_pm_parada IS NOT NULL THEN
         v_zona_key := 'Z' || TO_CHAR(TRUNC(r.v_pm_parada / 1000));
         IF v_is_w THEN
            IF v_w_pz.EXISTS(v_zona_key) THEN v_w_pz(v_zona_key) := v_w_pz(v_zona_key) + 1;
            ELSE                               v_w_pz(v_zona_key) := 1;
            END IF;
         ELSE
            IF v_n_pz.EXISTS(v_zona_key) THEN v_n_pz(v_zona_key) := v_n_pz(v_zona_key) + 1;
            ELSE                               v_n_pz(v_zona_key) := 1;
            END IF;
         END IF;
      END IF;

      -- TEM_PADRAO_25
      IF r.v_pm_tem25 = 'S' THEN
         IF v_is_w THEN v_w_tem25_s := v_w_tem25_s + 1;
         ELSE           v_n_tem25_s := v_n_tem25_s + 1;
         END IF;
      END IF;

      -- RESULTADO_REDON
      IF r.v_pm_redon = 'S' THEN
         IF v_is_w THEN v_w_redon_s := v_w_redon_s + 1;
         ELSE           v_n_redon_s := v_n_redon_s + 1;
         END IF;
      END IF;

      -- SUFIXO__TENDENCIA_CRESCENTE
      IF r.v_suf_tend IS NOT NULL THEN
         IF v_is_w THEN
            IF v_w_tend.EXISTS(r.v_suf_tend) THEN v_w_tend(r.v_suf_tend) := v_w_tend(r.v_suf_tend) + 1;
            ELSE                                   v_w_tend(r.v_suf_tend) := 1;
            END IF;
         ELSE
            IF v_n_tend.EXISTS(r.v_suf_tend) THEN v_n_tend(r.v_suf_tend) := v_n_tend(r.v_suf_tend) + 1;
            ELSE                                   v_n_tend(r.v_suf_tend) := 1;
            END IF;
         END IF;
      END IF;

      -- PERCENTIS__FINAL_NO_IQR
      IF r.v_perc_iqr = 'S' THEN
         IF v_is_w THEN v_w_iqr_s := v_w_iqr_s + 1;
         ELSE           v_n_iqr_s := v_n_iqr_s + 1;
         END IF;
      END IF;

      -- COMP_APOS_PICO__DESCIDA_TIPO
      IF r.v_descida_tipo = 'QUEDA_IRREGULAR' THEN
         IF v_is_w THEN v_w_irreg := v_w_irreg + 1;
         ELSE           v_n_irreg := v_n_irreg + 1;
         END IF;
      END IF;

      -- VOLAT_SEGMENTO__VOL_PADRAO
      IF r.v_vol_padrao = 'DECRESCENTE' THEN
         IF v_is_w THEN v_w_decr := v_w_decr + 1;
         ELSE           v_n_decr := v_n_decr + 1;
         END IF;
      END IF;
   END LOOP;

   -- ================================================================
   -- OUTPUT
   -- ================================================================
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('--- TOTAIS ---');
   DBMS_OUTPUT.PUT_LINE('Total lido  : ' || v_total);
   DBMS_OUTPUT.PUT_LINE('Premiados   : ' || v_winners);
   DBMS_OUTPUT.PUT_LINE('Não-prem.   : ' || v_nao);
   DBMS_OUTPUT.PUT_LINE('');

   -- Hipótese resultado == milhar_final
   DBMS_OUTPUT.PUT_LINE('--- HIPÓTESE: resultado == milhar_final ---');
   IF v_winners > 0 THEN
      DBMS_OUTPUT.PUT_LINE('Premiados match  : ' || v_w_match || '/' || v_winners ||
         ' (' || ROUND(v_w_match * 100 / v_winners, 1) || '%)');
   END IF;
   IF v_nao > 0 THEN
      DBMS_OUTPUT.PUT_LINE('Não-prem. match  : ' || v_n_match || '/' || v_nao ||
         ' (' || ROUND(v_n_match * 100 / v_nao, 1) || '%)');
   END IF;
   DBMS_OUTPUT.PUT_LINE('→ Se ambos ~100%: resultado é tautológico (= milhar_final arredondado)');
   DBMS_OUTPUT.PUT_LINE('');

   -- PARADA_FINAL por zona
   DBMS_OUTPUT.PUT_LINE('--- PARADA_FINAL por zona (sinal real do grupo) ---');
   DBMS_OUTPUT.PUT_LINE('Zona | Prem%  | NaoPrem% | Diff');
   FOR i IN 0..9 LOOP
      v_zona_key := 'Z' || TO_CHAR(i);
      DECLARE
         v_wc  NUMBER := CASE WHEN v_w_pz.EXISTS(v_zona_key) THEN v_w_pz(v_zona_key) ELSE 0 END;
         v_nc  NUMBER := CASE WHEN v_n_pz.EXISTS(v_zona_key) THEN v_n_pz(v_zona_key) ELSE 0 END;
         v_wp  NUMBER := 0;
         v_np  NUMBER := 0;
      BEGIN
         IF v_winners > 0 THEN v_wp := ROUND(v_wc * 100 / v_winners, 1); END IF;
         IF v_nao     > 0 THEN v_np := ROUND(v_nc * 100 / v_nao,     1); END IF;
         DBMS_OUTPUT.PUT_LINE(
            RPAD(v_zona_key, 5) || '| ' || LPAD(v_wp, 6) || '% | ' ||
            LPAD(v_np, 8) || '% | ' || LPAD(ROUND(v_wp - v_np, 1), 5));
      END;
   END LOOP;
   DBMS_OUTPUT.PUT_LINE('');

   -- TEM_PADRAO_25 / RESULTADO_REDON (esperado: constante)
   DBMS_OUTPUT.PUT_LINE('--- CONSTANTES esperadas (deve ser 100% em ambos) ---');
   IF v_winners > 0 THEN
      DBMS_OUTPUT.PUT_LINE('TEM_PADRAO_25=S  Prem: ' || ROUND(v_w_tem25_s * 100 / v_winners, 1) ||
         '%  NaoPrem: ' || ROUND(v_n_tem25_s * 100 / v_nao, 1) || '%');
      DBMS_OUTPUT.PUT_LINE('RESULTADO_REDON=S  Prem: ' || ROUND(v_w_redon_s * 100 / v_winners, 1) ||
         '%  NaoPrem: ' || ROUND(v_n_redon_s * 100 / v_nao, 1) || '%');
   END IF;
   DBMS_OUTPUT.PUT_LINE('');

   -- SUFIXO__TENDENCIA_CRESCENTE
   DBMS_OUTPUT.PUT_LINE('--- SUFIXO__TENDENCIA_CRESCENTE (delta ~11% em val=0.5) ---');
   DBMS_OUTPUT.PUT_LINE('Val   | Prem%  | NaoPrem% | Diff');
   DECLARE
      v_key  VARCHAR2(20);
   BEGIN
      v_key := v_w_tend.FIRST;
      WHILE v_key IS NOT NULL LOOP
         DECLARE
            v_wc  NUMBER := CASE WHEN v_w_tend.EXISTS(v_key) THEN v_w_tend(v_key) ELSE 0 END;
            v_nc  NUMBER := CASE WHEN v_n_tend.EXISTS(v_key) THEN v_n_tend(v_key) ELSE 0 END;
            v_wp  NUMBER := 0;
            v_np  NUMBER := 0;
         BEGIN
            IF v_winners > 0 THEN v_wp := ROUND(v_wc * 100 / v_winners, 1); END IF;
            IF v_nao     > 0 THEN v_np := ROUND(v_nc * 100 / v_nao,     1); END IF;
            DBMS_OUTPUT.PUT_LINE(
               RPAD(v_key, 6) || '| ' || LPAD(v_wp, 6) || '% | ' ||
               LPAD(v_np, 8) || '% | ' || LPAD(ROUND(v_wp - v_np, 1), 5));
         END;
         v_key := v_w_tend.NEXT(v_key);
      END LOOP;
   END;
   DBMS_OUTPUT.PUT_LINE('');

   -- PERCENTIS__FINAL_NO_IQR
   DBMS_OUTPUT.PUT_LINE('--- PERCENTIS__FINAL_NO_IQR (delta ~10%) ---');
   IF v_winners > 0 AND v_nao > 0 THEN
      DBMS_OUTPUT.PUT_LINE('IQR=S  Prem: ' || ROUND(v_w_iqr_s * 100 / v_winners, 1) ||
         '%  NaoPrem: ' || ROUND(v_n_iqr_s * 100 / v_nao, 1) ||
         '%  Diff: ' || ROUND(v_w_iqr_s * 100 / v_winners - v_n_iqr_s * 100 / v_nao, 1));
      DBMS_OUTPUT.PUT_LINE('IQR=N  Prem: ' || ROUND((v_winners - v_w_iqr_s) * 100 / v_winners, 1) ||
         '%  NaoPrem: ' || ROUND((v_nao - v_n_iqr_s) * 100 / v_nao, 1) ||
         '%  (premiados FORA do IQR → valores extremos)');
   END IF;
   DBMS_OUTPUT.PUT_LINE('');

   -- COMP_APOS_PICO__DESCIDA_TIPO
   DBMS_OUTPUT.PUT_LINE('--- COMP_APOS_PICO__DESCIDA_TIPO (QUEDA_IRREGULAR +9%) ---');
   IF v_winners > 0 AND v_nao > 0 THEN
      DBMS_OUTPUT.PUT_LINE('QUEDA_IRREGULAR  Prem: ' || ROUND(v_w_irreg * 100 / v_winners, 1) ||
         '%  NaoPrem: ' || ROUND(v_n_irreg * 100 / v_nao, 1) ||
         '%  Diff: +' || ROUND(v_w_irreg * 100 / v_winners - v_n_irreg * 100 / v_nao, 1));
   END IF;
   DBMS_OUTPUT.PUT_LINE('');

   -- VOLAT_SEGMENTO__VOL_PADRAO
   DBMS_OUTPUT.PUT_LINE('--- VOLAT_SEGMENTO__VOL_PADRAO (DECRESCENTE: prem evitam) ---');
   IF v_winners > 0 AND v_nao > 0 THEN
      DBMS_OUTPUT.PUT_LINE('DECRESCENTE  Prem: ' || ROUND(v_w_decr * 100 / v_winners, 1) ||
         '%  NaoPrem: ' || ROUND(v_n_decr * 100 / v_nao, 1) ||
         '%  Diff: ' || ROUND(v_w_decr * 100 / v_winners - v_n_decr * 100 / v_nao, 1));
   END IF;
   DBMS_OUTPUT.PUT_LINE('');

   -- CONCLUSÃO
   DBMS_OUTPUT.PUT_LINE('=== CONCLUSÃO ===');
   DBMS_OUTPUT.PUT_LINE('RESULTADO     : tautológico (= MILHAR_FINAL arredondado)');
   DBMS_OUTPUT.PUT_LINE('TEM_PADRAO_25 : constante (100% em ambos grupos)');
   DBMS_OUTPUT.PUT_LINE('SUFIXO_FINAL  : constante (= 25 em todos)');
   DBMS_OUTPUT.PUT_LINE('Sinal real PM : PARADA_FINAL em Z4 (+9%) e Z1 (+7%)');
   DBMS_OUTPUT.PUT_LINE('Bonus found   : SUFIXO__TENDENCIA_CRESCENTE=0.5 (-11%)');
   DBMS_OUTPUT.PUT_LINE('              : PERCENTIS__FINAL_NO_IQR=N (+10% premiados fora IQR)');
   DBMS_OUTPUT.PUT_LINE('              : COMP_APOS_PICO__DESCIDA_TIPO=QUEDA_IRREGULAR (+9%)');
   DBMS_OUTPUT.PUT_LINE('              : VOLAT_SEGMENTO__VOL_PADRAO≠DECRESCENTE (+7%)');
   DBMS_OUTPUT.PUT_LINE('→ Opção C descartada: não há atalho em PADRAO_MILHAR');
   DBMS_OUTPUT.PUT_LINE('→ Sinais disponíveis: max ~10-11% delta individualmente');
   DBMS_OUTPUT.PUT_LINE('→ Próximo: combinar múltiplos sinais (Opção B) ou aguardar FUNIL');
END;
/
