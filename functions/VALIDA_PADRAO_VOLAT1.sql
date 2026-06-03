-- Tipo   : FUNCTION
-- Objeto : VALIDA_PADRAO_VOLAT1
-- Schema : C4C
-- Salvo  : 2026-05-14
-- Origem : Enviado via prompt
-- Nota   : Consulta ORBITAS_TABELAO1 — pode ser inlinada na query principal.
--          Atenção: usa TO_NUMBER(ID_DADOS_ORBITA) — impede índice na coluna.
--          Ver qry_orbita_filtros_complexidade_v2.sql
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION C4C.VALIDA_PADRAO_VOLAT1 (
    p_id_orbita IN NUMBER
) RETURN NUMBER
IS
    v_g10c   VARCHAR2(50);
    v_padrao VARCHAR2(50);
    v_lyap   VARCHAR2(50);
    v_g10b   VARCHAR2(50);
    v_markov VARCHAR2(50);
BEGIN
    SELECT FUNIL_G10__G10_C_ROTULO_FUNIL,
           VOLAT_SEGMENTO__VOL_PADRAO,
           LYAPUNOV__LYAPUNOV_REGIME,
           FUNIL_G10__G10_B_ROTULO_LATENT,
           MARKOV_ZONAS__MARKOV_REGIME
      INTO v_g10c, v_padrao, v_lyap, v_g10b, v_markov
      FROM ORBITAS_TABELAO1
     WHERE TO_NUMBER(ID_DADOS_ORBITA) = p_id_orbita
       AND ROWNUM = 1;

    IF v_g10c   != 'FUNIL_PARCIALMENTE_CONVERGENTE'                                        THEN RETURN 0; END IF;
    IF v_padrao NOT IN ('IRREGULAR', 'CRESCENTE')                                          THEN RETURN 0; END IF;
    IF v_lyap   NOT IN ('INSTAVEL', 'NEUTRO')                                              THEN RETURN 0; END IF;
    IF v_g10b   NOT IN ('MODO_DOMINANTE_UNICO','TRES_MODOS_PRINCIPAIS','ESTRUTURA_DIFUSA') THEN RETURN 0; END IF;
    IF v_markov NOT IN ('ERGODICA','MISTURA_MEDIA','MISTURA_RAPIDA')                        THEN RETURN 0; END IF;

    RETURN 1;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
    WHEN TOO_MANY_ROWS THEN RETURN 0;
    WHEN OTHERS        THEN RETURN 0;
END VALIDA_PADRAO_VOLAT1;
/
