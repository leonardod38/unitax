-- Tipo   : DML
-- Objeto : qry_orbita_filtros_complexidade_v2
-- Salvo  : 2026-05-14
-- Origem : Reestruturação — funções PL/SQL eliminadas por inlining via CTE
-- Melhoria: 3 funções (VALIDA_PADRAO_VOLAT, VALIDA_PADRAO_VOLAT1, VALIDA_FUNIL_PREMIO)
--           substituídas por condições inline — elimina N+1 e context switch SQL->PL/SQL
-- ------------------------------------------------------------

WITH METRICAS AS (
   -- Calcula STR_PARA_NUMERO uma única vez por linha
   -- evitando chamadas repetidas nas condições do WHERE
   SELECT
      TAB1.ID_DADOS_ORBITA
      -- VALIDA_PADRAO_VOLAT: segmentos de volatilidade
    , STR_PARA_NUMERO(TAB1.VOLAT_SEGMENTO__VOL_INICIO)        AS vol_inicio
    , STR_PARA_NUMERO(TAB1.VOLAT_SEGMENTO__VOL_MEIO)          AS vol_meio
    , STR_PARA_NUMERO(TAB1.VOLAT_SEGMENTO__VOL_FIM)           AS vol_fim
      -- VALIDA_PADRAO_VOLAT1: rótulos de regime
    , TAB1.FUNIL_G10__G10_C_ROTULO_FUNIL                      AS g10c_funil
    , TAB1.VOLAT_SEGMENTO__VOL_PADRAO                         AS vol_padrao
    , TAB1.LYAPUNOV__LYAPUNOV_REGIME                          AS lyap_regime
    , TAB1.FUNIL_G10__G10_B_ROTULO_LATENT                     AS g10b_latent
    , TAB1.MARKOV_ZONAS__MARKOV_REGIME                        AS markov_regime
      -- VALIDA_FUNIL_PREMIO: rótulos G8/G9/G10
    , TAB1.FUNIL_G8__G8_N1_SLOPE_ROTULO                       AS g8_slope_rot
    , TAB1.FUNIL_G8__G8_N1_SLOPE_SUBROTU                      AS g8_slope_sub
    , TAB1.FUNIL_G8__G8_N1_R2L_ROTULO                         AS g8_r2l_rot
    , TAB1.FUNIL_G8__G8_N1_RMSE_ROTULO                        AS g8_rmse_rot
    , TAB1.FUNIL_G8__G8_N1_VEL_ENT_ROTULO                     AS g8_velent_rot
    , TAB1.FUNIL_G8__G8_N1_VEL_SAI_ROTULO                     AS g8_velsai_rot
    , TAB1.FUNIL_G8__G8_N1_D2_CRUZ_ROTULO                     AS g8_d2cruz_rot
    , TAB1.FUNIL_G8__G8_N1_ARCO_ROTULO                        AS g8_arco_rot
    , TAB1.FUNIL_G8__G8_N1_VAR_EXT_ROTULO                     AS g8_varext_rot
    , TAB1.FUNIL_G8__G8_N1_PROJ_ROTULO                        AS g8_proj_rot
    , TAB1.FUNIL_G9__G9_D2_ROTULO_CRUZA                       AS g9_d2_cruza
    , TAB1.FUNIL_G9__G9_D5_ROTULO_DIN                         AS g9_d5_din
    , TAB1.FUNIL_G10__G10_C_SUBROTU_INCER                     AS g10c_subincer
      -- VALIDA_FUNIL_PREMIO: features P3
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_SLOPE_P3_R2)       AS p3_r2_slope
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_SLOPE_P3_INF_T)    AS p3_inft_slope
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_R2L_P3_R2)         AS p3_r2_r2l
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_R2L_P3_INF_T)      AS p3_inft_r2l
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_RMSE_P3_COEF_A)    AS p3_coefa_rmse
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_RMSE_P3_R2)        AS p3_r2_rmse
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_RMSE_P3_INF_T)     AS p3_inft_rmse
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VEL_ENT_P3_R2)     AS p3_r2_velent
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VEL_ENT_P3_INF)    AS p3_inft_velent
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VEL_SAI_P3_R2)     AS p3_r2_velsai
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VEL_SAI_P3_INF)    AS p3_inft_velsai
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_ACEL_PICO_P3_R)    AS p3_r2_acel
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_ACEL_PICO_P3_I)    AS p3_inft_acel
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_D2_CRUZ_P3_R2)     AS p3_r2_d2cruz
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_D2_CRUZ_P3_INF)    AS p3_inft_d2cruz
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_RAZAO_VEL_P3_R)    AS p3_r2_razvel
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_RAZAO_VEL_P3_I)    AS p3_inft_razvel
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_AREA_TOT_P3_R2)    AS p3_r2_areat
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_AREA_TOT_P3_IN)    AS p3_inft_areat
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_ARCO_P3_R2)        AS p3_r2_arco
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_ARCO_P3_INF_T)     AS p3_inft_arco
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VAR_EXT_P3_R2)     AS p3_r2_varext
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VAR_EXT_P3_INF)    AS p3_inft_varext
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_PROJ_P3_R2)        AS p3_r2_proj
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_PROJ_P3_INF_T)     AS p3_inft_proj
      -- VALIDA_FUNIL_PREMIO: slopes
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_SLOPE_SLOPE)       AS slope_slope
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_R2L_SLOPE)         AS slope_r2l
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_RMSE_SLOPE)        AS slope_rmse
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VEL_ENT_SLOPE)     AS slope_velent
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VEL_SAI_SLOPE)     AS slope_velsai
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_D2_CRUZ_SLOPE)     AS slope_d2cruz
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_AREA_TOT_SLOPE)    AS slope_areat
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_ARCO_SLOPE)        AS slope_arco
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_VAR_EXT_SLOPE)     AS slope_varext
    , STR_PARA_NUMERO(TAB1.FUNIL_G8__G8_N1_PROJ_SLOPE)        AS slope_proj
   FROM ORBITAS_TABELAO1 TAB1
)
SELECT DD.ID_DADOS_ORBITA
     , TRUNC(DD.TIMESTAMP_EXECUCAO_INS)   DATA_EXECUCAO
     , DD.CORRIDA
     , DD.PREMIO
     , DD.MILHAR
     , DD.TXT                             CONTEUDO_TXT
     , DD.TIMESTAMP_EXECUCAO_INS
     , DD.BICHO
  FROM DADOS_ORBITA              DD
  JOIN METRICAS                  M    ON M.ID_DADOS_ORBITA   = DD.ID_DADOS_ORBITA
  JOIN ORBITA_MILHARES_FILTRADAS F    ON F.ID_DADOS_ORBITA   = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS <  TRUNC(SYSDATE - 1) + 19/24
   -- Filtros de classificação TAB1
   AND M.g10c_funil              = 'FUNIL_PARCIALMENTE_CONVERGENTE'
   AND M.g10c_subincer           = 'ROTULOS_CONFLITANTES'
   -- VALIDA_PADRAO_VOLAT: segmentos de volatilidade
   AND M.vol_inicio             >= 1300
   AND M.vol_inicio              > 0
   AND M.vol_inicio              IS NOT NULL
   AND M.vol_meio                IS NOT NULL
   AND M.vol_fim                 IS NOT NULL
   AND (M.vol_fim / M.vol_inicio) BETWEEN 0.5 AND 2.1
   AND (   (M.vol_inicio < M.vol_meio AND M.vol_meio < M.vol_fim)   -- ACUMULA_INSTAB
        OR (M.vol_inicio > M.vol_meio AND M.vol_meio > M.vol_fim)   -- CONVERGE_TARDIA
        OR (M.vol_meio < M.vol_inicio AND M.vol_meio < M.vol_fim)   -- RESPIRO_CENTRAL
        OR (M.vol_meio > M.vol_inicio AND M.vol_meio > M.vol_fim)   -- PICO_CENTRAL
       )
   -- VALIDA_PADRAO_VOLAT1: rótulos de regime
   AND M.vol_padrao    IN ('IRREGULAR', 'CRESCENTE')
   AND M.lyap_regime   IN ('INSTAVEL', 'NEUTRO')
   AND M.g10b_latent   IN ('MODO_DOMINANTE_UNICO', 'TRES_MODOS_PRINCIPAIS', 'ESTRUTURA_DIFUSA')
   AND M.markov_regime IN ('ERGODICA', 'MISTURA_MEDIA', 'MISTURA_RAPIDA')
   -- VALIDA_FUNIL_PREMIO — Bloco 1: 14 rótulos invariantes
   AND M.g8_slope_rot  = 'QUASE_LINEAR'
   AND M.g8_slope_sub  = 'FASE_ESTABILIZADA'
   AND M.g8_r2l_rot    = 'QUASE_LINEAR'
   AND M.g8_rmse_rot   = 'QUASE_LINEAR'
   AND M.g8_velent_rot = 'QUASE_LINEAR'
   AND M.g8_velsai_rot = 'QUASE_LINEAR'
   AND M.g8_d2cruz_rot = 'QUASE_LINEAR'
   AND M.g8_arco_rot   = 'QUASE_LINEAR'
   AND M.g8_varext_rot = 'QUASE_LINEAR'
   AND M.g8_proj_rot   = 'QUASE_LINEAR'
   AND M.g9_d2_cruza   = 'ACOPLAMENTO_MEDIO'
   AND M.g9_d5_din     = 'SISTEMA_REGULAR'
   -- VALIDA_FUNIL_PREMIO — Bloco 2: 25 features P3 (R²=0.9647, INF_T=0.3787, COEF_A=-0.0005)
   AND ABS(M.p3_r2_slope    - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_slope  - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_r2l      - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_r2l    - 0.3787)  <= 0.001
   AND ABS(M.p3_coefa_rmse  - (-0.0005)) <= 0.001
   AND ABS(M.p3_r2_rmse     - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_rmse   - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_velent   - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_velent - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_velsai   - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_velsai - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_acel     - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_acel   - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_d2cruz   - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_d2cruz - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_razvel   - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_razvel - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_areat    - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_areat  - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_arco     - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_arco   - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_varext   - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_varext - 0.3787)  <= 0.001
   AND ABS(M.p3_r2_proj     - 0.9647)  <= 0.001
   AND ABS(M.p3_inft_proj   - 0.3787)  <= 0.001
   -- VALIDA_FUNIL_PREMIO — Bloco 3: 10 slopes
   AND M.slope_slope  BETWEEN -0.0019 AND 0.0020
   AND M.slope_r2l    BETWEEN  0.0001 AND 0.0018
   AND M.slope_rmse   BETWEEN  0.0030 AND 0.0040
   AND M.slope_velent BETWEEN -0.0039 AND 0.0037
   AND M.slope_velsai BETWEEN -0.0035 AND 0.0038
   AND M.slope_d2cruz BETWEEN -0.0025 AND 0.0026
   AND M.slope_areat  BETWEEN  0.0129 AND 0.0150
   AND M.slope_arco   BETWEEN  0.0056 AND 0.0070
   AND M.slope_varext BETWEEN  0.0041 AND 0.0077
   AND M.slope_proj   BETWEEN  0.0044 AND 0.0069
   -- Filtros de classificação adicionais
   AND M.g8_slope_rot   = 'QUASE_LINEAR'
   AND M.g8_r2l_rot     = 'QUASE_LINEAR'
   -- Exclusão de orbitas já aprovadas
   AND NOT EXISTS (
          SELECT 1
            FROM ORBITAS_APROVADAS B
           WHERE B.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
       )
;
