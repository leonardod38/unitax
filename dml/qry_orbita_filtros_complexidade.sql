-- Tipo   : DML
-- Objeto : qry_orbita_filtros_complexidade
-- Salvo  : 2026-05-14
-- Origem : Reestruturação — JOINs explícitos, range timestamp, aliases completos
-- ------------------------------------------------------------

SELECT DD.ID_DADOS_ORBITA
     , TRUNC(DD.TIMESTAMP_EXECUCAO_INS)   DATA_EXECUCAO
     , DD.CORRIDA
     , DD.PREMIO
     , DD.MILHAR
     , DD.TXT                             CONTEUDO_TXT
     , DD.TIMESTAMP_EXECUCAO_INS
     , DD.BICHO
  FROM DADOS_ORBITA              DD
  JOIN ORBITAS_TABELAO1          TAB1 ON TAB1.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
  JOIN ORBITA_MILHARES_FILTRADAS F    ON F.ID_DADOS_ORBITA    = DD.ID_DADOS_ORBITA
 WHERE DD.TIMESTAMP_EXECUCAO_INS             >= TRUNC(SYSDATE - 1) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS              < TRUNC(SYSDATE - 1) + 19/24
   -- Filtros de classificação TAB1
   AND TAB1.COMPRIMENTO_ARCO__TRAJETORIA_T   = 'TORTUOSA'
   AND TAB1.COMPLEX_KOLMOG__LZ_NIVEL         = 'COMPLEXO'
   AND TAB1.DTW_PROPRIO__DTW_SUAVIDADE       = 'IRREGULAR'
   AND TAB1.DIAG_RECORR__PREVISIBILIDADE     = 'BAIXA'
   AND TAB1.CLUSTER_TEMP__CLUSTER_TIPO       = 'ALEATORIO'
   AND TAB1.AREA_CURVA__DOMINANCIA           = 'EQUILIBRADO'
   AND TAB1.WAVELET_ENERGIA__WAV_DOM_ESCAL   = 'RAPIDA'
   AND TAB1.POLINOMIAL__CONCAVIDADE         <> 'BAIXO'
   -- Validações via função (avaliar substituição por EXISTS/JOIN internos)
   AND VALIDA_PADRAO_VOLAT (DD.ID_DADOS_ORBITA)  = 1
   AND VALIDA_PADRAO_VOLAT1(DD.ID_DADOS_ORBITA)  = 1
   AND VALIDA_FUNIL_PREMIO (DD.ID_DADOS_ORBITA)  = 1
   -- Exclusão de orbitas já aprovadas
   AND NOT EXISTS (
          SELECT 1
            FROM ORBITAS_APROVADAS B
           WHERE B.ID_DADOS_ORBITA = DD.ID_DADOS_ORBITA
       )
;
