-- Tipo   : DML
-- Objeto : qry_orbita_tabelao1_filtrada
-- Salvo  : 2026-05-14
-- Origem : Reestruturação de query — joins explícitos, range de timestamp, aliases completos
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
 WHERE DD.TIMESTAMP_EXECUCAO_INS    >= TRUNC(SYSDATE) + 18/24
   AND DD.TIMESTAMP_EXECUCAO_INS    <  TRUNC(SYSDATE) + 19/24
   AND TAB1.CONVERGENCIA__MONOTONICA         = 'N'
   AND TAB1.RAIZES__T_PRIMEIRA_RAIZ         IS NULL
   AND TAB1.RAIZES__TEM_RAIZ_NO_INTERVALO   = 'N'
   AND TAB1.RAIZES__NUM_RAIZES_NO_INTERVAL  = '0'
   AND TAB1.PLATO_ABISMO__ENCONTRADO        = 'S'
;
