-- Tipo   : QUERY DE REFINAMENTO
-- Objeto : qry_refino_c4a_falsos_positivos
-- Salvo  : 2026-05-17
-- Objetivo: Identificar qual dos 6 C4a é o 1 winner e quem são os 5 NW
--           → encontrar o 5º filtro que elimina os 5 NW sem remover o winner
-- Origem  : Run d-30 sem prêmio (17/04 a 17/05/2026), C4a = 6 cands (1W, 5NW, ratio 5:1)
-- IDs     : 12602918, 12599690, 12599668, 12663458, 12663110, 12688048
-- Leitura : O winner terá PREMIO > 0. Comparar cada coluna do winner vs os 5 NW.
--           Procurar coluna onde o winner tem valor claramente distinto dos 5 NW.
-- ------------------------------------------------------------
SELECT
   T.ID_DADOS_ORBITA

   -- CLASSIFICAÇÃO (winner ou NW)
 , CASE WHEN STR_PARA_NUMERO(T.PREMIO) > 0 THEN 'WINNER' ELSE 'NW' END       AS tipo

   -- C4a: filtros já aplicados (todos devem ser Z4 / MESOCURTICA / passos>=11 / NORMAL)
 , T.ZONA__INICIAL                                                              AS zona_ini
 , T.FORMA__DISTRIBUICAO                                                        AS forma_dist
 , STR_PARA_NUMERO(T.COMP_APOS_PICO__DESCIDA_PASSOS)                           AS passos
 , T.PLATO_ABISMO__VELOCIDADE                                                   AS vel

   -- DERIVADAS base
 , STR_PARA_NUMERO(T.DERIVADAS__D1_MEDIA)                                      AS d1
 , STR_PARA_NUMERO(T.DERIVADAS__D2_MEDIA)                                      AS d2
 , STR_PARA_NUMERO(T.DERIVADAS__MAGNITUDE_ABISMO)                              AS mag_ab
 , STR_PARA_NUMERO(T.DERIVADAS__MILHAR_NO_ABISMO)                              AS m_ab

   -- COMP_APOS_PICO (grupo mais discriminador)
 , STR_PARA_NUMERO(T.COMP_APOS_PICO__IDX_PICO)                                 AS idx_pico
 , STR_PARA_NUMERO(T.COMP_APOS_PICO__DESCIDA_DEGRAU)                           AS degrau
 , STR_PARA_NUMERO(T.COMP_APOS_PICO__DESCIDA_VEL_ME)                           AS vel_me
 , T.COMP_APOS_PICO__DESCIDA_TIPO                                               AS descida_tipo

   -- PLATO_ABISMO
 , STR_PARA_NUMERO(T.PLATO_ABISMO__MAGNITUDE)                                  AS plato_mag
 , STR_PARA_NUMERO(T.PLATO_ABISMO__FORCA_PLATO)                                AS plato_forca
 , STR_PARA_NUMERO(T.PLATO_ABISMO__MILHAR_DESTINO)                             AS plato_dest
 , T.PLATO_ABISMO__INTENSIDADE                                                  AS plato_int

   -- BASICO
 , STR_PARA_NUMERO(T.BASICO__MAX)                                               AS basico_max
 , STR_PARA_NUMERO(T.BASICO__MIN)                                               AS basico_min
 , STR_PARA_NUMERO(T.BASICO__AMPLITUDE)                                         AS amplitude

   -- MOMENTUM
 , STR_PARA_NUMERO(T.MOMENTUM__RAZAO_FINAL_TOTAL)                              AS mom_razao
 , T.MOMENTUM__ACELERANDO                                                        AS mom_acel

   -- GRADIENTE_FINAL
 , STR_PARA_NUMERO(T.GRADIENTE_FINAL__GRAD_VEL_MEDI)                           AS grad_vel
 , T.GRADIENTE_FINAL__GRAD_CHEGADA                                              AS grad_cheg
 , T.GRADIENTE_FINAL__GRAD_ACELERAD                                             AS grad_acel

   -- ZONA
 , T.ZONA__DESTINO                                                               AS zona_dest
 , T.ZONA__PLATO                                                                 AS zona_plato
 , T.ZONA__TRANSICAO                                                             AS zona_trans

   -- AUTOCORRELACAO
 , STR_PARA_NUMERO(T.AUTOCORRELACAO__AC_LAG1)                                   AS ac_lag1

   -- PERCENTIS
 , T.PERCENTIS__FINAL_NO_IQR                                                     AS perc_iqr
 , STR_PARA_NUMERO(T.PERCENTIS__P50)                                             AS p50
 , STR_PARA_NUMERO(T.PERCENTIS__P75)                                             AS p75

   -- COMPRIMENTO_ARCO
 , STR_PARA_NUMERO(T.COMPRIMENTO_ARCO__COMPRIMENTO_)                            AS arco
 , T.COMPRIMENTO_ARCO__TRAJETORIA_T                                              AS traj_tipo

   -- PARADA_FINAL
 , STR_PARA_NUMERO(T.PADRAO_MILHAR__PARADA_FINAL)                              AS parada_final

   -- VOLATILIDADE
 , T.VOLAT_SEGMENTO__VOL_PADRAO                                                  AS vol_padrao

   -- RAZAO SUF_MIL
 , T.RAZAO_SUF_MIL__RAZAO_TENDENCIA                                             AS razao_tend

  FROM ORBITAS_TABELAO1 T
 WHERE T.ID_DADOS_ORBITA IN (12602918, 12599690, 12599668, 12663458, 12663110, 12688048)
 ORDER BY STR_PARA_NUMERO(T.PREMIO) DESC
        , T.ID_DADOS_ORBITA;
