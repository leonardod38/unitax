-- Tipo   : FUNCTION
-- Objeto : VALIDA_FUNIL_PREMIO
-- Schema : C4C
-- Salvo  : 2026-05-14
-- Origem : Enviado via prompt
-- Nota   : 48 critérios — consulta ORBITAS_TABELAO1 (já no JOIN da query principal).
--          Pode ser completamente inlinada. Ver qry_orbita_filtros_complexidade_v2.sql
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION C4C.VALIDA_FUNIL_PREMIO (
    p_id_orbita IN NUMBER
) RETURN NUMBER
IS
    v_g8_slope_rot   VARCHAR2(50); v_g8_slope_sub   VARCHAR2(50);
    v_g8_r2l_rot     VARCHAR2(50); v_g8_rmse_rot    VARCHAR2(50);
    v_g8_velent_rot  VARCHAR2(50); v_g8_velsai_rot  VARCHAR2(50);
    v_g8_d2cruz_rot  VARCHAR2(50); v_g8_arco_rot    VARCHAR2(50);
    v_g8_varext_rot  VARCHAR2(50); v_g8_proj_rot    VARCHAR2(50);
    v_g9_d2_cruza    VARCHAR2(50); v_g9_d5_din      VARCHAR2(50);
    v_g10_c_subincer VARCHAR2(50); v_g10_c_funil    VARCHAR2(50);
    v_p3_r2_slope    NUMBER; v_p3_inft_slope  NUMBER;
    v_p3_r2_r2l      NUMBER; v_p3_inft_r2l    NUMBER;
    v_p3_coefa_rmse  NUMBER; v_p3_r2_rmse     NUMBER; v_p3_inft_rmse   NUMBER;
    v_p3_r2_velent   NUMBER; v_p3_inft_velent NUMBER;
    v_p3_r2_velsai   NUMBER; v_p3_inft_velsai NUMBER;
    v_p3_r2_acel     NUMBER; v_p3_inft_acel   NUMBER;
    v_p3_r2_d2cruz   NUMBER; v_p3_inft_d2cruz NUMBER;
    v_p3_r2_razvel   NUMBER; v_p3_inft_razvel NUMBER;
    v_p3_r2_areat    NUMBER; v_p3_inft_areat  NUMBER;
    v_p3_r2_arco     NUMBER; v_p3_inft_arco   NUMBER;
    v_p3_r2_varext   NUMBER; v_p3_inft_varext NUMBER;
    v_p3_r2_proj     NUMBER; v_p3_inft_proj   NUMBER;
    v_slope_slope    NUMBER; v_slope_r2l      NUMBER;
    v_slope_rmse     NUMBER; v_slope_velent   NUMBER;
    v_slope_velsai   NUMBER; v_slope_d2cruz   NUMBER;
    v_slope_areat    NUMBER; v_slope_arco     NUMBER;
    v_slope_varext   NUMBER; v_slope_proj     NUMBER;
    c_p3_r2   CONSTANT NUMBER := 0.9647;
    c_p3_inft CONSTANT NUMBER := 0.3787;
    c_p3_coefa CONSTANT NUMBER := -0.0005;
    c_tol     CONSTANT NUMBER := 0.001;
