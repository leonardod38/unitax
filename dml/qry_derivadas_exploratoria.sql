-- Tipo   : DML
-- Objeto : qry_derivadas_exploratoria
-- Salvo  : 2026-05-15
-- Origem : Análise exploratória das colunas DERIVADAS__ em ORBITAS_TABELAO1
-- Base   : 773 registros analisados no derivadas.csv
--          Calibrado com resultado real Q8 (211 registros — filtro 18h–19h)
-- Padrões confirmados pelo Q8 real:
--   - D2 positivo apenas em D1 >= 100 (+10.41 médio, +64.59 forte)
--   - D2 negativo em D1 < 100  (-111.22 decrescente, -75.96 leve)
--   - IDX_ABISMO_MEDIO entre 9.5 e 11.02 para todos os grupos
--   - 3.3% sem abismo (7/211) — distribuídos em todos os grupos
--   - Crescimento médio (100–250): abismo mais tardio (11.02) e mais profundo entre crescentes
-- ------------------------------------------------------------

-- ============================================================
-- BASE reutilizável: aplica a todas as queries abaixo
-- ============================================================
-- FROM DADOS_ORBITA DD
-- JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
-- WHERE DD.TIMESTAMP_EXECUCAO_INS >= TRUNC(SYSDATE - 1) + 18/24
--   AND DD.TIMESTAMP_EXECUCAO_INS <  TRUNC(SYSDATE - 1) + 19/24
-- ------------------------------------------------------------


-- ============================================================
-- Q1: TENDÊNCIA — Crescimento genuíno (D1 >= 100, D2 positivo confirmado)
-- Calibrado: threshold elevado de > 0 para >= 100.
-- Q8 confirmou: D2 só é positivo para D1 >= 100 (médio +10.41, forte +64.59).
-- D1 entre 0–100 já está desacelerando (D2=-75.96) — não é crescimento consistente.
-- Ajuste Q1_AJUSTE.csv (614 registros analisados):
--   P1: D2 < 0 aparece já em D1=492 — desaceleração mascarada em ~50% dos registros
--   P3: razão D1_DESVIO/D1_MEDIA > 10 indica oscilação dominando a tendência
--   P4: abs(D1_MIN)/D1_MEDIA > 15 indica reversões internas extremas
-- ============================================================
SELECT DISTINCT
       T3.ID_DADOS_ORBITA
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)    D1_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MAX)       D1_MAX
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MIN)       D1_MIN
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_DESVIO)    D1_DESVIO
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)     D2_MEDIA
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE - 1) + 19/24
   AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)   >= 100    -- crescimento genuíno (médio ou forte)
   -- Ruído 2: cap absoluto restaurado — P3 (ratio) é leniente para D1 alto;
   -- sem este limite, D1_DESVIO de até 4.940 passava para D1=494 (Q1_AJUSTE_V1.csv)
   AND STR_PARA_NUMERO(T3.DERIVADAS__D1_DESVIO)  <  4000
   -- P1: remove desaceleração mascarada — D2 deve ser positivo para crescimento genuíno
   -- (D2 < 0 encontrado já em D1=492; abaixo de D1=300 é predominante)
   AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)   >= 0
   -- P3: remove desvio desproporcional — oscilação não pode dominar a tendência (razão máx. 10x)
   -- age em conjunto com o cap absoluto acima: ambos precisam ser satisfeitos
   -- (ex: D1=100 com D1_DESVIO=3665 → razão 36,6x — instável)
   AND STR_PARA_NUMERO(T3.DERIVADAS__D1_DESVIO)
       <= STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) * 10
   -- P4: remove reversões internas extremas — D1_MIN não pode ser 15x maior (módulo) que a média
   -- (ex: D1=214 com D1_MIN=-8997 → razão 42x — queda abrupta estrutural)
   AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MIN)
       >= -(STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) * 15)
 ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) DESC
;


