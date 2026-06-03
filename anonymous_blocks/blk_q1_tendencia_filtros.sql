-- Tipo   : BLOCO ANÔNIMO
-- Objeto : blk_q1_tendencia_filtros
-- Salvo  : 2026-05-16
-- v11    : D1 >= -200 (era 100) e D2 >= -400 (era -300)
--          Diagnóstico 16/05/2026: v10 capturava 2/10 ganhadores (20%)
--          v11 captura 7/10 ganhadores (70%) — inclui órbitas descendentes válidas
--          Os 3 ganhadores restantes: 2 sem abismo (IDX=-1) e 1 abismo fraco (MAG=-906)
-- v10    : 2026-05-15 — D1>=100, D2>=-300 → 2/10 ganhadores (20%)
-- Histórico de calibração:
--   CAP/P3/P4 REMOVIDOS — foram calibrados no d-30-sem-prêmio e rejeitavam winners legítimos:
--     ex: DEV=4434,D2=352,MAG=-7969,M_AB=9114 → CAP rejeitava mas é winner claro
--     ex: ratio=15x,D2=457,MAG=-5490,M_AB=9390 → P3 rejeitava mas é winner claro
-- Filtros ativos (v11):
--   cursor: D1 >= -200  — inclui órbitas descendentes (4 ganhadores adicionais capturados)
--   P1: D2 >= -400  — exclui apenas forte desaceleração extrema (era -300)
--   P5: IDX != -1   — abismo confirmado
--   P6: MAG <= -2000 — queda profunda
--   P7: M_AB >= 6000 — milhar alto no abismo
-- ------------------------------------------------------------
DECLARE
   CURSOR c_q1 IS
      SELECT MIN(T3.ID_DADOS_ORBITA)                         AS v_id_repr
           , COUNT(*)                                         AS v_qtde_milhares
           , STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)         AS v_d1_media
           , STR_PARA_NUMERO(T3.DERIVADAS__D1_MAX)           AS v_d1_max
           , STR_PARA_NUMERO(T3.DERIVADAS__D1_MIN)           AS v_d1_min
           , STR_PARA_NUMERO(T3.DERIVADAS__D1_DESVIO)        AS v_d1_desvio
           , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)         AS v_d2_media
           , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NA_PARADA) AS v_milhar_parada
           , STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)       AS v_idx_abismo
           , STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO) AS v_mag_abismo
           , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NO_ABISMO) AS v_milhar_abismo
        FROM DADOS_ORBITA     DD
        JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
       WHERE DD.TIMESTAMP_EXECUCAO_INS >= TRUNC(SYSDATE - 1) + 18/24
         AND DD.TIMESTAMP_EXECUCAO_INS <  TRUNC(SYSDATE - 1) + 19/24
         AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) >= -200
       GROUP BY T3.DERIVADAS__D1_MEDIA
              , T3.DERIVADAS__D1_MAX
              , T3.DERIVADAS__D1_MIN
              , T3.DERIVADAS__D1_DESVIO
              , T3.DERIVADAS__D2_MEDIA
              , T3.DERIVADAS__MILHAR_NA_PARADA
              , T3.DERIVADAS__IDX_ABISMO
              , T3.DERIVADAS__MAGNITUDE_ABISMO
              , T3.DERIVADAS__MILHAR_NO_ABISMO
       ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) DESC;

   TYPE t_linhas IS TABLE OF VARCHAR2(400) INDEX BY PLS_INTEGER;
   v_ap   t_linhas;
   v_p1   t_linhas;   -- D2 < 50
   v_p5   t_linhas;   -- sem abismo (IDX=-1)
   v_p6   t_linhas;   -- queda suave/positiva (MAG > -2000)
   v_p7   t_linhas;   -- milhar baixo no abismo (M_AB < 6000)

   -- Estatísticas dos aprovados
   TYPE t_freq IS TABLE OF NUMBER INDEX BY VARCHAR2(10);
   v_par_freq    t_freq;
   v_mab_freq    t_freq;
   v_iter_key    VARCHAR2(10);

   v_ap_idx_sem    NUMBER := 0;
   v_ap_idx_1_5    NUMBER := 0;
   v_ap_idx_6_10   NUMBER := 0;
   v_ap_idx_11plus NUMBER := 0;
   v_ap_idx_soma   NUMBER := 0;
   v_ap_idx_count  NUMBER := 0;

   v_ap_mag_soma   NUMBER :=  0;
   v_ap_mag_min    NUMBER :=  999999;
   v_ap_mag_max    NUMBER := -999999;
   v_ap_mag_count  NUMBER :=  0;
   v_ap_mag_lt2k   NUMBER :=  0;
   v_ap_mag_ge2k   NUMBER :=  0;

   v_total         NUMBER := 0;

   FUNCTION fmt(
      p_id     NUMBER, p_qtde   NUMBER,
      p_d1     NUMBER, p_d2     NUMBER,
      p_dev    NUMBER, p_min    NUMBER, p_max    NUMBER,
      p_par    NUMBER, p_idx_ab NUMBER,
      p_mag_ab NUMBER, p_m_ab   NUMBER,
      p_extra  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2 IS
      v_ab VARCHAR2(80);
   BEGIN
      IF p_idx_ab = -1 THEN
         v_ab := 'IDX_AB=SEM  MAG=    0  M_AB=    -';
      ELSE
         v_ab := 'IDX_AB=' || LPAD(TO_CHAR(p_idx_ab, 'FM99'),    4) ||
                 '  MAG='  || LPAD(TO_CHAR(p_mag_ab, 'FM999990'), 7) ||
                 '  M_AB=' || LPAD(TO_CHAR(p_m_ab,  'FM99990'),   6);
      END IF;
      RETURN
         'ID='    || LPAD(TO_CHAR(p_id),  10) ||
         ' (x'   || LPAD(TO_CHAR(p_qtde),  3) || ')' ||
         ' D1='  || LPAD(TO_CHAR(p_d1,  'FM999990.99'), 7) ||
         ' D2='  || LPAD(TO_CHAR(p_d2,  'FM999990.99'), 8) ||
         ' DEV=' || LPAD(TO_CHAR(p_dev, 'FM999990.99'), 8) ||
         ' MIN=' || LPAD(TO_CHAR(p_min, 'FM999990'),    7) ||
         CASE WHEN p_extra IS NOT NULL THEN '  >> ' || p_extra END ||
         CHR(10) ||
         '       PAR=' || LPAD(NVL(TO_CHAR(p_par), '-'), 5) || '  ' || v_ab;
   END fmt;

BEGIN
   DBMS_OUTPUT.PUT_LINE('[BLK_Q1_TENDENCIA] Iniciando filtragem Q1 — TENDÊNCIA GENUÍNA');
   DBMS_OUTPUT.PUT_LINE('[BLK_Q1_TENDENCIA] Referência: ' || TO_CHAR(SYSDATE-1,'DD/MM/YYYY') || ' 18h–19h');
   DBMS_OUTPUT.PUT_LINE('[BLK_Q1_TENDENCIA] v11 — cursor:D1>=-200 | P1(D2>=-400) P5(IDX!=-1) P6(MAG<=-2000) P7(M_AB>=6000)');

   FOR r IN c_q1 LOOP
      v_total := v_total + 1;

      -- P1: D2 >= -400 — rejeita apenas forte desaceleração extrema
      -- v11 2026-05-16: alargado de -300 para -400
      --   Diagnóstico: 12693149(D2=-359) e 12693508(D2=-399) eram winners e falhavam em -300
      --   D2 entre -400 e -300: órbitas com desaceleração moderada → incluídas a partir de v11
      --   D2 < -400: desaceleração extrema — padrão inconsistente com tendência genuína
      IF r.v_d2_media < -400 THEN
         v_p1(v_p1.COUNT+1) := fmt(
            r.v_id_repr, r.v_qtde_milhares,
            r.v_d1_media, r.v_d2_media, r.v_d1_desvio, r.v_d1_min, r.v_d1_max,
            r.v_milhar_parada, r.v_idx_abismo, r.v_mag_abismo, r.v_milhar_abismo,
            'D2='||TO_CHAR(r.v_d2_media,'FM999990.99')||' < -400 (desacel. extrema)');
         CONTINUE;
      END IF;

      -- P5: abismo confirmado (IDX=-1 = sem abismo)
      -- 100% dos winners têm abismo. Sem abismo → descarta.
      IF r.v_idx_abismo = -1 THEN
         v_p5(v_p5.COUNT+1) := fmt(
            r.v_id_repr, r.v_qtde_milhares,
            r.v_d1_media, r.v_d2_media, r.v_d1_desvio, r.v_d1_min, r.v_d1_max,
            r.v_milhar_parada, r.v_idx_abismo, r.v_mag_abismo, r.v_milhar_abismo,
            'SEM ABISMO — winners sempre têm abismo confirmado');
         CONTINUE;
      END IF;

      -- P6: queda profunda obrigatória (MAG <= -2000)
      -- 100% dos winners têm MAG <= -3809. MAG > -2000 = queda suave ou positiva → descarta.
      IF r.v_mag_abismo > -2000 THEN
         v_p6(v_p6.COUNT+1) := fmt(
            r.v_id_repr, r.v_qtde_milhares,
            r.v_d1_media, r.v_d2_media, r.v_d1_desvio, r.v_d1_min, r.v_d1_max,
            r.v_milhar_parada, r.v_idx_abismo, r.v_mag_abismo, r.v_milhar_abismo,
            'MAG='||TO_CHAR(r.v_mag_abismo,'FM999990')||' > -2000 (queda suave/positiva)');
         CONTINUE;
      END IF;

      -- P7: milhar alto no abismo (M_AB >= 6000)
      -- 100% dos winners têm M_AB >= 6020. M_AB < 6000 = padrão de não-winner.
      IF r.v_milhar_abismo IS NOT NULL AND r.v_milhar_abismo < 6000 THEN
         v_p7(v_p7.COUNT+1) := fmt(
            r.v_id_repr, r.v_qtde_milhares,
            r.v_d1_media, r.v_d2_media, r.v_d1_desvio, r.v_d1_min, r.v_d1_max,
            r.v_milhar_parada, r.v_idx_abismo, r.v_mag_abismo, r.v_milhar_abismo,
            'M_AB='||TO_CHAR(r.v_milhar_abismo,'FM99990')||' < 6000');
         CONTINUE;
      END IF;

      -- ── APROVADO ──────────────────────────────────────────────────────────
      v_ap(v_ap.COUNT+1) := fmt(
         r.v_id_repr, r.v_qtde_milhares,
         r.v_d1_media, r.v_d2_media, r.v_d1_desvio, r.v_d1_min, r.v_d1_max,
         r.v_milhar_parada, r.v_idx_abismo, r.v_mag_abismo, r.v_milhar_abismo);

      -- Acumula estatísticas
      IF r.v_milhar_parada IS NOT NULL THEN
         v_iter_key := LPAD(TO_CHAR(r.v_milhar_parada), 6, '0');
         IF v_par_freq.EXISTS(v_iter_key) THEN v_par_freq(v_iter_key) := v_par_freq(v_iter_key)+1;
         ELSE v_par_freq(v_iter_key) := 1; END IF;
      END IF;

      IF    r.v_idx_abismo = -1  THEN v_ap_idx_sem    := v_ap_idx_sem    + 1;
      ELSIF r.v_idx_abismo <= 5  THEN v_ap_idx_1_5    := v_ap_idx_1_5    + 1; v_ap_idx_soma := v_ap_idx_soma + r.v_idx_abismo; v_ap_idx_count := v_ap_idx_count + 1;
      ELSIF r.v_idx_abismo <= 10 THEN v_ap_idx_6_10   := v_ap_idx_6_10   + 1; v_ap_idx_soma := v_ap_idx_soma + r.v_idx_abismo; v_ap_idx_count := v_ap_idx_count + 1;
      ELSE                            v_ap_idx_11plus := v_ap_idx_11plus  + 1; v_ap_idx_soma := v_ap_idx_soma + r.v_idx_abismo; v_ap_idx_count := v_ap_idx_count + 1;
      END IF;

      IF r.v_idx_abismo >= 0 THEN
         v_ap_mag_count := v_ap_mag_count + 1;
         v_ap_mag_soma  := v_ap_mag_soma  + r.v_mag_abismo;
         IF r.v_mag_abismo < v_ap_mag_min THEN v_ap_mag_min := r.v_mag_abismo; END IF;
         IF r.v_mag_abismo > v_ap_mag_max THEN v_ap_mag_max := r.v_mag_abismo; END IF;
         IF ABS(r.v_mag_abismo) < 2000 THEN v_ap_mag_lt2k := v_ap_mag_lt2k+1; ELSE v_ap_mag_ge2k := v_ap_mag_ge2k+1; END IF;
      END IF;

      IF r.v_milhar_abismo IS NOT NULL AND r.v_idx_abismo >= 0 THEN
         v_iter_key := LPAD(TO_CHAR(r.v_milhar_abismo), 6, '0');
         IF v_mab_freq.EXISTS(v_iter_key) THEN v_mab_freq(v_iter_key) := v_mab_freq(v_iter_key)+1;
         ELSE v_mab_freq(v_iter_key) := 1; END IF;
      END IF;
   END LOOP;

   -- ============================================================
   -- SEÇÃO 1: LISTAGEM
   -- ============================================================
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════════════');
   DBMS_OUTPUT.PUT_LINE('[BLK_Q1] TOTAL CORRIDAS LIDAS : ' || v_total);
   DBMS_OUTPUT.PUT_LINE('══════════════════════════════════════════════════════');

   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('--- APROVADOS (' || v_ap.COUNT || ' corridas) ---');
   FOR i IN 1..v_ap.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('[AP ] ' || v_ap(i));
   END LOOP;

   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('--- REJEIT. P1 D2<-400 desacel.extrema (' || v_p1.COUNT || ' corridas) ---');
   FOR i IN 1..v_p1.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('[P1 ] ' || v_p1(i));
   END LOOP;

   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('--- REJEIT. P5 SEM ABISMO (' || v_p5.COUNT || ' corridas) ---');
   FOR i IN 1..v_p5.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('[P5 ] ' || v_p5(i));
   END LOOP;

   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('--- REJEIT. P6 QUEDA SUAVE MAG>-2000 (' || v_p6.COUNT || ' corridas) ---');
   FOR i IN 1..v_p6.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('[P6 ] ' || v_p6(i));
   END LOOP;

   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('--- REJEIT. P7 M_AB<6000 (' || v_p7.COUNT || ' corridas) ---');
   FOR i IN 1..v_p7.COUNT LOOP
      DBMS_OUTPUT.PUT_LINE('[P7 ] ' || v_p7(i));
   END LOOP;

   -- ============================================================
   -- SEÇÃO 2: ANÁLISE ESTATÍSTICA
   -- ============================================================
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════╗');
   DBMS_OUTPUT.PUT_LINE('║  ANÁLISE ESTATÍSTICA — APROVADOS (' || LPAD(v_ap.COUNT,3) || ' corridas)      ║');
   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   DBMS_OUTPUT.PUT_LINE('║  Q2 — IDX_ABISMO                                    ║');
   DBMS_OUTPUT.PUT_LINE('║    Sem abismo  (IDX=-1) : ' || LPAD(v_ap_idx_sem,   3) || ' (' || LPAD(ROUND(100*v_ap_idx_sem   /NULLIF(v_ap.COUNT,0)),3) || '%)                   ║');
   DBMS_OUTPUT.PUT_LINE('║    Abismo cedo (1–5)    : ' || LPAD(v_ap_idx_1_5,   3) || ' (' || LPAD(ROUND(100*v_ap_idx_1_5  /NULLIF(v_ap.COUNT,0)),3) || '%)                   ║');
   DBMS_OUTPUT.PUT_LINE('║    Abismo médio(6–10)   : ' || LPAD(v_ap_idx_6_10,  3) || ' (' || LPAD(ROUND(100*v_ap_idx_6_10 /NULLIF(v_ap.COUNT,0)),3) || '%)                   ║');
   DBMS_OUTPUT.PUT_LINE('║    Abismo tardio(>10)   : ' || LPAD(v_ap_idx_11plus, 3) || ' (' || LPAD(ROUND(100*v_ap_idx_11plus/NULLIF(v_ap.COUNT,0)),3) || '%)                   ║');
   IF v_ap_idx_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('║    IDX médio            : ' || LPAD(ROUND(v_ap_idx_soma/v_ap_idx_count,1), 5) || '                              ║');
   END IF;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');
   DBMS_OUTPUT.PUT_LINE('║  Q3 — MAGNITUDE_ABISMO                              ║');
   IF v_ap_mag_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('║    Count c/ abismo      : ' || LPAD(v_ap_mag_count, 3) || '                              ║');
      DBMS_OUTPUT.PUT_LINE('║    Mínima (mais profunda): ' || LPAD(v_ap_mag_min,   7) || '                         ║');
      DBMS_OUTPUT.PUT_LINE('║    Máxima (mais suave)  : ' || LPAD(v_ap_mag_max,   7) || '                         ║');
      DBMS_OUTPUT.PUT_LINE('║    Média                : ' || LPAD(ROUND(v_ap_mag_soma/v_ap_mag_count,0), 7) || '                         ║');
      DBMS_OUTPUT.PUT_LINE('║    Queda suave |MAG|<2k : ' || LPAD(v_ap_mag_lt2k,  3) || '                              ║');
      DBMS_OUTPUT.PUT_LINE('║    Queda profunda >=2k  : ' || LPAD(v_ap_mag_ge2k,  3) || '                              ║');
   END IF;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');
   DBMS_OUTPUT.PUT_LINE('║  Q1 — MILHAR_NA_PARADA (PAR)                        ║');
   v_iter_key := v_par_freq.FIRST;
   WHILE v_iter_key IS NOT NULL LOOP
      DBMS_OUTPUT.PUT_LINE('║    PAR=' || LPAD(TO_CHAR(TO_NUMBER(v_iter_key)),5) || '  ' || v_par_freq(v_iter_key) || 'x                                        ║');
      v_iter_key := v_par_freq.NEXT(v_iter_key);
   END LOOP;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');
   DBMS_OUTPUT.PUT_LINE('║  Q4 — MILHAR_NO_ABISMO (M_AB)                       ║');
   v_iter_key := v_mab_freq.FIRST;
   WHILE v_iter_key IS NOT NULL LOOP
      DBMS_OUTPUT.PUT_LINE('║    M_AB=' || LPAD(TO_CHAR(TO_NUMBER(v_iter_key)),5) || '  ' || v_mab_freq(v_iter_key) || 'x                                       ║');
      v_iter_key := v_mab_freq.NEXT(v_iter_key);
   END LOOP;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');
   DBMS_OUTPUT.PUT_LINE('║  RESUMO                                              ║');
   DBMS_OUTPUT.PUT_LINE('║  Total lido : ' || LPAD(v_total,   4) || '   Aprovados: ' || LPAD(v_ap.COUNT,4) || '                   ║');
   DBMS_OUTPUT.PUT_LINE('║  P1(D2<-400): ' || LPAD(v_p1.COUNT, 3) || '   P5(s/abismo): ' || LPAD(v_p5.COUNT,3) || '                  ║');
   DBMS_OUTPUT.PUT_LINE('║  P6(MAG>-2k): ' || LPAD(v_p6.COUNT,3) || '   P7(M_AB<6k): ' || LPAD(v_p7.COUNT,4) || '                  ║');
   DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════╝');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[BLK_Q1_TENDENCIA] Erro: ' || SQLERRM);
      RAISE;
END;
/
