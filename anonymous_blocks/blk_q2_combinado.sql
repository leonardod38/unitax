-- Tipo   : BLOCO ANÔNIMO
-- Objeto : blk_q2_combinado
-- Salvo  : 2026-05-17
-- v2     : Q1 CTE atualizada para v11 (D1>=-200, D2>=-400) — sync com blk_q1_tendencia_filtros v11
-- v3     : C4a e C4b adicionados — análise Python dentro do C2 → atinge 8:1 (META 10:1)
-- v4     : Refinamento via queries Oracle sobre 6 IDs C4a (1W+5NW):
--          C4b DESCARTADO (0 winners em d-30 sem prêmio)
--          C4a_v2 = C4a + grad_cheg=DESCENDO → ratio 1:1 (elimina 4/5 NW; 1 NW idêntico ao winner)
--          C4c    = C2 + PLATICURTICA + vol=IRREGULAR → captura 2 winners que C4a perdia
--          C4c2   = C4c + zona_plato=zona_dest        → 3:1 validado (4 cands/dia)
--          C4c3   = C4c2 + zona_plato='Z2'            → ratio 1:1 potencial (Z2->Z2 apenas)
--          Limite físico: 1 NW com features idênticas ao winner → irreducível
-- v5     : C5 — primeira tentativa T2 (DESCARTADA em v6):
--          rank_g15 e balanco_f calibrados no pool GLOBAL invertiam dentro do C4c
--          rank_g15>=0.45: 71:1 dentro C4c (pior que sem filtro) — eliminava 2/3 dos W
--          balanco_f<0:    57:1 dentro C4c — mesmo problema
-- v9     : C4r — Arquétipo C (winners invisíveis: sem F10 E sem F11)
--          Análise Python analise_arquetipo_c.py — 7 dias com winners C no histórico:
--            41% dos winners totais são arquétipo C (15/37) — maior grupo!
--            betti_0 captura winner C em top-1 em 6/7 dias (exceção: 14/05 betti=3.93)
--            Nenhuma combinação T1 atinge ratio<10:1 dentro do espaço C (pool 1903 NW)
--          C4r = Q1 + NOT F10 + NOT F11 → top-2 por betti_0 DESC
--          Cobre arquétipo C: plato_vel≠NORMAL, perc_iqr=S, passos curtos (mediana=6)
-- v8     : C3r em 2 passos — pré-filtro nmf_dom_fator=2 + ranking betti_0 DESC top-2
--          Análise Python analise_t2_ranking_c3.py — C3 exclusivo (F10+F11 sem F1):
--            nmf_dom_fator=2: winner sempre=2, NW_mean~1.6 → descarta ~30-40% NW com valor 1
--            betti_0 W>N: top1=75% dentro C3 excl. (menos que C4c 100% mas melhor que aleatório)
--          C3r = C3 (F10+F11) + nmf_dom_fator=2 → top-2 por betti_0 DESC
--          Cobre winners que C4c perde (passos<11, trajetória curta)
-- v7     : C5r — RANKING dentro do pool C4c diário por betti_0 (TOP-2 por dia)
--          Análise Python analise_t2_ranking.py — 3 dias com winner (09,13,16/mai)
--          Features com winner no TOP-1 em 100% dos dias:
--            presm_g22_front_betti_0  W>N  top1=100%  rank_med=1.0  (topologia: conexões)
--            presm_g22_front_betti_1  W>N  top1=100%  rank_med=1.0  (topologia: ciclos)
--            presm_g21_fis_estabilidade W<N top1=100% rank_med=1.0  (estabilidade física)
--            presm_g22_front_ocsvm_score W<N top1=100% rank_med=1.0 (anomalia OCSVM)
--          Estratégia: ordenar C4c por betti_0 DESC e apostar nos TOP-2 do dia
--          Vantagem: sem threshold fixo — adapta ao contexto de cada dia
--          C5a-d (thresholds fixos): mantidos como MONITORAMENTO — não validados em d-30
-- v6     : C5 recalibrado DENTRO DO POOL C4c (152 registros, 3W, 149NW — ORBITAS_TABELAO2_V1.csv)
--          Salvo  : 2026-05-17
--          Método: Python analise_t2_dentro_c4c.py — Cohen's d e scan de threshold no subpool
--          Top discriminantes dentro C4c (Cohen's d >> pool global):
--            presm_g21_fis_simetria_rotac  d=1.42  W=-0.549 N=-0.099  (W<N)
--            presm_g16_omega_coer_tempo    d=1.39  W=0.762  N=0.606   (W>N)
--            presm_g17_heurist_limiar      d=1.20  W=10.958 N=10.746  (W>N)
--            presm_g20_homog_local         d=1.15  W=0.550  N=0.645   (W<N)
--            presm_g22_front_betti_0       d=1.08  W=347    N=255     (W>N)
--          Filtros simples validados dentro C4c:
--            C5a = C4c + homog_local <= 0.587         → 11.7:1, recall=100% (3W/35NW)
--            C5b = C4c + coer_tempo  >= 0.804         → 8.5:1,  recall= 67% (2W/17NW)
--            C5c = C4c + heurist_limiar >= 10.930     → 13.3:1, recall=100% (3W/40NW)
--            C5d = C4c + homog_local<=0.568 & betti_0>=347.3 → 1.0:1, recall=67% *** META ***
-- Origem : Varredura Python calibrada DENTRO do pool Q1 (7.7k registros)
-- Problema resolvido: thresholds globais (13k) estavam invertidos dentro do Q1
-- Novos sinais calibrados dentro do Q1 (delta dentro do pool Q1):
--   F1  descida_passos >= 11       +17.8%  (era -13.9% global → INVERTIDO)
--   F2  plato_mag      < -6542     +13.8%  (consistente)
--   F3  traj_vel_de    < -3154     +12.5%  (novo)
--   F4  descida_tipo = QUEDA_IRR   +12.2%  (consistente, mais forte)
--   F5  momentum       >= 293.73   +12.1%  (novo)
--   F6  conv_dist      >= 3503.5   +11.9%  (novo)
--   F7  ac_lag1        < 0.17      +11.4%  (novo)
--   F8  grad_vel       >= 86       +11.0%  (consistente)
--   F9  plato_forca    >= -244     +11.0%  (novo)
--   F10 perc_fora_iqr = N          +10.0%  (consistente)
--   F11 plato_vel = NORMAL         +8.1%   (novo)
-- Melhores combos AND dentro Q1:
--   C1: F1 & F10  (passos>=11 & perc_fora_iqr=N)    → CSV: 51:1 (W=20.3%)
--   C2: F1 & F11  (passos>=11 & plato_vel=NORMAL)   → CSV: 52:1 (W=21.7%)
--   C3: F10 & F11 (perc_fora_iqr=N & plato_vel=N)   → CSV: 59:1 (W=21.7%)
-- Metodologia: PREDICAO = dia normal (candidatos sem PREMIO)
--              HISTORICO = d-30 (valida com PREMIO populado)
-- ------------------------------------------------------------
DECLARE
   -- ┌── CONFIGURAR AQUI ANTES DE EXECUTAR ──────────────────────────────────────┐
   --   v_modo = 'PREDICAO' : dia normal — PREMIO desconhecido, mostra CANDIDATOS  │
   --   v_modo = 'HISTORICO': d-30      — PREMIO populado, valida sinais           │
   --   Run 1 (d-30 sem prêmio): v_modo='HISTORICO' | v_dt_ini=TRUNC(SYSDATE-30)  │
   --                             v_dt_fim=<data antes do prêmio>                  │
   --   Run 2 (d-30 com prêmio): v_modo='HISTORICO' | v_dt_ini=TRUNC(SYSDATE-30)  │
   --                             v_dt_fim=TRUNC(SYSDATE)                          │
   --   Run 3 (dia normal)     : v_modo='PREDICAO'  | v_dt_ini=TRUNC(SYSDATE-1)   │
   --                             v_dt_fim=TRUNC(SYSDATE-1)                        │
   v_modo      VARCHAR2(10)  := 'PREDICAO';
   v_run_label VARCHAR2(40)  := 'Run 3: dia normal (ontem)';
   v_dt_ini    DATE          := TRUNC(SYSDATE - 1);
   v_dt_fim    DATE          := TRUNC(SYSDATE - 1);
   -- └───────────────────────────────────────────────────────────────────────────┘

   CURSOR c_q2 IS
      WITH q1_base AS (
         SELECT MIN(T3.ID_DADOS_ORBITA) AS id_repr
           FROM DADOS_ORBITA     DD
           JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
          WHERE DD.TIMESTAMP_EXECUCAO_INS >= v_dt_ini + 18/24
            AND DD.TIMESTAMP_EXECUCAO_INS <  v_dt_fim + 19/24
            AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)         >= -200  -- v11: era 100
            AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)         >= -400  -- v11: era -300
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
           , STR_PARA_NUMERO(P.PREMIO)                                AS v_premio
           -- F1: COMP_APOS_PICO — descida
           , STR_PARA_NUMERO(P.COMP_APOS_PICO__DESCIDA_PASSOS)       AS v_passos
           , P.COMP_APOS_PICO__DESCIDA_TIPO                           AS v_descida_tipo
           -- F2: PLATO_ABISMO
           , STR_PARA_NUMERO(P.PLATO_ABISMO__MAGNITUDE)               AS v_plato_mag
           , STR_PARA_NUMERO(P.PLATO_ABISMO__FORCA_PLATO)             AS v_plato_forca
           , P.PLATO_ABISMO__VELOCIDADE                                AS v_plato_vel
           -- F3: TRAJ_ASSIMETRICA
           , STR_PARA_NUMERO(P.TRAJ_ASSIMETRICA__VEL_MEDIA_DE)        AS v_traj_vel_de
           -- F5: MOMENTUM
           , STR_PARA_NUMERO(P.MOMENTUM__MOMENTUM)                    AS v_momentum
           -- F6: CONVERGENCIA
           , STR_PARA_NUMERO(P.CONVERGENCIA__DISTANCIA_MEDIA)         AS v_conv_dist
           -- F7: AUTOCORRELACAO
           , STR_PARA_NUMERO(P.AUTOCORRELACAO__AC_LAG1)               AS v_ac_lag1
           -- F8: GRADIENTE_FINAL
           , STR_PARA_NUMERO(P.GRADIENTE_FINAL__GRAD_VEL_MEDI)        AS v_grad_vel
           -- F10: PERCENTIS
           , P.PERCENTIS__FINAL_NO_IQR                                 AS v_perc_iqr
           -- C4 extras
           , STR_PARA_NUMERO(P.MOMENTUM__RAZAO_FINAL_TOTAL)            AS v_mom_razao
           , STR_PARA_NUMERO(P.COMPRIMENTO_ARCO__COMPRIMENTO_)         AS v_arco
           , P.FORMA__DISTRIBUICAO                                      AS v_forma_dist
           , P.ZONA__INICIAL                                            AS v_zona_ini
           -- C4a_v2: 5o filtro eliminando 4/5 NW do C4a
           , P.GRADIENTE_FINAL__GRAD_CHEGADA                            AS v_grad_cheg
           -- C4c e C4c_v2: captura winners PLATICURTICA com órbita estável
           , P.VOLAT_SEGMENTO__VOL_PADRAO                               AS v_vol_padrao
           , P.ZONA__PLATO                                               AS v_zona_plato
           , P.ZONA__DESTINO                                             AS v_zona_dest
           -- T2: C5 recalibrado dentro do pool C4c (v6 — Cohen's d > 1.0 dentro C4c)
           , STR_PARA_NUMERO(T2.PRESM_G20_HOMOG_LOCAL)           AS v_homog_local   -- d=1.15 W<N
           , STR_PARA_NUMERO(T2.PRESM_G16_OMEGA_COER_TEMPO)      AS v_coer_tempo    -- d=1.39 W>N
           , STR_PARA_NUMERO(T2.PRESM_G17_HEURIST_LIMIAR)        AS v_heurist_lim   -- d=1.20 W>N
           , STR_PARA_NUMERO(T2.PRESM_G22_FRONT_BETTI_0)         AS v_betti_0       -- d=1.08 W>N
           -- T2: C3r pré-filtro (v8 — nmf_dom_fator=2 sempre em winners C3, NW_mean~1.6)
           , STR_PARA_NUMERO(T2.PRESM_G17_NMF_DOM_FATOR)         AS v_nmf_dom_fator -- W=2.0 sempre
        FROM q1_base
        JOIN ORBITAS_TABELAO1  P  ON P.ID_DADOS_ORBITA  = q1_base.id_repr
        LEFT JOIN ORBITAS_TABELAO2 T2 ON T2.ID_DADOS_ORBITA = q1_base.id_repr
       ORDER BY STR_PARA_NUMERO(P.PREMIO) DESC;

   -- Contadores base
   v_total    NUMBER := 0;
   v_winners  NUMBER := 0;
   v_nao      NUMBER := 0;

   -- Contadores filtros individuais — [w]=winners, [n]=nao-premiados
   v_f1w  NUMBER := 0;  v_f1n  NUMBER := 0;   -- passos >= 11
   v_f2w  NUMBER := 0;  v_f2n  NUMBER := 0;   -- plato_mag < -6542
   v_f3w  NUMBER := 0;  v_f3n  NUMBER := 0;   -- traj_vel_de < -3154
   v_f4w  NUMBER := 0;  v_f4n  NUMBER := 0;   -- descida_tipo = QUEDA_IRREGULAR
   v_f5w  NUMBER := 0;  v_f5n  NUMBER := 0;   -- momentum >= 293.73
   v_f6w  NUMBER := 0;  v_f6n  NUMBER := 0;   -- conv_dist >= 3503.5
   v_f7w  NUMBER := 0;  v_f7n  NUMBER := 0;   -- ac_lag1 < 0.17
   v_f8w  NUMBER := 0;  v_f8n  NUMBER := 0;   -- grad_vel >= 86
   v_f9w  NUMBER := 0;  v_f9n  NUMBER := 0;   -- plato_forca >= -244
   v_f10w NUMBER := 0;  v_f10n NUMBER := 0;   -- perc_fora_iqr = N
   v_f11w NUMBER := 0;  v_f11n NUMBER := 0;   -- plato_vel = NORMAL

   -- Contadores combinações AND (HISTORICO)
   v_c1w  NUMBER := 0;  v_c1n  NUMBER := 0;   -- C1: F1 & F10
   v_c2w  NUMBER := 0;  v_c2n  NUMBER := 0;   -- C2: F1 & F11
   v_c3w  NUMBER := 0;  v_c3n  NUMBER := 0;   -- C3: F10 & F11
   -- C4a   : C2 & zona=Z4 & MESO                       → validado 5:1 (d-30)
   -- C4a_v2: C4a + grad_cheg=DESCENDO                  → 1:1 (elimina 4/5 NW; limite físico)
   -- C4c   : C2 & PLATICURTICA & vol=IRREGULAR               → 74:1 (refinamento pendente)
   -- C4c_v2: C4c & zona_plato=zona_destino (orbita estavel)  → meta <= 10:1
   v_c4aw   NUMBER := 0;  v_c4an   NUMBER := 0;
   v_c4a2w  NUMBER := 0;  v_c4a2n  NUMBER := 0;
   v_c4cw   NUMBER := 0;  v_c4cn   NUMBER := 0;
   v_c4c2w  NUMBER := 0;  v_c4c2n  NUMBER := 0;
   -- C4c3: C4c2 AND zona_plato='Z2' → apenas Z2->Z2 (ratio potencial 1:1)
   v_c4c3w  NUMBER := 0;  v_c4c3n  NUMBER := 0;
   -- C5a: C4c + homog_local <= 0.587  (T2 dentro C4c: d=1.15, recall=100%, 11.7:1)
   v_c5aw   NUMBER := 0;  v_c5an   NUMBER := 0;
   -- C5b: C4c + coer_tempo >= 0.804  (T2 dentro C4c: d=1.39, recall= 67%, 8.5:1)
   v_c5bw   NUMBER := 0;  v_c5bn   NUMBER := 0;
   -- C5c: C4c + heurist_limiar >= 10.930 (T2 dentro C4c: d=1.20, recall=100%, 13.3:1)
   v_c5cw   NUMBER := 0;  v_c5cn   NUMBER := 0;
   -- C5d: C4c + homog_local<=0.568 AND betti_0>=347.3 (T2 dentro C4c: 1.0:1, 67%) *** META ***
   v_c5dw   NUMBER := 0;  v_c5dn   NUMBER := 0;

   -- C4r: ranking betti_0 no pool arquétipo C (NOT F10 AND NOT F11) top-2
   v_c4rw   NUMBER := 0;  v_c4rn   NUMBER := 0;
   -- C3r: ranking betti_0 dentro do pool C3 diário (F10+F11, sem F1) top-2
   v_c3rw   NUMBER := 0;  v_c3rn   NUMBER := 0;
   -- C5r: ranking betti_0 dentro do pool C4c diário (top-2 por dia)
   v_c5rw   NUMBER := 0;  v_c5rn   NUMBER := 0;

   -- Coleções de IDs
   TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;

   -- Pool compartilhado para ranking por betti_0 (C3r e C5r)
   TYPE t_c5r_rec IS RECORD (id_orb NUMBER, betti NUMBER, is_w BOOLEAN);
   TYPE t_c5r_tab IS TABLE OF t_c5r_rec INDEX BY PLS_INTEGER;
   -- C4r pool (NOT F10 AND NOT F11 — arquétipo C invisível)
   v_c4r_pool  t_c5r_tab;
   v_c4r_cnt   NUMBER := 0;
   v_top1_c4r  PLS_INTEGER := NULL;
   v_top2_c4r  PLS_INTEGER := NULL;
   -- C3r pool (F10+F11, sem F1)
   v_c3r_pool  t_c5r_tab;
   v_c3r_cnt   NUMBER := 0;
   v_top1_c3r  PLS_INTEGER := NULL;
   v_top2_c3r  PLS_INTEGER := NULL;
   -- C5r pool (C4c)
   v_c5r_pool  t_c5r_tab;
   v_c5r_cnt   NUMBER := 0;
   v_top1_idx  PLS_INTEGER := NULL;
   v_top2_idx  PLS_INTEGER := NULL;
   v_iter      PLS_INTEGER;

   -- HISTORICO: premiados por grupo
   v_ids_q1  t_ids;
   v_ids_c1  t_ids;
   v_ids_c2  t_ids;
   v_ids_c3  t_ids;

   -- PREDICAO: todos aprovados por grupo (PREMIO desconhecido)
   v_cand_q1  t_ids;
   v_cand_c1  t_ids;
   v_cand_c2  t_ids;
   v_cand_c3  t_ids;
   v_cand_c4a  t_ids;   -- C4a:    zona=Z4 & MESO              (5:1 validado)
   v_cand_c4a2 t_ids;   -- C4a_v2: C4a + grad_cheg=DESCENDO   (1:1 limite fisico)
   v_cand_c4c  t_ids;   -- C4c:    PLATICURTICA & vol=IRREGULAR (74:1 d-30)
   v_cand_c4c2 t_ids;   -- C4c2: C4c + zona_plato=zona_dest     (3:1 validado)
   v_cand_c4c3 t_ids;   -- C4c3: C4c2 + zona_plato='Z2'        (ratio 1:1 potencial)
   v_cand_c5a  t_ids;   -- C5a: C4c + homog_local <= 0.587          (11.7:1, recall 100%)
   v_cand_c5b  t_ids;   -- C5b: C4c + coer_tempo >= 0.804          (8.5:1,  recall  67%)
   v_cand_c5c  t_ids;   -- C5c: C4c + heurist_limiar >= 10.930     (13.3:1, recall 100%)
   v_cand_c5d  t_ids;   -- C5d: C4c + homog<=0.568 & betti>=347.3  (1.0:1,  recall  67%) monit.
   v_cand_c4r  t_ids;   -- C4r: top-2 Q1(sem F10/F11) por betti_0 DESC (arquétipo C — 41% dos W)
   v_cand_c3r  t_ids;   -- C3r: top-2 C3 por betti_0 DESC (F10+F11, sem F1 — winners que C4c perde)
   v_cand_c5r  t_ids;   -- C5r: top-2 C4c por betti_0 DESC (ranking diário — 100% top1 em 3 dias)

   -- Contadores candidatos
   v_cq1   NUMBER := 0;
   v_cc1   NUMBER := 0;
   v_cc2   NUMBER := 0;
   v_cc3   NUMBER := 0;
   v_cc4a  NUMBER := 0;
   v_cc4a2 NUMBER := 0;
   v_cc4c  NUMBER := 0;
   v_cc4c2 NUMBER := 0;
   v_cc4c3 NUMBER := 0;
   v_cc5a  NUMBER := 0;
   v_cc5b  NUMBER := 0;
   v_cc5c  NUMBER := 0;
   v_cc5d  NUMBER := 0;
   v_cc4r  NUMBER := 0;
   v_cc3r  NUMBER := 0;
   v_cc5r  NUMBER := 0;

   v_is_w   BOOLEAN;
   v_p1     BOOLEAN;   -- F1: passos >= 11
   v_p2     BOOLEAN;   -- F2: plato_mag < -6542
   v_p3     BOOLEAN;   -- F3: traj_vel_de < -3154
   v_p4     BOOLEAN;   -- F4: QUEDA_IRREGULAR
   v_p5     BOOLEAN;   -- F5: momentum >= 293.73
   v_p6     BOOLEAN;   -- F6: conv_dist >= 3503.5
   v_p7     BOOLEAN;   -- F7: ac_lag1 < 0.17
   v_p8     BOOLEAN;   -- F8: grad_vel >= 86
   v_p9     BOOLEAN;   -- F9: plato_forca >= -244
   v_p10    BOOLEAN;   -- F10: perc_iqr = N
   v_p11    BOOLEAN;   -- F11: plato_vel = NORMAL
   v_p12    BOOLEAN;   -- F12: grad_cheg = DESCENDO            (C4a_v2)
   v_p13    BOOLEAN;   -- F13: vol_padrao = IRREGULAR          (C4c)
   v_p14    BOOLEAN;   -- F14: forma = PLATICURTICA            (C4c)
   v_p15    BOOLEAN;   -- F15: zona_plato = zona_destino       (C4c_v2 — orbita estavel)
   v_p16    BOOLEAN;   -- F16: homog_local <= 0.587  (T2 dentro C4c: d=1.15, recall 100%)
   v_p17    BOOLEAN;   -- F17: coer_tempo  >= 0.804  (T2 dentro C4c: d=1.39, recall  67%)
   v_p18    BOOLEAN;   -- F18: heurist_lim >= 10.930 (T2 dentro C4c: d=1.20, recall 100%)
   v_p19    BOOLEAN;   -- F19: betti_0     >= 347.3  (T2 dentro C4c: d=1.08, recall  67%)

   -- Persistência em tabela
   v_id_exec   NUMBER;
   TYPE t_bool_set IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
   v_prem_set  t_bool_set;   -- mapa ID → is_premio para lookup no INSERT

   FUNCTION pct(n NUMBER, tot NUMBER) RETURN VARCHAR2 IS
   BEGIN
      IF tot = 0 THEN RETURN '0.0'; END IF;
      RETURN TO_CHAR(ROUND(n * 100 / tot, 1));
   END;

   PROCEDURE print_ids(p_col t_ids, p_label VARCHAR2) IS
      v_linha VARCHAR2(200) := '  ';
      v_i     PLS_INTEGER;
   BEGIN
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE(p_label);
      IF p_col.COUNT = 0 THEN
         DBMS_OUTPUT.PUT_LINE('  (nenhum)');
         RETURN;
      END IF;
      v_i := p_col.FIRST;
      WHILE v_i IS NOT NULL LOOP
         v_linha := v_linha || p_col(v_i);
         v_i := p_col.NEXT(v_i);
         IF v_i IS NOT NULL THEN v_linha := v_linha || ', '; END IF;
         IF LENGTH(v_linha) > 150 OR v_i IS NULL THEN
            DBMS_OUTPUT.PUT_LINE(v_linha);
            v_linha := '  ';
         END IF;
      END LOOP;
   END;

BEGIN
   DBMS_OUTPUT.PUT_LINE('=== Q2 COMBINADO — ' || v_run_label || ' ===');
   DBMS_OUTPUT.PUT_LINE('Modo   : ' || v_modo);
   DBMS_OUTPUT.PUT_LINE('Janela : ' || TO_CHAR(v_dt_ini,'DD/MM/YYYY') || ' a ' || TO_CHAR(v_dt_fim,'DD/MM/YYYY'));
   DBMS_OUTPUT.PUT_LINE('Filtros calibrados DENTRO do Q1 (Python, 7.7k registros)');
   DBMS_OUTPUT.PUT_LINE('-----------------------------------------------------------');

   FOR r IN c_q2 LOOP
      v_total := v_total + 1;
      v_is_w  := (r.v_premio > 0);

      IF v_is_w THEN
         v_winners := v_winners + 1;
         v_ids_q1(v_winners) := r.ID_DADOS_ORBITA;
         v_prem_set(TO_NUMBER(r.ID_DADOS_ORBITA)) := TRUE;   -- mapa para INSERT
      ELSE
         v_nao := v_nao + 1;
      END IF;

      -- Todos Q1 são candidatos (PREDICAO)
      v_cq1 := v_cq1 + 1;
      v_cand_q1(v_cq1) := r.ID_DADOS_ORBITA;

      -- Avalia cada filtro
      v_p1  := r.v_passos       IS NOT NULL AND r.v_passos       >= 11;
      v_p2  := r.v_plato_mag    IS NOT NULL AND r.v_plato_mag    <  -6542;
      v_p3  := r.v_traj_vel_de  IS NOT NULL AND r.v_traj_vel_de  <  -3154;
      v_p4  := r.v_descida_tipo = 'QUEDA_IRREGULAR';
      v_p5  := r.v_momentum     IS NOT NULL AND r.v_momentum     >= 293.73;
      v_p6  := r.v_conv_dist    IS NOT NULL AND r.v_conv_dist    >= 3503.5;
      v_p7  := r.v_ac_lag1      IS NOT NULL AND r.v_ac_lag1      <  0.17;
      v_p8  := r.v_grad_vel     IS NOT NULL AND r.v_grad_vel     >= 86;
      v_p9  := r.v_plato_forca  IS NOT NULL AND r.v_plato_forca  >= -244;
      v_p10 := r.v_perc_iqr     = 'N';
      v_p11 := r.v_plato_vel    = 'NORMAL';
      v_p12 := r.v_grad_cheg    = 'DESCENDO';
      v_p13 := r.v_vol_padrao   = 'IRREGULAR';
      v_p14 := r.v_forma_dist   = 'PLATICURTICA';
      v_p15 := r.v_zona_plato   IS NOT NULL
           AND r.v_zona_dest    IS NOT NULL
           AND r.v_zona_plato   = r.v_zona_dest;
      v_p16 := r.v_homog_local  IS NOT NULL AND r.v_homog_local <= 0.587;
      v_p17 := r.v_coer_tempo  IS NOT NULL AND r.v_coer_tempo  >= 0.804;
      v_p18 := r.v_heurist_lim IS NOT NULL AND r.v_heurist_lim >= 10.930;
      v_p19 := r.v_betti_0     IS NOT NULL AND r.v_betti_0    >= 347.3;

      -- Contadores individuais (HISTORICO)
      IF v_p1  THEN IF v_is_w THEN v_f1w  := v_f1w  + 1; ELSE v_f1n  := v_f1n  + 1; END IF; END IF;
      IF v_p2  THEN IF v_is_w THEN v_f2w  := v_f2w  + 1; ELSE v_f2n  := v_f2n  + 1; END IF; END IF;
      IF v_p3  THEN IF v_is_w THEN v_f3w  := v_f3w  + 1; ELSE v_f3n  := v_f3n  + 1; END IF; END IF;
      IF v_p4  THEN IF v_is_w THEN v_f4w  := v_f4w  + 1; ELSE v_f4n  := v_f4n  + 1; END IF; END IF;
      IF v_p5  THEN IF v_is_w THEN v_f5w  := v_f5w  + 1; ELSE v_f5n  := v_f5n  + 1; END IF; END IF;
      IF v_p6  THEN IF v_is_w THEN v_f6w  := v_f6w  + 1; ELSE v_f6n  := v_f6n  + 1; END IF; END IF;
      IF v_p7  THEN IF v_is_w THEN v_f7w  := v_f7w  + 1; ELSE v_f7n  := v_f7n  + 1; END IF; END IF;
      IF v_p8  THEN IF v_is_w THEN v_f8w  := v_f8w  + 1; ELSE v_f8n  := v_f8n  + 1; END IF; END IF;
      IF v_p9  THEN IF v_is_w THEN v_f9w  := v_f9w  + 1; ELSE v_f9n  := v_f9n  + 1; END IF; END IF;
      IF v_p10 THEN IF v_is_w THEN v_f10w := v_f10w + 1; ELSE v_f10n := v_f10n + 1; END IF; END IF;
      IF v_p11 THEN IF v_is_w THEN v_f11w := v_f11w + 1; ELSE v_f11n := v_f11n + 1; END IF; END IF;

      -- C4r: arquétipo C (NOT F10 AND NOT F11) — 41% dos winners totais
      -- betti_0 captura winner C no top-1 em 6/7 dias (analise_arquetipo_c.py)
      IF NOT v_p10 AND NOT v_p11 THEN
         v_c4r_cnt := v_c4r_cnt + 1;
         v_c4r_pool(v_c4r_cnt).id_orb := r.ID_DADOS_ORBITA;
         v_c4r_pool(v_c4r_cnt).betti  := NVL(r.v_betti_0, 0);
         v_c4r_pool(v_c4r_cnt).is_w   := v_is_w;
      END IF;

      -- C3r: F10 & F11 + pré-filtro nmf_dom_fator=2 → top-2 betti_0 (v8)
      -- nmf_dom_fator=2 em 100% dos winners C3, descarta ~30-40% NW com valor 1
      IF v_p10 AND v_p11
         AND NVL(r.v_nmf_dom_fator, 0) = 2 THEN
         v_c3r_cnt := v_c3r_cnt + 1;
         v_c3r_pool(v_c3r_cnt).id_orb := r.ID_DADOS_ORBITA;
         v_c3r_pool(v_c3r_cnt).betti  := NVL(r.v_betti_0, 0);
         v_c3r_pool(v_c3r_cnt).is_w   := v_is_w;
      END IF;

      -- C1: F1 & F10 (passos>=11 & perc_fora_iqr=N)
      IF v_p1 AND v_p10 THEN
         IF v_is_w THEN v_c1w := v_c1w + 1; v_ids_c1(v_c1w) := r.ID_DADOS_ORBITA;
         ELSE           v_c1n := v_c1n + 1;
         END IF;
         v_cc1 := v_cc1 + 1; v_cand_c1(v_cc1) := r.ID_DADOS_ORBITA;
      END IF;

      -- C2: F1 & F11 (passos>=11 & plato_vel=NORMAL)
      IF v_p1 AND v_p11 THEN
         IF v_is_w THEN v_c2w := v_c2w + 1; v_ids_c2(v_c2w) := r.ID_DADOS_ORBITA;
         ELSE           v_c2n := v_c2n + 1;
         END IF;
         v_cc2 := v_cc2 + 1; v_cand_c2(v_cc2) := r.ID_DADOS_ORBITA;
      END IF;

      -- C3: F10 & F11 (perc_fora_iqr=N & plato_vel=NORMAL)
      IF v_p10 AND v_p11 THEN
         IF v_is_w THEN v_c3w := v_c3w + 1; v_ids_c3(v_c3w) := r.ID_DADOS_ORBITA;
         ELSE           v_c3n := v_c3n + 1;
         END IF;
         v_cc3 := v_cc3 + 1; v_cand_c3(v_cc3) := r.ID_DADOS_ORBITA;
      END IF;

      -- C4a: C2 & zona_ini=Z4 & MESO → validado 5:1
      IF v_p1 AND v_p11
         AND r.v_zona_ini   = 'Z4'
         AND r.v_forma_dist = 'MESOCURTICA' THEN
         IF v_is_w THEN v_c4aw := v_c4aw + 1; ELSE v_c4an := v_c4an + 1; END IF;
         v_cc4a := v_cc4a + 1; v_cand_c4a(v_cc4a) := r.ID_DADOS_ORBITA;
      END IF;

      -- C4a_v2: C4a + grad_cheg=DESCENDO → 1:1 (elimina 4/5 NW; limite físico do sistema)
      IF v_p1 AND v_p11 AND v_p12
         AND r.v_zona_ini   = 'Z4'
         AND r.v_forma_dist = 'MESOCURTICA' THEN
         IF v_is_w THEN v_c4a2w := v_c4a2w + 1; ELSE v_c4a2n := v_c4a2n + 1; END IF;
         v_cc4a2 := v_cc4a2 + 1; v_cand_c4a2(v_cc4a2) := r.ID_DADOS_ORBITA;
      END IF;

      -- C4c: C2 & PLATICURTICA & vol=IRREGULAR → 74:1 (precisa de C4c_v2)
      IF v_p1 AND v_p11 AND v_p13 AND v_p14 THEN
         IF v_is_w THEN v_c4cw := v_c4cw + 1; ELSE v_c4cn := v_c4cn + 1; END IF;
         v_cc4c := v_cc4c + 1; v_cand_c4c(v_cc4c) := r.ID_DADOS_ORBITA;
         -- C5r: acumula pool com betti_0 para ranking pós-loop
         v_c5r_cnt := v_c5r_cnt + 1;
         v_c5r_pool(v_c5r_cnt).id_orb := r.ID_DADOS_ORBITA;
         v_c5r_pool(v_c5r_cnt).betti  := NVL(r.v_betti_0, 0);
         v_c5r_pool(v_c5r_cnt).is_w   := v_is_w;
      END IF;

      -- C4c_v2: C4c & zona_plato=zona_destino → orbita estavel — meta <=10:1
      IF v_p1 AND v_p11 AND v_p13 AND v_p14 AND v_p15 THEN
         IF v_is_w THEN v_c4c2w := v_c4c2w + 1; ELSE v_c4c2n := v_c4c2n + 1; END IF;
         v_cc4c2 := v_cc4c2 + 1; v_cand_c4c2(v_cc4c2) := r.ID_DADOS_ORBITA;
      END IF;

      -- C4c3: C4c2 AND zona_plato='Z2' → apenas Z2->Z2 (ratio potencial 1:1)
      IF v_p1 AND v_p11 AND v_p13 AND v_p14 AND v_p15
         AND r.v_zona_plato = 'Z2' THEN
         IF v_is_w THEN v_c4c3w := v_c4c3w + 1; ELSE v_c4c3n := v_c4c3n + 1; END IF;
         v_cc4c3 := v_cc4c3 + 1; v_cand_c4c3(v_cc4c3) := r.ID_DADOS_ORBITA;
      END IF;

      -- C5a: C4c + homog_local <= 0.587 (recall=100%, 11.7:1 dentro C4c)
      IF v_p1 AND v_p11 AND v_p13 AND v_p14 AND v_p16 THEN
         IF v_is_w THEN v_c5aw := v_c5aw + 1; ELSE v_c5an := v_c5an + 1; END IF;
         v_cc5a := v_cc5a + 1; v_cand_c5a(v_cc5a) := r.ID_DADOS_ORBITA;
      END IF;

      -- C5b: C4c + coer_tempo >= 0.804 (recall=67%, 8.5:1 dentro C4c)
      IF v_p1 AND v_p11 AND v_p13 AND v_p14 AND v_p17 THEN
         IF v_is_w THEN v_c5bw := v_c5bw + 1; ELSE v_c5bn := v_c5bn + 1; END IF;
         v_cc5b := v_cc5b + 1; v_cand_c5b(v_cc5b) := r.ID_DADOS_ORBITA;
      END IF;

      -- C5c: C4c + heurist_limiar >= 10.930 (recall=100%, 13.3:1 dentro C4c)
      IF v_p1 AND v_p11 AND v_p13 AND v_p14 AND v_p18 THEN
         IF v_is_w THEN v_c5cw := v_c5cw + 1; ELSE v_c5cn := v_c5cn + 1; END IF;
         v_cc5c := v_cc5c + 1; v_cand_c5c(v_cc5c) := r.ID_DADOS_ORBITA;
      END IF;

      -- C5d: C4c + homog_local<=0.568 AND betti_0>=347.3 (recall=67%, 1.0:1) *** META ***
      IF v_p1 AND v_p11 AND v_p13 AND v_p14
         AND r.v_homog_local IS NOT NULL AND r.v_homog_local <= 0.568
         AND v_p19 THEN
         IF v_is_w THEN v_c5dw := v_c5dw + 1; ELSE v_c5dn := v_c5dn + 1; END IF;
         v_cc5d := v_cc5d + 1; v_cand_c5d(v_cc5d) := r.ID_DADOS_ORBITA;
      END IF;
   END LOOP;

   -- ── C4r: ranking betti_0 DESC no pool arquétipo C (NOT F10 AND NOT F11) ──────
   v_iter := v_c4r_pool.FIRST;
   WHILE v_iter IS NOT NULL LOOP
      IF v_top1_c4r IS NULL
         OR NVL(v_c4r_pool(v_iter).betti,0) > NVL(v_c4r_pool(v_top1_c4r).betti,0) THEN
         v_top2_c4r := v_top1_c4r;  v_top1_c4r := v_iter;
      ELSIF v_top2_c4r IS NULL
         OR NVL(v_c4r_pool(v_iter).betti,0) > NVL(v_c4r_pool(v_top2_c4r).betti,0) THEN
         v_top2_c4r := v_iter;
      END IF;
      v_iter := v_c4r_pool.NEXT(v_iter);
   END LOOP;
   IF v_top1_c4r IS NOT NULL THEN
      v_cc4r := v_cc4r + 1; v_cand_c4r(v_cc4r) := v_c4r_pool(v_top1_c4r).id_orb;
      IF v_c4r_pool(v_top1_c4r).is_w THEN v_c4rw := v_c4rw+1; ELSE v_c4rn := v_c4rn+1; END IF;
   END IF;
   IF v_top2_c4r IS NOT NULL THEN
      v_cc4r := v_cc4r + 1; v_cand_c4r(v_cc4r) := v_c4r_pool(v_top2_c4r).id_orb;
      IF v_c4r_pool(v_top2_c4r).is_w THEN v_c4rw := v_c4rw+1; ELSE v_c4rn := v_c4rn+1; END IF;
   END IF;

   -- ── C3r: ranking betti_0 DESC dentro do pool C3 (F10+F11) — top-2 ──────────
   v_iter := v_c3r_pool.FIRST;
   WHILE v_iter IS NOT NULL LOOP
      IF v_top1_c3r IS NULL
         OR NVL(v_c3r_pool(v_iter).betti,0) > NVL(v_c3r_pool(v_top1_c3r).betti,0) THEN
         v_top2_c3r := v_top1_c3r;  v_top1_c3r := v_iter;
      ELSIF v_top2_c3r IS NULL
         OR NVL(v_c3r_pool(v_iter).betti,0) > NVL(v_c3r_pool(v_top2_c3r).betti,0) THEN
         v_top2_c3r := v_iter;
      END IF;
      v_iter := v_c3r_pool.NEXT(v_iter);
   END LOOP;
   IF v_top1_c3r IS NOT NULL THEN
      v_cc3r := v_cc3r + 1; v_cand_c3r(v_cc3r) := v_c3r_pool(v_top1_c3r).id_orb;
      IF v_c3r_pool(v_top1_c3r).is_w THEN v_c3rw := v_c3rw+1; ELSE v_c3rn := v_c3rn+1; END IF;
   END IF;
   IF v_top2_c3r IS NOT NULL THEN
      v_cc3r := v_cc3r + 1; v_cand_c3r(v_cc3r) := v_c3r_pool(v_top2_c3r).id_orb;
      IF v_c3r_pool(v_top2_c3r).is_w THEN v_c3rw := v_c3rw+1; ELSE v_c3rn := v_c3rn+1; END IF;
   END IF;

   -- ── C5r: ranking betti_0 DESC dentro do pool C4c — seleciona top-2 ─────────
   -- Passagem 1: acha o maior betti_0
   v_iter := v_c5r_pool.FIRST;
   WHILE v_iter IS NOT NULL LOOP
      IF v_top1_idx IS NULL
         OR NVL(v_c5r_pool(v_iter).betti, 0) > NVL(v_c5r_pool(v_top1_idx).betti, 0) THEN
         v_top2_idx := v_top1_idx;
         v_top1_idx := v_iter;
      ELSIF v_top2_idx IS NULL
         OR NVL(v_c5r_pool(v_iter).betti, 0) > NVL(v_c5r_pool(v_top2_idx).betti, 0) THEN
         v_top2_idx := v_iter;
      END IF;
      v_iter := v_c5r_pool.NEXT(v_iter);
   END LOOP;
   -- Registra top-1
   IF v_top1_idx IS NOT NULL THEN
      v_cc5r := v_cc5r + 1;
      v_cand_c5r(v_cc5r) := v_c5r_pool(v_top1_idx).id_orb;
      IF v_c5r_pool(v_top1_idx).is_w THEN v_c5rw := v_c5rw + 1;
      ELSE                                 v_c5rn := v_c5rn + 1; END IF;
   END IF;
   -- Registra top-2
   IF v_top2_idx IS NOT NULL THEN
      v_cc5r := v_cc5r + 1;
      v_cand_c5r(v_cc5r) := v_c5r_pool(v_top2_idx).id_orb;
      IF v_c5r_pool(v_top2_idx).is_w THEN v_c5rw := v_c5rw + 1;
      ELSE                                  v_c5rn := v_c5rn + 1; END IF;
   END IF;

   -- ================================================================
   -- OUTPUT
   -- ================================================================
   DBMS_OUTPUT.PUT_LINE('');
   DBMS_OUTPUT.PUT_LINE('--- TOTAIS Q1 ---');
   DBMS_OUTPUT.PUT_LINE('Total   : ' || v_total);
   DBMS_OUTPUT.PUT_LINE('Prem.   : ' || v_winners);
   DBMS_OUTPUT.PUT_LINE('Nao-pr. : ' || v_nao);
   IF v_winners > 0 THEN
      DBMS_OUTPUT.PUT_LINE('Ratio   : ' || ROUND(v_nao / v_winners) || ':1');
   END IF;
   DBMS_OUTPUT.PUT_LINE('');

   DBMS_OUTPUT.PUT_LINE('--- FILTROS INDIVIDUAIS (calibrados dentro Q1) ---');
   DBMS_OUTPUT.PUT_LINE('Filtro                      | Prem%  | NaoPr% | Delta | Ref CSV');
   DBMS_OUTPUT.PUT_LINE('F1  passos>=11              | ' || LPAD(pct(v_f1w,v_winners),6) || '% | ' || LPAD(pct(v_f1n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f1w*100/NULLIF(v_winners,0)-v_f1n*100/NULLIF(v_nao,0),1)),5) || ' | +17.8%');
   DBMS_OUTPUT.PUT_LINE('F2  plato_mag<-6542         | ' || LPAD(pct(v_f2w,v_winners),6) || '% | ' || LPAD(pct(v_f2n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f2w*100/NULLIF(v_winners,0)-v_f2n*100/NULLIF(v_nao,0),1)),5) || ' | +13.8%');
   DBMS_OUTPUT.PUT_LINE('F3  traj_vel_de<-3154       | ' || LPAD(pct(v_f3w,v_winners),6) || '% | ' || LPAD(pct(v_f3n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f3w*100/NULLIF(v_winners,0)-v_f3n*100/NULLIF(v_nao,0),1)),5) || ' | +12.5%');
   DBMS_OUTPUT.PUT_LINE('F4  descida=QUEDA_IRREGULAR | ' || LPAD(pct(v_f4w,v_winners),6) || '% | ' || LPAD(pct(v_f4n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f4w*100/NULLIF(v_winners,0)-v_f4n*100/NULLIF(v_nao,0),1)),5) || ' | +12.2%');
   DBMS_OUTPUT.PUT_LINE('F5  momentum>=293.73        | ' || LPAD(pct(v_f5w,v_winners),6) || '% | ' || LPAD(pct(v_f5n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f5w*100/NULLIF(v_winners,0)-v_f5n*100/NULLIF(v_nao,0),1)),5) || ' | +12.1%');
   DBMS_OUTPUT.PUT_LINE('F6  conv_dist>=3503.5       | ' || LPAD(pct(v_f6w,v_winners),6) || '% | ' || LPAD(pct(v_f6n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f6w*100/NULLIF(v_winners,0)-v_f6n*100/NULLIF(v_nao,0),1)),5) || ' | +11.9%');
   DBMS_OUTPUT.PUT_LINE('F7  ac_lag1<0.17            | ' || LPAD(pct(v_f7w,v_winners),6) || '% | ' || LPAD(pct(v_f7n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f7w*100/NULLIF(v_winners,0)-v_f7n*100/NULLIF(v_nao,0),1)),5) || ' | +11.4%');
   DBMS_OUTPUT.PUT_LINE('F8  grad_vel>=86            | ' || LPAD(pct(v_f8w,v_winners),6) || '% | ' || LPAD(pct(v_f8n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f8w*100/NULLIF(v_winners,0)-v_f8n*100/NULLIF(v_nao,0),1)),5) || ' | +11.0%');
   DBMS_OUTPUT.PUT_LINE('F9  plato_forca>=-244       | ' || LPAD(pct(v_f9w,v_winners),6) || '% | ' || LPAD(pct(v_f9n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f9w*100/NULLIF(v_winners,0)-v_f9n*100/NULLIF(v_nao,0),1)),5) || ' | +11.0%');
   DBMS_OUTPUT.PUT_LINE('F10 perc_fora_iqr=N         | ' || LPAD(pct(v_f10w,v_winners),6) || '% | ' || LPAD(pct(v_f10n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f10w*100/NULLIF(v_winners,0)-v_f10n*100/NULLIF(v_nao,0),1)),5) || ' | +10.0%');
   DBMS_OUTPUT.PUT_LINE('F11 plato_vel=NORMAL        | ' || LPAD(pct(v_f11w,v_winners),6) || '% | ' || LPAD(pct(v_f11n,v_nao),6) || '% | ' || LPAD(TO_CHAR(ROUND(v_f11w*100/NULLIF(v_winners,0)-v_f11n*100/NULLIF(v_nao,0),1)),5) || ' |  +8.1%');
   DBMS_OUTPUT.PUT_LINE('');

   DBMS_OUTPUT.PUT_LINE('--- COMBINAÇÕES AND (ref CSV Q1: C1→51:1, C2→52:1, C3→59:1) ---');
   DBMS_OUTPUT.PUT_LINE('Comb                        | Prem          | NaoPr         | Ratio');
   DBMS_OUTPUT.PUT_LINE('C1 F1&F10 (passos & iqr=N)  | '
      || LPAD(v_c1w,4) || ' (' || LPAD(pct(v_c1w,v_winners),5) || '%) | '
      || LPAD(v_c1n,5) || ' (' || LPAD(pct(v_c1n,v_nao),5) || '%) | '
      || CASE WHEN v_c1w > 0 THEN ROUND(v_c1n/v_c1w)||':1' ELSE 'sem W' END);
   DBMS_OUTPUT.PUT_LINE('C2 F1&F11 (passos & vel=N)  | '
      || LPAD(v_c2w,4) || ' (' || LPAD(pct(v_c2w,v_winners),5) || '%) | '
      || LPAD(v_c2n,5) || ' (' || LPAD(pct(v_c2n,v_nao),5) || '%) | '
      || CASE WHEN v_c2w > 0 THEN ROUND(v_c2n/v_c2w)||':1' ELSE 'sem W' END);
   DBMS_OUTPUT.PUT_LINE('C3 F10&F11 (iqr=N & vel=N)  | '
      || LPAD(v_c3w,4) || ' (' || LPAD(pct(v_c3w,v_winners),5) || '%) | '
      || LPAD(v_c3n,5) || ' (' || LPAD(pct(v_c3n,v_nao),5) || '%) | '
      || CASE WHEN v_c3w > 0 THEN ROUND(v_c3n/v_c3w)||':1' ELSE 'sem W' END);
   DBMS_OUTPUT.PUT_LINE('C4a  C2+zona=Z4+MESO        | '
      || LPAD(v_c4aw,4) || ' (' || LPAD(pct(v_c4aw,v_winners),5) || '%) | '
      || LPAD(v_c4an,5) || ' (' || LPAD(pct(v_c4an,v_nao),5) || '%) | '
      || CASE WHEN v_c4aw > 0 THEN ROUND(v_c4an/v_c4aw)||':1' ELSE 'sem W' END
      || ' [d-30 validado: 5:1]');
   DBMS_OUTPUT.PUT_LINE('C4a2 C4a+grad=DESCENDO      | '
      || LPAD(v_c4a2w,4) || ' (' || LPAD(pct(v_c4a2w,v_winners),5) || '%) | '
      || LPAD(v_c4a2n,5) || ' (' || LPAD(pct(v_c4a2n,v_nao),5) || '%) | '
      || CASE WHEN v_c4a2w > 0 THEN ROUND(v_c4a2n/v_c4a2w)||':1' ELSE 'sem W' END
      || ' *** META — limite fisico 1:1 ***');
   DBMS_OUTPUT.PUT_LINE('C4c  C2+PLAT+vol=IRREG      | '
      || LPAD(v_c4cw,4) || ' (' || LPAD(pct(v_c4cw,v_winners),5) || '%) | '
      || LPAD(v_c4cn,5) || ' (' || LPAD(pct(v_c4cn,v_nao),5) || '%) | '
      || CASE WHEN v_c4cw > 0 THEN ROUND(v_c4cn/v_c4cw)||':1' ELSE 'sem W' END
      || ' [d-30: 74:1]');
   DBMS_OUTPUT.PUT_LINE('C4c2 C4c+zona_pl=zona_dest  | '
      || LPAD(v_c4c2w,4) || ' (' || LPAD(pct(v_c4c2w,v_winners),5) || '%) | '
      || LPAD(v_c4c2n,5) || ' (' || LPAD(pct(v_c4c2n,v_nao),5) || '%) | '
      || CASE WHEN v_c4c2w > 0 THEN ROUND(v_c4c2n/v_c4c2w)||':1' ELSE 'sem W' END
      || ' [validado 3:1]');
   DBMS_OUTPUT.PUT_LINE('C4c3 C4c2+zona_pl=Z2        | '
      || LPAD(v_c4c3w,4) || ' (' || LPAD(pct(v_c4c3w,v_winners),5) || '%) | '
      || LPAD(v_c4c3n,5) || ' (' || LPAD(pct(v_c4c3n,v_nao),5) || '%) | '
      || CASE WHEN v_c4c3w > 0 THEN ROUND(v_c4c3n/v_c4c3w)||':1' ELSE 'sem W' END
      || ' *** Z2->Z2 apenas — ratio potencial 1:1 ***');
   DBMS_OUTPUT.PUT_LINE('--- T2 RANKING betti_0 DESC (v9) ---');
   DBMS_OUTPUT.PUT_LINE('C4r  SEM F10/F11 TOP-2 betti_0   | '
      || LPAD(v_c4rw,4) || ' (' || LPAD(pct(v_c4rw,v_winners),5) || '%) | '
      || LPAD(v_c4rn,5) || ' (' || LPAD(pct(v_c4rn,v_nao),5) || '%) | '
      || CASE WHEN v_c4rw > 0 THEN ROUND(v_c4rn/v_c4rw)||':1' ELSE 'sem W' END
      || ' [Arquetipo C — 41% winners, top1 em 6/7 dias]');
   DBMS_OUTPUT.PUT_LINE('C3r  C3+nmf=2 TOP-2 betti_0      | '
      || LPAD(v_c3rw,4) || ' (' || LPAD(pct(v_c3rw,v_winners),5) || '%) | '
      || LPAD(v_c3rn,5) || ' (' || LPAD(pct(v_c3rn,v_nao),5) || '%) | '
      || CASE WHEN v_c3rw > 0 THEN ROUND(v_c3rn/v_c3rw)||':1' ELSE 'sem W' END
      || ' [F10+F11+nmf=2, top-2 betti_0 — winners sem F1]');
   DBMS_OUTPUT.PUT_LINE('C5r  C4c TOP-2 betti_0 DESC     | '
      || LPAD(v_c5rw,4) || ' (' || LPAD(pct(v_c5rw,v_winners),5) || '%) | '
      || LPAD(v_c5rn,5) || ' (' || LPAD(pct(v_c5rn,v_nao),5) || '%) | '
      || CASE WHEN v_c5rw > 0 THEN ROUND(v_c5rn/v_c5rw)||':1' ELSE 'sem W' END
      || ' *** betti_0 top1=100% em 3/3 dias ***');
   DBMS_OUTPUT.PUT_LINE('--- T2 C5 thresholds fixos (monitoramento — nao validados em d-30) ---');
   DBMS_OUTPUT.PUT_LINE('C5a  C4c+homog<=0.587       | '
      || LPAD(v_c5aw,4) || ' (' || LPAD(pct(v_c5aw,v_winners),5) || '%) | '
      || LPAD(v_c5an,5) || ' (' || LPAD(pct(v_c5an,v_nao),5) || '%) | '
      || CASE WHEN v_c5aw > 0 THEN ROUND(v_c5an/v_c5aw)||':1' ELSE 'sem W' END
      || ' [d=1.15 recall=100%]');
   DBMS_OUTPUT.PUT_LINE('C5b  C4c+coer_t>=0.804      | '
      || LPAD(v_c5bw,4) || ' (' || LPAD(pct(v_c5bw,v_winners),5) || '%) | '
      || LPAD(v_c5bn,5) || ' (' || LPAD(pct(v_c5bn,v_nao),5) || '%) | '
      || CASE WHEN v_c5bw > 0 THEN ROUND(v_c5bn/v_c5bw)||':1' ELSE 'sem W' END
      || ' [d=1.39 recall= 67%]');
   DBMS_OUTPUT.PUT_LINE('C5c  C4c+limiar>=10.930     | '
      || LPAD(v_c5cw,4) || ' (' || LPAD(pct(v_c5cw,v_winners),5) || '%) | '
      || LPAD(v_c5cn,5) || ' (' || LPAD(pct(v_c5cn,v_nao),5) || '%) | '
      || CASE WHEN v_c5cw > 0 THEN ROUND(v_c5cn/v_c5cw)||':1' ELSE 'sem W' END
      || ' [d=1.20 recall=100%]');
   DBMS_OUTPUT.PUT_LINE('C5d  C4c+homog&betti        | '
      || LPAD(v_c5dw,4) || ' (' || LPAD(pct(v_c5dw,v_winners),5) || '%) | '
      || LPAD(v_c5dn,5) || ' (' || LPAD(pct(v_c5dn,v_nao),5) || '%) | '
      || CASE WHEN v_c5dw > 0 THEN ROUND(v_c5dn/v_c5dw)||':1' ELSE 'sem W' END
      || ' *** META 1:1 recall=67% ***');

   -- ================================================================
   -- IDs POR MODO
   -- ================================================================
   DBMS_OUTPUT.PUT_LINE('');

   IF v_modo = 'PREDICAO' THEN
      DBMS_OUTPUT.PUT_LINE('=== CANDIDATOS (PREDICAO — PREMIO nao populado ainda) ===');
      DBMS_OUTPUT.PUT_LINE('Apos sorteio: verifique quais IDs do C1/C2 foram premiados.');
      print_ids(v_cand_q1,  '-- Q1 todos aprovados (' || v_cq1 || ') --');
      print_ids(v_cand_c2,   '-- C2: F1&F11 (' || v_cc2 || ' candidatos) passos>=11 & vel=NORMAL --');
      print_ids(v_cand_c4a,  '-- C4a: C2+zona=Z4+MESO (' || v_cc4a || ' candidatos) [5:1 validado] --');
      print_ids(v_cand_c4a2, '-- C4a2: C4a+grad=DESCENDO (' || v_cc4a2 || ' candidatos) *** META 1:1 limite fisico *** --');
      print_ids(v_cand_c4c,  '-- C4c: C2+PLAT+vol=IRREG (' || v_cc4c || ' candidatos) [74:1 d-30] --');
      print_ids(v_cand_c4c2, '-- C4c2: C4c+zona_pl=dest (' || v_cc4c2 || ' candidatos) [3:1 validado] --');
      print_ids(v_cand_c4c3, '-- C4c3: C4c2+zona=Z2 (' || v_cc4c3 || ' candidatos) *** Z2->Z2 ratio 1:1 potencial *** --');
      print_ids(v_cand_c4r,  '-- C4r: SEM F10/F11 TOP-2 betti_0 (' || v_cc4r || ' cands) [Arquetipo C — 41% W] --');
      print_ids(v_cand_c3r,  '-- C3r: C3+nmf=2 TOP-2 betti_0 (' || v_cc3r || ' cands) [winners sem F1] --');
      print_ids(v_cand_c5r,  '-- C5r: C4c TOP-2 betti_0 (' || v_cc5r || ' cands) *** RANKING — apostar aqui *** --');
      print_ids(v_cand_c5a,  '-- C5a: C4c+homog<=0.587 (' || v_cc5a || ' cands) [monitoramento] --');
      print_ids(v_cand_c5b,  '-- C5b: C4c+coer_t>=0.804 (' || v_cc5b || ' cands) [d=1.39 recall= 67%] --');
      print_ids(v_cand_c5c,  '-- C5c: C4c+limiar>=10.930 (' || v_cc5c || ' cands) [d=1.20 recall=100%] --');
      print_ids(v_cand_c5d,  '-- C5d: C4c+homog&betti (' || v_cc5d || ' cands) *** META 1:1 recall=67% *** --');
      print_ids(v_cand_c1,   '-- C1: F1&F10 (' || v_cc1 || ' candidatos) passos>=11 & iqr=N --');
      print_ids(v_cand_c3, '-- C3: F10&F11 (' || v_cc3 || ' candidatos) iqr=N & vel=NORMAL --');
   ELSE
      DBMS_OUTPUT.PUT_LINE('=== IDs PREMIADOS (HISTORICO — PREMIO populado) ===');
      print_ids(v_ids_q1, '-- Q1 (' || v_winners || ' premiados) --');
      print_ids(v_ids_c1, '-- C1: F1&F10 (' || v_c1w || ' premiados) --');
      print_ids(v_ids_c2, '-- C2: F1&F11 (' || v_c2w || ' premiados) --');
      print_ids(v_ids_c3,  '-- C3: F10&F11 (' || v_c3w || ' premiados) --');
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('-- C4a:  C2+zona=Z4+MESO       (' || v_c4aw  || ' premiados) [5:1 validado] --');
      DBMS_OUTPUT.PUT_LINE('-- C4a2: C4a+grad=DESCENDO     (' || v_c4a2w || ' premiados) *** META 1:1 ***');
      DBMS_OUTPUT.PUT_LINE('-- C4c:  C2+PLAT+vol=IRREG     (' || v_c4cw  || ' premiados) [74:1 d-30] --');
      DBMS_OUTPUT.PUT_LINE('-- C4c2: C4c+zona_pl=dest      (' || v_c4c2w || ' premiados) [3:1 validado] --');
      DBMS_OUTPUT.PUT_LINE('-- C4c3: C4c2+zona=Z2          (' || v_c4c3w || ' premiados) *** Z2->Z2 ratio 1:1 potencial *** --');
      DBMS_OUTPUT.PUT_LINE('--- T2 RANKING betti_0 (v9) ---');
      DBMS_OUTPUT.PUT_LINE('-- C4r: SEM F10/F11 TOP-2 betti_0 (' || v_c4rw || ' prem) [Arquetipo C — 41% W] --');
      DBMS_OUTPUT.PUT_LINE('-- C3r: C3+nmf=2 TOP-2 betti_0  (' || v_c3rw || ' prem) [winners sem F1] --');
      DBMS_OUTPUT.PUT_LINE('-- C5r: C4c TOP-2 betti_0       (' || v_c5rw || ' prem) *** RANKING — apostar aqui ***');
      DBMS_OUTPUT.PUT_LINE('--- T2 C5 thresholds (monitoramento) ---');
      DBMS_OUTPUT.PUT_LINE('-- C5a: C4c+homog<=0.587        (' || v_c5aw || ' prem) [monitoramento] --');
      DBMS_OUTPUT.PUT_LINE('-- C5b: C4c+coer_t>=0.804       (' || v_c5bw || ' prem) [d=1.39 recall= 67%] --');
      DBMS_OUTPUT.PUT_LINE('-- C5c: C4c+limiar>=10.930      (' || v_c5cw || ' prem) [d=1.20 recall=100%] --');
      DBMS_OUTPUT.PUT_LINE('-- C5d: C4c+homog&betti         (' || v_c5dw || ' prem) *** META 1:1 recall=67% ***');
   END IF;

   -- ================================================================
   -- ================================================================
   -- PERSISTÊNCIA EM TABELA (INSERTs diretos — sem procedures aninhadas)
   -- ================================================================
   BEGIN
      -- 1. Cabeçalho da execução (modo_exec ≠ v_modo para evitar conflito de nome)
      INSERT INTO tb_claude_exec_head
          (dt_referencia, modo_exec, run_label, total_q1, total_premios, total_nao_prem)
      VALUES
          (v_dt_ini, v_modo, v_run_label, v_total, v_winners, v_nao)
      RETURNING id_execucao INTO v_id_exec;

      -- Helper inline: converte ID para is_premio (PL/SQL — sem BOOLEAN em SQL)
      -- Para coleções simples (C4a2, C4c2, C4c3): usa v_prem_set
      -- Para pools ranking (C4r, C3r, C5r): usa campo .is_w da pool
      DECLARE
         v_i  PLS_INTEGER;
         v_ip VARCHAR2(1);
      BEGIN
         -- C4a2
         v_i := v_cand_c4a2.FIRST;
         WHILE v_i IS NOT NULL LOOP
            IF v_modo = 'HISTORICO' THEN
               IF v_prem_set.EXISTS(TO_NUMBER(v_cand_c4a2(v_i))) THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio)
            VALUES (v_id_exec, v_dt_ini, v_cand_c4a2(v_i), 'C4a2', v_ip);
            v_i := v_cand_c4a2.NEXT(v_i);
         END LOOP;
         -- C4c2
         v_i := v_cand_c4c2.FIRST;
         WHILE v_i IS NOT NULL LOOP
            IF v_modo = 'HISTORICO' THEN
               IF v_prem_set.EXISTS(TO_NUMBER(v_cand_c4c2(v_i))) THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio)
            VALUES (v_id_exec, v_dt_ini, v_cand_c4c2(v_i), 'C4c2', v_ip);
            v_i := v_cand_c4c2.NEXT(v_i);
         END LOOP;
         -- C4c3
         v_i := v_cand_c4c3.FIRST;
         WHILE v_i IS NOT NULL LOOP
            IF v_modo = 'HISTORICO' THEN
               IF v_prem_set.EXISTS(TO_NUMBER(v_cand_c4c3(v_i))) THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio)
            VALUES (v_id_exec, v_dt_ini, v_cand_c4c3(v_i), 'C4c3', v_ip);
            v_i := v_cand_c4c3.NEXT(v_i);
         END LOOP;
      END;
      -- Insere ranking pools (C4r, C3r, C5r) usando v_ip para evitar BOOLEAN em SQL
      DECLARE v_ip VARCHAR2(1); BEGIN
         -- C4r top-1
         IF v_top1_c4r IS NOT NULL THEN
            IF v_modo = 'HISTORICO' THEN
               IF v_c4r_pool(v_top1_c4r).is_w THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio,betti_0)
            VALUES (v_id_exec,v_dt_ini,v_c4r_pool(v_top1_c4r).id_orb,'C4r',v_ip,v_c4r_pool(v_top1_c4r).betti);
         END IF;
         -- C4r top-2
         IF v_top2_c4r IS NOT NULL THEN
            IF v_modo = 'HISTORICO' THEN
               IF v_c4r_pool(v_top2_c4r).is_w THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio,betti_0)
            VALUES (v_id_exec,v_dt_ini,v_c4r_pool(v_top2_c4r).id_orb,'C4r',v_ip,v_c4r_pool(v_top2_c4r).betti);
         END IF;
         -- C3r top-1
         IF v_top1_c3r IS NOT NULL THEN
            IF v_modo = 'HISTORICO' THEN
               IF v_c3r_pool(v_top1_c3r).is_w THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio,betti_0)
            VALUES (v_id_exec,v_dt_ini,v_c3r_pool(v_top1_c3r).id_orb,'C3r',v_ip,v_c3r_pool(v_top1_c3r).betti);
         END IF;
         -- C3r top-2
         IF v_top2_c3r IS NOT NULL THEN
            IF v_modo = 'HISTORICO' THEN
               IF v_c3r_pool(v_top2_c3r).is_w THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio,betti_0)
            VALUES (v_id_exec,v_dt_ini,v_c3r_pool(v_top2_c3r).id_orb,'C3r',v_ip,v_c3r_pool(v_top2_c3r).betti);
         END IF;
      END;
      DECLARE v_ip VARCHAR2(1); BEGIN
         -- C5r top-1
         IF v_top1_idx IS NOT NULL THEN
            IF v_modo = 'HISTORICO' THEN
               IF v_c5r_pool(v_top1_idx).is_w THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio,betti_0)
            VALUES (v_id_exec,v_dt_ini,v_c5r_pool(v_top1_idx).id_orb,'C5r',v_ip,v_c5r_pool(v_top1_idx).betti);
         END IF;
         -- C5r top-2
         IF v_top2_idx IS NOT NULL THEN
            IF v_modo = 'HISTORICO' THEN
               IF v_c5r_pool(v_top2_idx).is_w THEN v_ip := 'Y'; ELSE v_ip := 'N'; END IF;
            ELSE v_ip := 'P'; END IF;
            INSERT INTO tb_claude_diario_cand (id_execucao,dt_referencia,id_dados_orbita,filtro,is_premio,betti_0)
            VALUES (v_id_exec,v_dt_ini,v_c5r_pool(v_top2_idx).id_orb,'C5r',v_ip,v_c5r_pool(v_top2_idx).betti);
         END IF;
      END;

      COMMIT;
      DBMS_OUTPUT.PUT_LINE('');
      DBMS_OUTPUT.PUT_LINE('=== SALVO | id_execucao=' || v_id_exec
                           || ' | dt_ref=' || TO_CHAR(v_dt_ini,'DD/MM/YYYY')
                           || ' | modo=' || v_modo || ' ===');
   EXCEPTION
      WHEN OTHERS THEN
         ROLLBACK;
         DBMS_OUTPUT.PUT_LINE('[ERRO PERSIST] ' || SQLERRM);
   END;

END;
/
