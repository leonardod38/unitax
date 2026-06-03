-- Tipo   : QUERY DE REFINAMENTO
-- Objeto : qry_refino_c2_winners_fora_c4a
-- Salvo  : 2026-05-17
-- Objetivo: Encontrar os 2 winners do C2 que NÃO passaram C4a
--           → entender qual padrão têm → construir C4c para eles
-- Contexto: Run d-30 sem prêmio (17/04 a 17/05/2026)
--           C2 teve 3 winners. C4a capturou 1 (o ID 12602918).
--           Os 2 restantes passaram passos>=11 & vel=NORMAL
--           mas NÃO têm zona_ini=Z4 e/ou forma=MESOCURTICA.
-- Leitura : Comparar zona_ini e forma dos 2 winners entre si.
--           Ver qual outro par (zona, forma) poderia virar C4c.
-- ------------------------------------------------------------
WITH q1_base AS (
   SELECT MIN(T3.ID_DADOS_ORBITA) AS id_repr
     FROM DADOS_ORBITA     DD
     JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
    WHERE DD.TIMESTAMP_EXECUCAO_INS >= TO_DATE('17/04/2026','DD/MM/YYYY') + 18/24
      AND DD.TIMESTAMP_EXECUCAO_INS <  TO_DATE('17/05/2026','DD/MM/YYYY') + 19/24
      -- Q1 v11
      AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)         >= -200
      AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)         >= -400
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
SELECT
   P.ID_DADOS_ORBITA

   -- Classificação dentro do C2
 , CASE
      WHEN P.ZONA__INICIAL      = 'Z4'
       AND P.FORMA__DISTRIBUICAO = 'MESOCURTICA' THEN 'C4a-winner'
      ELSE 'C2-winner-sem-C4a'
   END                                                                         AS classificacao

   -- Condições C4a: ver por que não passou
 , P.ZONA__INICIAL                                                              AS zona_ini
 , P.FORMA__DISTRIBUICAO                                                        AS forma_dist

   -- Identificar padrão alternativo
 , P.ZONA__DESTINO                                                               AS zona_dest
 , P.ZONA__PLATO                                                                 AS zona_plato
 , P.ZONA__TRANSICAO                                                             AS zona_trans

   -- DERIVADAS
 , STR_PARA_NUMERO(P.DERIVADAS__D1_MEDIA)                                      AS d1
 , STR_PARA_NUMERO(P.DERIVADAS__D2_MEDIA)                                      AS d2
 , STR_PARA_NUMERO(P.DERIVADAS__MAGNITUDE_ABISMO)                              AS mag_ab

   -- C2 filtros (confirmação)
 , STR_PARA_NUMERO(P.COMP_APOS_PICO__DESCIDA_PASSOS)                           AS passos
 , P.PLATO_ABISMO__VELOCIDADE                                                   AS vel
 , STR_PARA_NUMERO(P.COMP_APOS_PICO__IDX_PICO)                                 AS idx_pico
 , STR_PARA_NUMERO(P.COMP_APOS_PICO__DESCIDA_DEGRAU)                           AS degrau
 , P.COMP_APOS_PICO__DESCIDA_TIPO                                               AS descida_tipo

   -- Potenciais filtros para C4c
 , STR_PARA_NUMERO(P.PLATO_ABISMO__MAGNITUDE)                                  AS plato_mag
 , P.PLATO_ABISMO__INTENSIDADE                                                  AS plato_int
 , STR_PARA_NUMERO(P.BASICO__MAX)                                               AS basico_max
 , STR_PARA_NUMERO(P.MOMENTUM__RAZAO_FINAL_TOTAL)                              AS mom_razao
 , P.MOMENTUM__ACELERANDO                                                        AS mom_acel
 , STR_PARA_NUMERO(P.AUTOCORRELACAO__AC_LAG1)                                   AS ac_lag1
 , STR_PARA_NUMERO(P.GRADIENTE_FINAL__GRAD_VEL_MEDI)                           AS grad_vel
 , P.GRADIENTE_FINAL__GRAD_CHEGADA                                              AS grad_cheg
 , P.PERCENTIS__FINAL_NO_IQR                                                     AS perc_iqr
 , STR_PARA_NUMERO(P.COMPRIMENTO_ARCO__COMPRIMENTO_)                            AS arco
 , P.VOLAT_SEGMENTO__VOL_PADRAO                                                  AS vol_padrao
 , P.RAZAO_SUF_MIL__RAZAO_TENDENCIA                                             AS razao_tend
 , STR_PARA_NUMERO(P.PADRAO_MILHAR__PARADA_FINAL)                              AS parada_final

  FROM q1_base
  JOIN ORBITAS_TABELAO1 P ON P.ID_DADOS_ORBITA = q1_base.id_repr
 WHERE -- C2: passos>=11 AND vel=NORMAL
       STR_PARA_NUMERO(P.COMP_APOS_PICO__DESCIDA_PASSOS) >= 11
   AND P.PLATO_ABISMO__VELOCIDADE = 'NORMAL'
   -- apenas winners
   AND STR_PARA_NUMERO(P.PREMIO) > 0
 ORDER BY
   -- winner de C4a primeiro, depois os sem-C4a
   CASE WHEN P.ZONA__INICIAL = 'Z4' AND P.FORMA__DISTRIBUICAO = 'MESOCURTICA'
        THEN 0 ELSE 1 END
 , P.ID_DADOS_ORBITA;
