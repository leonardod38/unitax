-- Tipo   : QUERY DE REFINAMENTO
-- Objeto : qry_refino_c4c_zona_plato_dest
-- Salvo  : 2026-05-17
-- Objetivo: Validar se zona_plato=zona_dest é o 3o filtro do C4c
--           Os 2 winners conhecidos do C4c têm zona_plato=zona_dest (orbita estavel)
--           Se dos 75 NW do C4c poucos também têm → ratio cai de 74:1 para ≤10:1
-- Contexto: Run d-30 (16/04 a 16/05/2026), C4c = C2 + PLATICURTICA + vol=IRREGULAR
-- Leitura : Se zona_estavel <= 10 → C4c_v2 atinge a meta
-- ------------------------------------------------------------

-- 1. Contagem geral: quantos dos C4c têm zona_plato = zona_destino
WITH q1_base AS (
   SELECT MIN(T3.ID_DADOS_ORBITA) AS id_repr
     FROM DADOS_ORBITA     DD
     JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
    WHERE DD.TIMESTAMP_EXECUCAO_INS >= TO_DATE('16/04/2026','DD/MM/YYYY') + 18/24
      AND DD.TIMESTAMP_EXECUCAO_INS <  TO_DATE('16/05/2026','DD/MM/YYYY') + 19/24
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
, c4c_pool AS (
   SELECT P.ID_DADOS_ORBITA
        , P.ZONA__PLATO
        , P.ZONA__DESTINO
        , P.ZONA__INICIAL
        , P.ZONA__TRANSICAO
        , STR_PARA_NUMERO(P.PREMIO) AS premio
     FROM q1_base
     JOIN ORBITAS_TABELAO1 P ON P.ID_DADOS_ORBITA = q1_base.id_repr
    WHERE STR_PARA_NUMERO(P.COMP_APOS_PICO__DESCIDA_PASSOS) >= 11
      AND P.PLATO_ABISMO__VELOCIDADE   = 'NORMAL'
      AND P.FORMA__DISTRIBUICAO        = 'PLATICURTICA'
      AND P.VOLAT_SEGMENTO__VOL_PADRAO = 'IRREGULAR'
)
SELECT
   COUNT(*)                                                                     AS total_c4c
 , SUM(CASE WHEN ZONA__PLATO  = ZONA__DESTINO THEN 1 ELSE 0 END)               AS zona_estavel
 , SUM(CASE WHEN ZONA__PLATO != ZONA__DESTINO THEN 1 ELSE 0 END)               AS zona_instavel
 , SUM(CASE WHEN ZONA__PLATO  = ZONA__DESTINO
             AND premio > 0   THEN 1 ELSE 0 END)                                AS estavel_winner
 , ROUND(
     SUM(CASE WHEN ZONA__PLATO = ZONA__DESTINO THEN 1 ELSE 0 END) * 100
     / NULLIF(COUNT(*), 0), 1)                                                  AS pct_estavel
  FROM c4c_pool
/

-- 2. Distribuição detalhada por zona — entender os padrões dentro do C4c
WITH q1_base AS (
   SELECT MIN(T3.ID_DADOS_ORBITA) AS id_repr
     FROM DADOS_ORBITA     DD
     JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
    WHERE DD.TIMESTAMP_EXECUCAO_INS >= TO_DATE('16/04/2026','DD/MM/YYYY') + 18/24
      AND DD.TIMESTAMP_EXECUCAO_INS <  TO_DATE('16/05/2026','DD/MM/YYYY') + 19/24
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
, c4c_pool AS (
   SELECT P.ID_DADOS_ORBITA
        , P.ZONA__PLATO
        , P.ZONA__DESTINO
        , CASE WHEN P.ZONA__PLATO = P.ZONA__DESTINO
               THEN 'ESTAVEL' ELSE 'MOVE' END          AS estabilidade
        , STR_PARA_NUMERO(P.PREMIO)                    AS premio
     FROM q1_base
     JOIN ORBITAS_TABELAO1 P ON P.ID_DADOS_ORBITA = q1_base.id_repr
    WHERE STR_PARA_NUMERO(P.COMP_APOS_PICO__DESCIDA_PASSOS) >= 11
      AND P.PLATO_ABISMO__VELOCIDADE   = 'NORMAL'
      AND P.FORMA__DISTRIBUICAO        = 'PLATICURTICA'
      AND P.VOLAT_SEGMENTO__VOL_PADRAO = 'IRREGULAR'
)
SELECT
   ZONA__PLATO
 , ZONA__DESTINO
 , estabilidade
 , COUNT(*)                                          AS qtde
 , SUM(CASE WHEN premio > 0 THEN 1 ELSE 0 END)      AS winners
  FROM c4c_pool
 GROUP BY ZONA__PLATO, ZONA__DESTINO, estabilidade
 ORDER BY estabilidade, qtde DESC, ZONA__PLATO
/
