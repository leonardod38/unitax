-- Tipo   : BLOCO ANÔNIMO
-- Objeto : blk_q2_calculadores_analise
-- Salvo  : 2026-05-16
-- Origem : Análise exploratória — calculadores de nível 1 disponíveis no ORBITAS_TABELAO1
-- Objetivo: calibrar filtros do Q2 respondendo por comparação de 3 runs:
--   Q-PLATO : PLATO_ABISMO.encontrado/intensidade/velocidade
--   Q-GRAD  : GRADIENTE_FINAL.grad_chegada (SUBINDO/DESCENDO) e grad_acelerad (S/N)
--   Q-ZONA  : ZONA__DESTINO — qual zona alvo domina nos premiados
--   Q-CONV  : CONVERGENCIA.monotonica e perc_aproximacao
--   Q-MOM   : MOMENTUM.acelerando (S/N)
--   Q-REG   : REGRESSAO_LINEAR.tendencia (SUBINDO/DESCENDO/LATERAL)
--   Q-DIST  : DIST_RES_PLATO.pousa_perto (S/N)
-- Metodologia: mesmos 3 runs do blk_q2_polinomios_analise.sql
--   Run 1: d-30 sem premio → padrao nao-premiados
--   Run 2: d-30 com premio → padrao premiados
--   Run 3: dia normal      → padrao misto
-- Base: mesmos 275 aprovados do Q1 (filtros embutidos no cursor via CTE)
-- ------------------------------------------------------------
DECLARE
   -- Cursor: Q1 embutido → JOIN nos calculadores adicionais
   CURSOR c_q2 IS
      WITH q1_base AS (
         SELECT MIN(T3.ID_DADOS_ORBITA) AS id_repr
           FROM DADOS_ORBITA     DD
           JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
          WHERE DD.TIMESTAMP_EXECUCAO_INS >= TRUNC(SYSDATE - 1) + 18/24
            AND DD.TIMESTAMP_EXECUCAO_INS <  TRUNC(SYSDATE - 1) + 19/24
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
           -- D1/D2 para referência
           , STR_PARA_NUMERO(P.DERIVADAS__D1_MEDIA)  AS v_d1
           , STR_PARA_NUMERO(P.DERIVADAS__D2_MEDIA)  AS v_d2
           -- PLATO_ABISMO
           , P.PLATO_ABISMO__ENCONTRADO              AS v_plato_enc
           , P.PLATO_ABISMO__INTENSIDADE             AS v_plato_int
           , P.PLATO_ABISMO__VELOCIDADE              AS v_plato_vel
           , STR_PARA_NUMERO(P.PLATO_ABISMO__MILHAR_DESTINO) AS v_plato_dest
           , STR_PARA_NUMERO(P.PLATO_ABISMO__MAGNITUDE)      AS v_plato_mag
           -- GRADIENTE_FINAL
           , P.GRADIENTE_FINAL__GRAD_CHEGADA         AS v_grad_cheg
           , P.GRADIENTE_FINAL__GRAD_ACELERAD        AS v_grad_acel
           , STR_PARA_NUMERO(P.GRADIENTE_FINAL__GRAD_SLOPE_FI) AS v_grad_slope
           , STR_PARA_NUMERO(P.GRADIENTE_FINAL__GRAD_VEL_MEDI) AS v_grad_vel
           -- ZONA
           , P.ZONA__DESTINO                         AS v_zona_dest
           -- CONVERGENCIA
           , P.CONVERGENCIA__MONOTONICA              AS v_conv_mono
           , STR_PARA_NUMERO(P.CONVERGENCIA__PERC_APROXIMACAO) AS v_conv_perc
           -- MOMENTUM
           , P.MOMENTUM__ACELERANDO                  AS v_mom_acel
           , STR_PARA_NUMERO(P.MOMENTUM__MOMENTUM)   AS v_momentum
           -- REGRESSAO_LINEAR
           , P.REGRESSAO_LINEAR__TENDENCIA           AS v_reg_tend
           -- DIST_RES_PLATO
           , P.DIST_RES_PLATO__POUSA_PERTO           AS v_pousa_perto
           , STR_PARA_NUMERO(P.DIST_RES_PLATO__DIST_RES_PLATO) AS v_dist_plato
        FROM q1_base
        JOIN ORBITAS_TABELAO1 P ON P.ID_DADOS_ORBITA = q1_base.id_repr
       ORDER BY STR_PARA_NUMERO(P.DERIVADAS__D1_MEDIA) DESC;

   v_total   NUMBER := 0;

   -- Q-PLATO: PLATO_ABISMO
   v_plato_s   NUMBER := 0;   -- encontrado = S
   v_plato_n   NUMBER := 0;   -- encontrado = N
   v_plato_ext NUMBER := 0;   -- intensidade EXTREMA
   v_plato_alt NUMBER := 0;   -- intensidade ALTA
   v_plato_med NUMBER := 0;   -- intensidade MEDIA
   v_plato_bai NUMBER := 0;   -- intensidade BAIXA
   v_plato_len NUMBER := 0;   -- velocidade LENTO
   v_plato_nor NUMBER := 0;   -- velocidade NORMAL
   v_plato_rap NUMBER := 0;   -- velocidade RAPIDO

   -- Q-GRAD: GRADIENTE_FINAL
   v_grad_sub    NUMBER := 0;   -- grad_chegada SUBINDO
   v_grad_des    NUMBER := 0;   -- grad_chegada DESCENDO
   v_grad_lat    NUMBER := 0;   -- grad_chegada LATERAL
   v_grad_acel_s NUMBER := 0;   -- grad_acelerad S
   v_grad_acel_n NUMBER := 0;   -- grad_acelerad N
   v_grad_slope_soma NUMBER := 0;
   v_grad_slope_min  NUMBER :=  9999999;
   v_grad_slope_max  NUMBER := -9999999;
   v_grad_vel_soma   NUMBER := 0;
   v_grad_count      NUMBER := 0;

   -- Q-ZONA: tabela de frequência por zona destino
   TYPE t_freq IS TABLE OF NUMBER INDEX BY VARCHAR2(5);
   v_zona_freq  t_freq;
   v_iter_key   VARCHAR2(5);

   -- Q-CONV: CONVERGENCIA
   v_conv_s          NUMBER := 0;
   v_conv_n          NUMBER := 0;
   v_conv_perc_soma  NUMBER := 0;
   v_conv_perc_min   NUMBER :=  999;
   v_conv_perc_max   NUMBER := -999;
   v_conv_count      NUMBER := 0;

   -- Q-MOM: MOMENTUM
   v_mom_s  NUMBER := 0;
   v_mom_n  NUMBER := 0;
   v_mom_pos NUMBER := 0;   -- momentum > 0
   v_mom_neg NUMBER := 0;   -- momentum < 0

   -- Q-REG: REGRESSAO_LINEAR.tendencia
   v_reg_sub NUMBER := 0;
   v_reg_des NUMBER := 0;
   v_reg_lat NUMBER := 0;
   v_reg_out NUMBER := 0;

   -- Q-DIST: DIST_RES_PLATO
   v_dist_s  NUMBER := 0;
   v_dist_n  NUMBER := 0;
   v_dist_soma NUMBER := 0;
   v_dist_min  NUMBER :=  9999999;
   v_dist_max  NUMBER := -9999999;
   v_dist_count NUMBER := 0;

BEGIN
   DBMS_OUTPUT.PUT_LINE('[BLK_Q2_CALC] Análise: PLATO_ABISMO + GRADIENTE_FINAL + correlatos');
   DBMS_OUTPUT.PUT_LINE('[BLK_Q2_CALC] Referência: ' || TO_CHAR(SYSDATE-1,'DD/MM/YYYY') || ' 18h–19h');
   DBMS_OUTPUT.PUT_LINE('[BLK_Q2_CALC] Base Q1: D1>=100 | D2>=-300 | IDX!=-1 | MAG<=-2000 | M_AB>=6000');

   FOR r IN c_q2 LOOP
      v_total := v_total + 1;

      -- Linha por corrida (compacta)
      DBMS_OUTPUT.PUT_LINE(
         '[Q2] ID='     || LPAD(TO_CHAR(r.ID_DADOS_ORBITA), 10) ||
         ' D1='         || LPAD(TO_CHAR(r.v_d1,  'FM999990.99'), 7) ||
         ' D2='         || LPAD(TO_CHAR(r.v_d2,  'FM999990.99'), 8) ||
         ' | PL='       || RPAD(NVL(r.v_plato_enc,'-'), 1) ||
         '/' || RPAD(NVL(r.v_plato_int,'-'), 7) ||
         '/' || RPAD(NVL(r.v_plato_vel,'-'), 6) ||
         ' | GR='       || RPAD(NVL(r.v_grad_cheg,'-'), 8) ||
         '/' || RPAD(NVL(r.v_grad_acel,'-'), 1) ||
         ' | Z='        || RPAD(NVL(r.v_zona_dest,'-'), 2) ||
         ' MOM='        || RPAD(NVL(r.v_mom_acel,'-'), 1) ||
         ' REG='        || RPAD(NVL(r.v_reg_tend,'-'), 8) ||
         ' PERTO='      || NVL(r.v_pousa_perto,'-')
      );

      -- Q-PLATO
      IF r.v_plato_enc = 'S' THEN v_plato_s := v_plato_s + 1;
                              ELSE v_plato_n := v_plato_n + 1; END IF;
      IF    r.v_plato_int = 'EXTREMA' THEN v_plato_ext := v_plato_ext + 1;
      ELSIF r.v_plato_int = 'ALTA'    THEN v_plato_alt := v_plato_alt + 1;
      ELSIF r.v_plato_int = 'MEDIA'   THEN v_plato_med := v_plato_med + 1;
      ELSIF r.v_plato_int = 'BAIXA'   THEN v_plato_bai := v_plato_bai + 1;
      END IF;
      IF    r.v_plato_vel = 'LENTO'   THEN v_plato_len := v_plato_len + 1;
      ELSIF r.v_plato_vel = 'NORMAL'  THEN v_plato_nor := v_plato_nor + 1;
      ELSIF r.v_plato_vel = 'RAPIDO'  THEN v_plato_rap := v_plato_rap + 1;
      END IF;

      -- Q-GRAD
      IF    r.v_grad_cheg = 'SUBINDO'  THEN v_grad_sub := v_grad_sub + 1;
      ELSIF r.v_grad_cheg = 'DESCENDO' THEN v_grad_des := v_grad_des + 1;
      ELSE                                   v_grad_lat := v_grad_lat + 1;
      END IF;
      IF r.v_grad_acel = 'S' THEN v_grad_acel_s := v_grad_acel_s + 1;
                              ELSE v_grad_acel_n := v_grad_acel_n + 1; END IF;
      IF r.v_grad_slope IS NOT NULL THEN
         v_grad_count     := v_grad_count + 1;
         v_grad_slope_soma := v_grad_slope_soma + r.v_grad_slope;
         v_grad_vel_soma   := v_grad_vel_soma   + NVL(r.v_grad_vel, 0);
         IF r.v_grad_slope < v_grad_slope_min THEN v_grad_slope_min := r.v_grad_slope; END IF;
         IF r.v_grad_slope > v_grad_slope_max THEN v_grad_slope_max := r.v_grad_slope; END IF;
      END IF;

      -- Q-ZONA
      IF r.v_zona_dest IS NOT NULL THEN
         v_iter_key := r.v_zona_dest;
         IF v_zona_freq.EXISTS(v_iter_key) THEN
            v_zona_freq(v_iter_key) := v_zona_freq(v_iter_key) + 1;
         ELSE
            v_zona_freq(v_iter_key) := 1;
         END IF;
      END IF;

      -- Q-CONV
      IF r.v_conv_mono = 'S' THEN v_conv_s := v_conv_s + 1;
                              ELSE v_conv_n := v_conv_n + 1; END IF;
      IF r.v_conv_perc IS NOT NULL THEN
         v_conv_count     := v_conv_count + 1;
         v_conv_perc_soma := v_conv_perc_soma + r.v_conv_perc;
         IF r.v_conv_perc < v_conv_perc_min THEN v_conv_perc_min := r.v_conv_perc; END IF;
         IF r.v_conv_perc > v_conv_perc_max THEN v_conv_perc_max := r.v_conv_perc; END IF;
      END IF;

      -- Q-MOM
      IF r.v_mom_acel = 'S' THEN v_mom_s := v_mom_s + 1;
                             ELSE v_mom_n := v_mom_n + 1; END IF;
      IF NVL(r.v_momentum, 0) > 0 THEN v_mom_pos := v_mom_pos + 1;
                                   ELSE v_mom_neg := v_mom_neg + 1; END IF;

      -- Q-REG
      IF    r.v_reg_tend = 'SUBINDO'  THEN v_reg_sub := v_reg_sub + 1;
      ELSIF r.v_reg_tend = 'DESCENDO' THEN v_reg_des := v_reg_des + 1;
      ELSIF r.v_reg_tend = 'LATERAL'  THEN v_reg_lat := v_reg_lat + 1;
      ELSE                                  v_reg_out := v_reg_out + 1;
      END IF;

      -- Q-DIST
      IF r.v_pousa_perto = 'S' THEN v_dist_s := v_dist_s + 1;
                                ELSE v_dist_n := v_dist_n + 1; END IF;
      IF r.v_dist_plato IS NOT NULL THEN
         v_dist_count := v_dist_count + 1;
         v_dist_soma  := v_dist_soma  + r.v_dist_plato;
         IF r.v_dist_plato < v_dist_min THEN v_dist_min := r.v_dist_plato; END IF;
         IF r.v_dist_plato > v_dist_max THEN v_dist_max := r.v_dist_plato; END IF;
      END IF;
   END LOOP;

   -- ============================================================
   -- SEÇÃO ANÁLISE — compare entre os 3 runs
   -- ============================================================
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('╔══════════════════════════════════════════════════════╗');
   DBMS_OUTPUT.PUT_LINE('║  ANÁLISE CALCULADORES — BASE Q1 (' || LPAD(v_total,3) || ' corridas)     ║');
   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-PLATO
   DBMS_OUTPUT.PUT_LINE('║  Q-PLATO: PLATO_ABISMO (padrão platô-abismo)        ║');
   DBMS_OUTPUT.PUT_LINE('║    Encontrado  S : ' || LPAD(v_plato_s,3) || ' (' || LPAD(ROUND(100*v_plato_s/NULLIF(v_total,0)),3) || '%)  N: ' || LPAD(v_plato_n,3) || ' (' || LPAD(ROUND(100*v_plato_n/NULLIF(v_total,0)),3) || '%)    ║');
   DBMS_OUTPUT.PUT_LINE('║    Intensidade → EXTREMA:' || LPAD(v_plato_ext,3) || '  ALTA:' || LPAD(v_plato_alt,3) || '  MEDIA:' || LPAD(v_plato_med,3) || '  BAIXA:' || LPAD(v_plato_bai,3) || ' ║');
   DBMS_OUTPUT.PUT_LINE('║    Velocidade  → LENTO:' || LPAD(v_plato_len,3) || '  NORMAL:' || LPAD(v_plato_nor,3) || '  RAPIDO:' || LPAD(v_plato_rap,3) || '          ║');

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-GRAD
   DBMS_OUTPUT.PUT_LINE('║  Q-GRAD: GRADIENTE_FINAL (direção e aceleração final)║');
   DBMS_OUTPUT.PUT_LINE('║    grad_chegada → SUBINDO : ' || LPAD(v_grad_sub,3) || ' (' || LPAD(ROUND(100*v_grad_sub/NULLIF(v_total,0)),3) || '%)              ║');
   DBMS_OUTPUT.PUT_LINE('║    grad_chegada → DESCENDO: ' || LPAD(v_grad_des,3) || ' (' || LPAD(ROUND(100*v_grad_des/NULLIF(v_total,0)),3) || '%)              ║');
   DBMS_OUTPUT.PUT_LINE('║    grad_chegada → LATERAL : ' || LPAD(v_grad_lat,3) || ' (' || LPAD(ROUND(100*v_grad_lat/NULLIF(v_total,0)),3) || '%)              ║');
   DBMS_OUTPUT.PUT_LINE('║    grad_acelerad → S: ' || LPAD(v_grad_acel_s,3) || ' (' || LPAD(ROUND(100*v_grad_acel_s/NULLIF(v_total,0)),3) || '%)  N: ' || LPAD(v_grad_acel_n,3) || ' (' || LPAD(ROUND(100*v_grad_acel_n/NULLIF(v_total,0)),3) || '%)   ║');
   IF v_grad_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('║    Slope médio: ' || LPAD(TO_CHAR(ROUND(v_grad_slope_soma/v_grad_count,1),'FM999990.9'),9) ||
                           '  Vel. média: ' || LPAD(TO_CHAR(ROUND(v_grad_vel_soma/v_grad_count,1),'FM999990.9'),9) || ' ║');
   END IF;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-ZONA
   DBMS_OUTPUT.PUT_LINE('║  Q-ZONA: ZONA__DESTINO (zona alvo da série)         ║');
   v_iter_key := v_zona_freq.FIRST;
   WHILE v_iter_key IS NOT NULL LOOP
      DBMS_OUTPUT.PUT_LINE('║    ' || RPAD(v_iter_key,4) || ': ' || LPAD(v_zona_freq(v_iter_key),3) || ' (' || LPAD(ROUND(100*v_zona_freq(v_iter_key)/NULLIF(v_total,0)),3) || '%)                       ║');
      v_iter_key := v_zona_freq.NEXT(v_iter_key);
   END LOOP;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-CONV
   DBMS_OUTPUT.PUT_LINE('║  Q-CONV: CONVERGENCIA (convergência ao destino)     ║');
   DBMS_OUTPUT.PUT_LINE('║    Monotonica → S: ' || LPAD(v_conv_s,3) || ' (' || LPAD(ROUND(100*v_conv_s/NULLIF(v_total,0)),3) || '%)  N: ' || LPAD(v_conv_n,3) || ' (' || LPAD(ROUND(100*v_conv_n/NULLIF(v_total,0)),3) || '%)    ║');
   IF v_conv_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('║    Perc_aprox → média: ' || LPAD(TO_CHAR(ROUND(v_conv_perc_soma/v_conv_count,3),'FM0.999'),6) ||
                           '  mín: ' || LPAD(TO_CHAR(ROUND(v_conv_perc_min,3),'FM0.999'),6) ||
                           '  máx: ' || LPAD(TO_CHAR(ROUND(v_conv_perc_max,3),'FM0.999'),6) || '  ║');
   END IF;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-MOM
   DBMS_OUTPUT.PUT_LINE('║  Q-MOM: MOMENTUM.acelerando                         ║');
   DBMS_OUTPUT.PUT_LINE('║    Acelerando → S: ' || LPAD(v_mom_s,3) || ' (' || LPAD(ROUND(100*v_mom_s/NULLIF(v_total,0)),3) || '%)  N: ' || LPAD(v_mom_n,3) || ' (' || LPAD(ROUND(100*v_mom_n/NULLIF(v_total,0)),3) || '%)    ║');
   DBMS_OUTPUT.PUT_LINE('║    Momentum valor → pos: ' || LPAD(v_mom_pos,3) || ' (' || LPAD(ROUND(100*v_mom_pos/NULLIF(v_total,0)),3) || '%)  neg: ' || LPAD(v_mom_neg,3) || ' (' || LPAD(ROUND(100*v_mom_neg/NULLIF(v_total,0)),3) || '%) ║');

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-REG
   DBMS_OUTPUT.PUT_LINE('║  Q-REG: REGRESSAO_LINEAR.tendencia                  ║');
   DBMS_OUTPUT.PUT_LINE('║    SUBINDO : ' || LPAD(v_reg_sub,3) || ' (' || LPAD(ROUND(100*v_reg_sub/NULLIF(v_total,0)),3) || '%)                       ║');
   DBMS_OUTPUT.PUT_LINE('║    DESCENDO: ' || LPAD(v_reg_des,3) || ' (' || LPAD(ROUND(100*v_reg_des/NULLIF(v_total,0)),3) || '%)                       ║');
   DBMS_OUTPUT.PUT_LINE('║    LATERAL : ' || LPAD(v_reg_lat,3) || ' (' || LPAD(ROUND(100*v_reg_lat/NULLIF(v_total,0)),3) || '%)                       ║');

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');

   -- Q-DIST
   DBMS_OUTPUT.PUT_LINE('║  Q-DIST: DIST_RES_PLATO.pousa_perto                 ║');
   DBMS_OUTPUT.PUT_LINE('║    Pousa perto → S: ' || LPAD(v_dist_s,3) || ' (' || LPAD(ROUND(100*v_dist_s/NULLIF(v_total,0)),3) || '%)  N: ' || LPAD(v_dist_n,3) || ' (' || LPAD(ROUND(100*v_dist_n/NULLIF(v_total,0)),3) || '%)   ║');
   IF v_dist_count > 0 THEN
      DBMS_OUTPUT.PUT_LINE('║    Distância → média: ' || LPAD(TO_CHAR(ROUND(v_dist_soma/v_dist_count,0),'FM999990'),6) ||
                           '  mín: ' || LPAD(TO_CHAR(ROUND(v_dist_min,0),'FM999990'),6) ||
                           '  máx: ' || LPAD(TO_CHAR(ROUND(v_dist_max,0),'FM999990'),6) || '  ║');
   END IF;

   DBMS_OUTPUT.PUT_LINE('╠══════════════════════════════════════════════════════╣');
   DBMS_OUTPUT.PUT_LINE('║  RESUMO                                              ║');
   DBMS_OUTPUT.PUT_LINE('║  Base Q1 analisada : ' || LPAD(v_total,4) || ' corridas                    ║');
   DBMS_OUTPUT.PUT_LINE('╚══════════════════════════════════════════════════════╝');

EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('[BLK_Q2_CALC] Erro: ' || SQLERRM);
      RAISE;
END;
/
