-- Exporta colunas T1 necessárias para aplicar filtros Q1+C3+C4c em Python
-- v2: adicionado perc_iqr (F10) para permitir análise do pool C3 (F10+F11)
-- Período: mesmo do ORBITAS_TABELAO2_V1.csv
-- Salvar como: plsql/arquivo_csv/ORBITAS_TABELAO_V2.csv (separador ;) — substitui o anterior

SELECT
    T1.ID_DADOS_ORBITA
  , T1.PREMIO
  -- Q1: filtros de entrada
  , T1.DERIVADAS__D1_MEDIA              AS d1_media
  , T1.DERIVADAS__D2_MEDIA              AS d2_media
  , T1.DERIVADAS__IDX_ABISMO            AS idx_abismo
  , T1.DERIVADAS__MAGNITUDE_ABISMO      AS mag_abismo
  , T1.DERIVADAS__MILHAR_NO_ABISMO      AS milhar_abismo
  -- F1: descida_passos >= 11
  , T1.COMP_APOS_PICO__DESCIDA_PASSOS   AS descida_passos
  -- F10: perc_fora_iqr = N  ← novo (necessário para pool C3)
  , T1.PERCENTIS__FINAL_NO_IQR          AS perc_iqr
  -- F11: plato_vel = NORMAL
  , T1.PLATO_ABISMO__VELOCIDADE         AS plato_vel
  -- F13: vol_padrao = IRREGULAR
  , T1.VOLAT_SEGMENTO__VOL_PADRAO       AS vol_padrao
  -- F14: forma = PLATICURTICA
  , T1.FORMA__DISTRIBUICAO              AS forma_dist
  -- C4c2/C4c3: zona estável
  , T1.ZONA__PLATO                      AS zona_plato
  , T1.ZONA__DESTINO                    AS zona_dest
  , T1.ZONA__INICIAL                    AS zona_ini
  -- C4a2: grad_cheg
  , T1.GRADIENTE_FINAL__GRAD_CHEGADA    AS grad_cheg
FROM DADOS_ORBITA DD
JOIN ORBITAS_TABELAO1 T1 ON T1.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
WHERE DD.TIMESTAMP_EXECUCAO_INS >= TO_DATE('17/04/2026', 'DD/MM/YYYY') + 18/24
  AND DD.TIMESTAMP_EXECUCAO_INS <  TO_DATE('16/05/2026', 'DD/MM/YYYY') + 19/24
ORDER BY DD.TIMESTAMP_EXECUCAO_INS, T1.ID_DADOS_ORBITA