BEGIN
    SELECT
        FUNIL_G8__G8_N1_SLOPE_ROTULO,   FUNIL_G8__G8_N1_SLOPE_SUBROTU,
        FUNIL_G8__G8_N1_R2L_ROTULO,     FUNIL_G8__G8_N1_RMSE_ROTULO,
        FUNIL_G8__G8_N1_VEL_ENT_ROTULO, FUNIL_G8__G8_N1_VEL_SAI_ROTULO,
        FUNIL_G8__G8_N1_D2_CRUZ_ROTULO, FUNIL_G8__G8_N1_ARCO_ROTULO,
        FUNIL_G8__G8_N1_VAR_EXT_ROTULO, FUNIL_G8__G8_N1_PROJ_ROTULO,
        FUNIL_G9__G9_D2_ROTULO_CRUZA,   FUNIL_G9__G9_D5_ROTULO_DIN,
        FUNIL_G10__G10_C_SUBROTU_INCER, FUNIL_G10__G10_C_ROTULO_FUNIL,
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_SLOPE_P3_R2),    STR_PARA_NUMERO(FUNIL_G8__G8_N1_SLOPE_P3_INF_T),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_R2L_P3_R2),      STR_PARA_NUMERO(FUNIL_G8__G8_N1_R2L_P3_INF_T),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_RMSE_P3_COEF_A), STR_PARA_NUMERO(FUNIL_G8__G8_N1_RMSE_P3_R2),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_RMSE_P3_INF_T),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_VEL_ENT_P3_R2),  STR_PARA_NUMERO(FUNIL_G8__G8_N1_VEL_ENT_P3_INF),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_VEL_SAI_P3_R2),  STR_PARA_NUMERO(FUNIL_G8__G8_N1_VEL_SAI_P3_INF),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_ACEL_PICO_P3_R), STR_PARA_NUMERO(FUNIL_G8__G8_N1_ACEL_PICO_P3_I),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_D2_CRUZ_P3_R2),  STR_PARA_NUMERO(FUNIL_G8__G8_N1_D2_CRUZ_P3_INF),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_RAZAO_VEL_P3_R), STR_PARA_NUMERO(FUNIL_G8__G8_N1_RAZAO_VEL_P3_I),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_AREA_TOT_P3_R2), STR_PARA_NUMERO(FUNIL_G8__G8_N1_AREA_TOT_P3_IN),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_ARCO_P3_R2),     STR_PARA_NUMERO(FUNIL_G8__G8_N1_ARCO_P3_INF_T),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_VAR_EXT_P3_R2),  STR_PARA_NUMERO(FUNIL_G8__G8_N1_VAR_EXT_P3_INF),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_PROJ_P3_R2),     STR_PARA_NUMERO(FUNIL_G8__G8_N1_PROJ_P3_INF_T),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_SLOPE_SLOPE),    STR_PARA_NUMERO(FUNIL_G8__G8_N1_R2L_SLOPE),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_RMSE_SLOPE),     STR_PARA_NUMERO(FUNIL_G8__G8_N1_VEL_ENT_SLOPE),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_VEL_SAI_SLOPE),  STR_PARA_NUMERO(FUNIL_G8__G8_N1_D2_CRUZ_SLOPE),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_AREA_TOT_SLOPE), STR_PARA_NUMERO(FUNIL_G8__G8_N1_ARCO_SLOPE),
        STR_PARA_NUMERO(FUNIL_G8__G8_N1_VAR_EXT_SLOPE),  STR_PARA_NUMERO(FUNIL_G8__G8_N1_PROJ_SLOPE)
      INTO
        v_g8_slope_rot, v_g8_slope_sub, v_g8_r2l_rot, v_g8_rmse_rot,
        v_g8_velent_rot, v_g8_velsai_rot, v_g8_d2cruz_rot, v_g8_arco_rot,
        v_g8_varext_rot, v_g8_proj_rot, v_g9_d2_cruza, v_g9_d5_din,
        v_g10_c_subincer, v_g10_c_funil,
        v_p3_r2_slope,    v_p3_inft_slope,  v_p3_r2_r2l,      v_p3_inft_r2l,
        v_p3_coefa_rmse,  v_p3_r2_rmse,    v_p3_inft_rmse,
        v_p3_r2_velent,   v_p3_inft_velent, v_p3_r2_velsai,   v_p3_inft_velsai,
        v_p3_r2_acel,     v_p3_inft_acel,   v_p3_r2_d2cruz,   v_p3_inft_d2cruz,
        v_p3_r2_razvel,   v_p3_inft_razvel, v_p3_r2_areat,    v_p3_inft_areat,
        v_p3_r2_arco,     v_p3_inft_arco,   v_p3_r2_varext,   v_p3_inft_varext,
        v_p3_r2_proj,     v_p3_inft_proj,
        v_slope_slope, v_slope_r2l,    v_slope_rmse,   v_slope_velent,
        v_slope_velsai, v_slope_d2cruz, v_slope_areat,  v_slope_arco,
        v_slope_varext, v_slope_proj
      FROM ORBITAS_TABELAO1
     WHERE TO_NUMBER(ID_DADOS_ORBITA) = p_id_orbita
       AND ROWNUM = 1;

    -- BLOCO 1: 14 rótulos invariantes
    IF v_g8_slope_rot   != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_slope_sub   != 'FASE_ESTABILIZADA'              THEN RETURN 0; END IF;
    IF v_g8_r2l_rot     != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_rmse_rot    != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_velent_rot  != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_velsai_rot  != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_d2cruz_rot  != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_arco_rot    != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_varext_rot  != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g8_proj_rot    != 'QUASE_LINEAR'                   THEN RETURN 0; END IF;
    IF v_g9_d2_cruza    != 'ACOPLAMENTO_MEDIO'              THEN RETURN 0; END IF;
    IF v_g9_d5_din      != 'SISTEMA_REGULAR'                THEN RETURN 0; END IF;
    IF v_g10_c_subincer != 'ROTULOS_CONFLITANTES'           THEN RETURN 0; END IF;
    IF v_g10_c_funil    != 'FUNIL_PARCIALMENTE_CONVERGENTE' THEN RETURN 0; END IF;
    -- BLOCO 2: 25 features P3
    IF ABS(v_p3_r2_slope    - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_slope  - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_r2l      - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_r2l    - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_coefa_rmse  - c_p3_coefa) > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_rmse     - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_rmse   - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_velent   - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_velent - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_velsai   - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_velsai - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_acel     - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_acel   - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_d2cruz   - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_d2cruz - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_razvel   - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_razvel - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_areat    - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_areat  - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_arco     - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_arco   - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_varext   - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_varext - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_r2_proj     - c_p3_r2)    > c_tol THEN RETURN 0; END IF;
    IF ABS(v_p3_inft_proj   - c_p3_inft)  > c_tol THEN RETURN 0; END IF;
    -- BLOCO 3: 10 slopes
    IF v_slope_slope  NOT BETWEEN -0.0019 AND 0.0020 THEN RETURN 0; END IF;
    IF v_slope_r2l    NOT BETWEEN  0.0001 AND 0.0018 THEN RETURN 0; END IF;
    IF v_slope_rmse   NOT BETWEEN  0.0030 AND 0.0040 THEN RETURN 0; END IF;
    IF v_slope_velent NOT BETWEEN -0.0039 AND 0.0037 THEN RETURN 0; END IF;
    IF v_slope_velsai NOT BETWEEN -0.0035 AND 0.0038 THEN RETURN 0; END IF;
    IF v_slope_d2cruz NOT BETWEEN -0.0025 AND 0.0026 THEN RETURN 0; END IF;
    IF v_slope_areat  NOT BETWEEN  0.0129 AND 0.0150 THEN RETURN 0; END IF;
    IF v_slope_arco   NOT BETWEEN  0.0056 AND 0.0070 THEN RETURN 0; END IF;
    IF v_slope_varext NOT BETWEEN  0.0041 AND 0.0077 THEN RETURN 0; END IF;
    IF v_slope_proj   NOT BETWEEN  0.0044 AND 0.0069 THEN RETURN 0; END IF;

    RETURN 1;
EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN 0;
    WHEN TOO_MANY_ROWS THEN RETURN 0;
    WHEN OTHERS        THEN RETURN 0;
END VALIDA_FUNIL_PREMIO;
/
