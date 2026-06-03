-- Tipo   : FUNCTION
-- Objeto : VALIDA_PADRAO_VOLAT
-- Schema : C4C
-- Salvo  : 2026-05-14
-- Origem : Enviado via prompt
-- Nota   : Consulta ORBITAS_TABELAO1 — pode ser inlinada na query principal
--          pois TAB1 já está no JOIN. Ver qry_orbita_filtros_complexidade_v2.sql
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION C4C.VALIDA_PADRAO_VOLAT (
    p_id_orbita IN NUMBER
) RETURN NUMBER
IS
    v_inicio NUMBER;
    v_meio   NUMBER;
    v_fim    NUMBER;
    v_razao  NUMBER;
BEGIN
    SELECT STR_PARA_NUMERO(VOLAT_SEGMENTO__VOL_INICIO),
           STR_PARA_NUMERO(VOLAT_SEGMENTO__VOL_MEIO),
           STR_PARA_NUMERO(VOLAT_SEGMENTO__VOL_FIM)
      INTO v_inicio, v_meio, v_fim
      FROM ORBITAS_TABELAO1
     WHERE ID_DADOS_ORBITA = p_id_orbita
       AND ROWNUM = 1;

    IF v_inicio IS NULL OR v_meio IS NULL OR v_fim IS NULL THEN RETURN 0; END IF;
    IF v_inicio = 0                                        THEN RETURN 0; END IF;
    IF v_inicio < 1300                                     THEN RETURN 0; END IF;

    v_razao := v_fim / v_inicio;
    IF v_razao < 0.5 OR v_razao > 2.1                     THEN RETURN 0; END IF;

    IF (v_inicio < v_meio AND v_meio < v_fim)
    OR (v_inicio > v_meio AND v_meio > v_fim)
    OR (v_meio < v_inicio AND v_meio < v_fim)
    OR (v_meio > v_inicio AND v_meio > v_fim) THEN
        RETURN 1;
    END IF;

    RETURN 0;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
    WHEN TOO_MANY_ROWS THEN RETURN 0;
    WHEN OTHERS        THEN RETURN 0;
END VALIDA_PADRAO_VOLAT;
/