-- ============================================================
-- Q2: DESACELERAÇÃO — D2 negativa com abismo confirmado
-- Calibrado: adicionado D1_MEDIA < 100.
-- Q8 confirmou: D2 negativo concentra-se em decrescente (-111.22) e leve (-75.96).
-- Magnitude -4000 mantida: decrescente avg -5568 e leve avg -4548 excedem o threshold.
-- 103 registros esperados (decrescente 59 + leve 44).
-- ============================================================
SELECT T3.ID_DADOS_ORBITA
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)           D1_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)           D2_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MIN)             D2_MIN
     , STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)         IDX_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO)   MAGNITUDE_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NO_ABISMO)   MILHAR_NO_ABISMO
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE - 1) + 19/24
   AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)         < 100     -- decrescente ou crescimento leve (D2 negativo no Q8)
   AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)         < 0       -- desacelerando
   AND STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)       >= 0      -- abismo confirmado
   AND STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO) < -4000   -- queda expressiva
 ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO) ASC
;


-- ============================================================
-- Q3: ABISMO TARDIO — Abismo no final da série (IDX entre 10 e 12)
-- Calibrado: limite superior reduzido de 15 para 12.
-- Q8 confirmou: IDX_ABISMO_MEDIO máximo = 11.02 (crescimento médio).
-- Todos os grupos têm média entre 9.5 e 11.02 — limite 12 é mais preciso.
-- Crescimento médio (D1 100–250) é o grupo com abismo mais tardio.
-- ============================================================
SELECT T3.ID_DADOS_ORBITA
     , STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)         IDX_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO)   MAGNITUDE_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NO_ABISMO)   MILHAR_NO_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)           D1_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)           D2_MEDIA
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE - 1) + 19/24
   AND STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO) BETWEEN 10 AND 12   -- limite superior reduzido (médias reais: 9.5–11.02)
 ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)       DESC
        , STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO) ASC
;


-- ============================================================
-- Q4: PARADA CENTRAL — Parada no meio da série (IDX_PARADA 5 a 8)
-- Calibrado: limite superior reduzido de 10 para 8.
-- Base: média IDX_PARADA = 6.98 (derivadas.csv).
-- Q8 confirma abismo ocorre em média aos 10+ — parada precede o abismo.
-- Faixa 5–8 captura o padrão real antes da queda.
-- ============================================================
SELECT T3.ID_DADOS_ORBITA
     , STR_PARA_NUMERO(T3.DERIVADAS__IDX_PARADA)         IDX_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__FORCA_PARADA)       FORCA_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NA_PARADA)   MILHAR_NA_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)           D1_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)           D2_MEDIA
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE - 1) + 19/24
   AND STR_PARA_NUMERO(T3.DERIVADAS__IDX_PARADA) BETWEEN 5 AND 8    -- centrado na média real 6.98
 ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__FORCA_PARADA) DESC
;


-- ============================================================
-- Q5: PADRÃO IDEAL — Crescimento leve + desacelerando + abismo tardio
-- Calibrado: D1 explicitado como BETWEEN 0 AND 100 (crescimento leve).
-- Q8 confirmou: crescimento leve (0–100) é o único grupo com D1>0 E D2<0.
--   D2_MEDIA = -75.96, IDX_ABISMO_MEDIO = 10.45 → 44 registros esperados.
-- ============================================================
SELECT T3.ID_DADOS_ORBITA
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)           D1_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)           D2_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__IDX_PARADA)         IDX_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__FORCA_PARADA)       FORCA_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NA_PARADA)   MILHAR_NA_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)         IDX_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO)   MAGNITUDE_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NO_ABISMO)   MILHAR_NO_ABISMO
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE - 1) + 19/24
   AND STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)   BETWEEN 0 AND 100  -- crescimento leve (único grupo D1>0 e D2<0 no Q8)
   AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)   < 0                -- desacelerando
   AND STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO) >= 10              -- abismo tardio (média grupo = 10.45)
 ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) DESC
;


