CREATE OR REPLACE PROCEDURE USER_XMLS.PRC_RECOMPILAR_OBJETOS
AS
-- ============================================================
-- Tipo    : PROCEDURE
-- Objeto  : PRC_RECOMPILAR_OBJETOS
-- Schema  : USER_XMLS
-- Descricao: Recompila todos os objetos inválidos do banco
--            Oracle acessíveis ao schema USER_XMLS.
--            Ordem de compilacao respeita dependencias:
--            TYPE → TYPE BODY → PACKAGE → PACKAGE BODY →
--            FUNCTION → PROCEDURE → TRIGGER → VIEW → SYNONYM.
--            Executa duas passagens para resolver dependencias
--            cruzadas. Exibe resumo final por schema/tipo.
-- Execucao  : EXEC PRC_RECOMPILAR_OBJETOS;
-- ------------------------------------------------------------
-- Historico de alteracoes:
-- (criacao inicial - 2026-06-03)
-- ============================================================

    TYPE t_tipos IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
    v_ordem    t_tipos;

    v_status   VARCHAR2(20);
    v_ok       PLS_INTEGER := 0;
    v_erro     PLS_INTEGER := 0;
    v_total    PLS_INTEGER := 0;

    PROCEDURE log(p_msg IN VARCHAR2) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE(p_msg);
    END log;

    PROCEDURE compilar_objeto(
        p_own  IN VARCHAR2,
        p_name IN VARCHAR2,
        p_type IN VARCHAR2
    ) IS
        v_cmd VARCHAR2(500);
    BEGIN
        CASE p_type
            WHEN 'PACKAGE BODY' THEN
                v_cmd := 'ALTER PACKAGE "' || p_own || '"."' || p_name || '" COMPILE BODY';
            WHEN 'TYPE BODY' THEN
                v_cmd := 'ALTER TYPE "' || p_own || '"."' || p_name || '" COMPILE BODY';
            ELSE
                v_cmd := 'ALTER ' || p_type || ' "' || p_own || '"."' || p_name || '" COMPILE';
        END CASE;

        EXECUTE IMMEDIATE v_cmd;

    EXCEPTION
        WHEN OTHERS THEN NULL;
    END compilar_objeto;

BEGIN
    DBMS_OUTPUT.ENABLE(1000000);

    log('============================================================');
    log('[PRC_RECOMPILAR_OBJETOS] Inicio: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    log('============================================================');

    -- Ordem de compilação respeitando dependências
    v_ordem(1) := 'TYPE';
    v_ordem(2) := 'TYPE BODY';
    v_ordem(3) := 'PACKAGE';
    v_ordem(4) := 'PACKAGE BODY';
    v_ordem(5) := 'FUNCTION';
    v_ordem(6) := 'PROCEDURE';
    v_ordem(7) := 'TRIGGER';
    v_ordem(8) := 'VIEW';
    v_ordem(9) := 'SYNONYM';

    -- Duas passagens para resolver dependências cruzadas
    FOR v_passagem IN 1..2 LOOP

        log('');
        log('--- Passagem ' || v_passagem || ' de 2 ---');

        FOR idx IN 1..9 LOOP

            FOR rec IN (
                SELECT owner, object_name, object_type
                  FROM all_objects
                 WHERE object_type = v_ordem(idx)
                   AND status      = 'INVALID'
                 ORDER BY owner, object_name
            ) LOOP

                v_total := v_total + 1;

                compilar_objeto(rec.owner, rec.object_name, rec.object_type);

                SELECT status
                  INTO v_status
                  FROM all_objects
                 WHERE owner       = rec.owner
                   AND object_name = rec.object_name
                   AND object_type = rec.object_type
                   AND ROWNUM      = 1;

                IF v_status = 'VALID' THEN
                    v_ok := v_ok + 1;
                    IF v_passagem = 1 THEN
                        log('  [OK]   ' || rec.owner || '.' || rec.object_name || ' (' || rec.object_type || ')');
                    END IF;
                ELSE
                    IF v_passagem = 2 THEN
                        v_erro := v_erro + 1;
                        log('  [ERRO] ' || rec.owner || '.' || rec.object_name || ' (' || rec.object_type || ') — continua invalido');
                    END IF;
                END IF;

            END LOOP;

        END LOOP;

    END LOOP;

    -- Resumo final
    log('');
    log('============================================================');
    log('[PRC_RECOMPILAR_OBJETOS] RESUMO FINAL');
    log('------------------------------------------------------------');

    FOR rec IN (
        SELECT owner, object_type, status, COUNT(*) AS qtd
          FROM all_objects
         WHERE object_type IN ('TYPE','TYPE BODY','PACKAGE','PACKAGE BODY',
                               'FUNCTION','PROCEDURE','TRIGGER','VIEW','SYNONYM')
         GROUP BY owner, object_type, status
         ORDER BY owner, object_type, status
    ) LOOP
        log('  ' || RPAD(rec.owner, 20) ||
            RPAD(rec.object_type, 15) ||
            RPAD(rec.status, 10) ||
            rec.qtd || ' objeto(s)');
    END LOOP;

    log('------------------------------------------------------------');
    log('  Objetos processados : ' || v_total);
    log('  Recompilados com OK : ' || v_ok);
    log('  Ainda com erro      : ' || v_erro);
    log('============================================================');
    log('[PRC_RECOMPILAR_OBJETOS] Fim: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));

EXCEPTION
    WHEN OTHERS THEN
        log('[PRC_RECOMPILAR_OBJETOS] ERRO GERAL: ' || SQLERRM);
        log('[PRC_RECOMPILAR_OBJETOS] TRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        RAISE;

END PRC_RECOMPILAR_OBJETOS;
/

SHOW ERRORS;
