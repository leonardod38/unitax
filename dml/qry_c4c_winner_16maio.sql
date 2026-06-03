-- Valida qual dos 16 IDs do C4c foi o winner de 16/05/2026
-- e exibe as colunas T2 para avaliar se C5 direto sobre C4c faz sentido

SELECT
    T1.ID_DADOS_ORBITA
  , STR_PARA_NUMERO(T1.PREMIO)                                AS premio
  , CASE WHEN STR_PARA_NUMERO(T1.PREMIO) > 0 THEN '*** WINNER ***' ELSE '' END AS flag
  -- T1: contexto do candidato C4c
  , T1.FORMA__DISTRIBUICAO                                    AS forma
  , T1.VOLAT_SEGMENTO__VOL_PADRAO                             AS vol_padrao
  , T1.ZONA__PLATO                                            AS zona_plato
  , T1.ZONA__DESTINO                                          AS zona_dest
  , CASE WHEN T1.ZONA__PLATO = T1.ZONA__DESTINO
         THEN 'SIM (C4c2)' ELSE 'NAO' END                    AS orbita_estavel
  , T1.ZONA__INICIAL                                          AS zona_ini
  , T1.GRADIENTE_FINAL__GRAD_CHEGADA                          AS grad_cheg
  -- T2: colunas C5 — avaliar separação winner vs NW
  , STR_PARA_NUMERO(T2.PRESM_G20_RANK_G15)                   AS rank_g15
  , STR_PARA_NUMERO(T2.PRESM_G21_FIS_BALANCO_FORCAS)         AS balanco_f
  , STR_PARA_NUMERO(T2.PRESM_G15_L1_VEL_SAI)                 AS g15_vel_sai
  -- T2: colunas adicionais de alta discriminação (Cohen's d > 0.30)
  , STR_PARA_NUMERO(T2.PRESM_G20_RANK_GLOBAL)                AS rank_global
  , STR_PARA_NUMERO(T2.PRESM_G21_FIS_DESVIO_EQUILIBRI)       AS desvio_equil
  , STR_PARA_NUMERO(T2.PRESM_G21_FIS_MOMENTO_ANGULAR)        AS momento_ang
  , STR_PARA_NUMERO(T2.PRESM_G22_FRONT_TIPICIDADE)           AS tipicidade
  , STR_PARA_NUMERO(T2.PRESM_G22_FRONT_EXCEPCIONAL)          AS excepcional
FROM ORBITAS_TABELAO1 T1
LEFT JOIN ORBITAS_TABELAO2 T2
       ON T2.ID_DADOS_ORBITA = T1.ID_DADOS_ORBITA
WHERE T1.ID_DADOS_ORBITA IN (
    12693508, 12693197, 12693028, 12693199, 12693070,
    12693190, 12693110, 12693353, 12693363, 12692867,
    12692935, 12692962, 12693696, 12693497, 12693591,
    12693571
)
ORDER BY STR_PARA_NUMERO(T1.PREMIO) DESC NULLS LAST
       , T1.ID_DADOS_ORBITA