-- ============================================================
-- Q6: ANOMALIAS — Quedas abruptas extremas (D2_MIN < -10000)
-- Calibrado: adicionada coluna FAIXA_D1 ao SELECT.
-- Q8: decrescente tem D2_MEDIA mais negativo (-111.22) — anomalias concentram-se ali.
-- A coluna FAIXA_D1 permite identificar em qual grupo a anomalia ocorre.
-- D2_MIN mínimo observado: -17.068 (derivadas.csv).
-- ============================================================
SELECT T3.ID_DADOS_ORBITA
     , CASE
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 0              THEN '1. Decrescente'
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 100            THEN '2. Crescimento leve'
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 250            THEN '3. Crescimento médio'
          ELSE                                                                '4. Crescimento forte'
       END                                                               FAIXA_D1
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MIN)             D2_MIN
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)           D2_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MAX)             D2_MAX
     , STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO)   MAGNITUDE_ABISMO
     , STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)         IDX_ABISMO
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE - 1) + 19/24
   AND STR_PARA_NUMERO(T3.DERIVADAS__D2_MIN) < -10000
 ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__D2_MIN) ASC
;


-- ============================================================
-- Q7: SEM ABISMO — Orbitas sem queda identificada (IDX_ABISMO = -1)
-- Calibrado: adicionada coluna FAIXA_D1 ao SELECT.
-- Q8 real: 7 registros — 2 decrescente, 3 leve, 1 médio, 1 forte.
-- A coluna FAIXA_D1 permite confirmar a distribuição por grupo.
-- IDX_ABISMO = -1 é sentinela de ausência de abismo.
-- ============================================================
SELECT T3.ID_DADOS_ORBITA
     , CASE
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 0              THEN '1. Decrescente'
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 100            THEN '2. Crescimento leve'
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 250            THEN '3. Crescimento médio'
          ELSE                                                                '4. Crescimento forte'
       END                                                               FAIXA_D1
     , STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA)           D1_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)           D2_MEDIA
     , STR_PARA_NUMERO(T3.DERIVADAS__IDX_PARADA)         IDX_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__FORCA_PARADA)       FORCA_PARADA
     , STR_PARA_NUMERO(T3.DERIVADAS__MILHAR_NA_PARADA)   MILHAR_NA_PARADA
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE - 1) + 19/24
   AND STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO) = -1
 ORDER BY STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) DESC
;


-- ============================================================
-- Q8: RESUMO ESTATÍSTICO — Agrupamento por faixa de D1_MEDIA
-- Calibrado: corrigido overlap nas bordas do CASE (usar < ao invés de BETWEEN).
--   Antes: BETWEEN 0 AND 100 e BETWEEN 100 AND 250 → valor 100 entrava em ambas.
--   Depois: >= 0 AND < 100 e >= 100 AND < 250 → sem ambiguidade.
-- Adicionado: D2_NEG_COUNT (contagem de séries com D2<0 por grupo).
-- ============================================================
SELECT CASE
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 0              THEN '1. Decrescente        (< 0)'
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 100            THEN '2. Crescimento leve   (0–100)'
          WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 250            THEN '3. Crescimento médio  (100–250)'
          ELSE                                                                '4. Crescimento forte  (>= 250)'
       END                                                               FAIXA_D1
     , COUNT(*)                                                          QTDE
     , ROUND(AVG(STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)),  2)          D2_MEDIA_MEDIA
     , ROUND(AVG(STR_PARA_NUMERO(T3.DERIVADAS__MAGNITUDE_ABISMO)), 2)   MAG_ABISMO_MEDIA
     , ROUND(AVG(STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO)),  2)        IDX_ABISMO_MEDIO
     , SUM(CASE WHEN STR_PARA_NUMERO(T3.DERIVADAS__IDX_ABISMO) = -1
                THEN 1 ELSE 0 END)                                       SEM_ABISMO
     , SUM(CASE WHEN STR_PARA_NUMERO(T3.DERIVADAS__D2_MEDIA)  < 0
                THEN 1 ELSE 0 END)                                       D2_NEG_COUNT
  FROM DADOS_ORBITA     DD
  JOIN ORBITAS_TABELAO1 T3 ON T3.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS <  TRUNC(SYSDATE - 1) + 19/24
 GROUP BY CASE
             WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 0              THEN '1. Decrescente        (< 0)'
             WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 100            THEN '2. Crescimento leve   (0–100)'
             WHEN STR_PARA_NUMERO(T3.DERIVADAS__D1_MEDIA) < 250            THEN '3. Crescimento médio  (100–250)'
             ELSE                                                                '4. Crescimento forte  (>= 250)'
          END
 ORDER BY 1
;
