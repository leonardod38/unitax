# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/db_status.py

from db_connection import get_connection


def atualiza_status_job(status: str, mensagem: str) -> None:
    """
    Atualiza TB_JOB_CONTROLE ao final do processamento.
    Se não existir registro RODANDO → insere novo (modo teste manual).
    """
    conn   = None
    cursor = None

    try:
        conn   = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            UPDATE TB_JOB_CONTROLE
            SET    STATUS   = :status,
                   DT_FIM   = SYSTIMESTAMP,
                   MENSAGEM = :mensagem
            WHERE  STATUS   = 'RODANDO'
        """,
            status   = status,
            mensagem = mensagem[:500]
        )

        rows_updated = cursor.rowcount

        if rows_updated == 0:
            cursor.execute("""
                INSERT INTO TB_JOB_CONTROLE (
                    JOB_NOME,
                    STATUS,
                    DT_INICIO,
                    DT_FIM,
                    MENSAGEM,
                    USUARIO
                ) VALUES (
                    'JOB_MANUAL_' || TO_CHAR(SYSDATE,'YYYYMMDD_HH24MISS'),
                    :status,
                    SYSTIMESTAMP,
                    SYSTIMESTAMP,
                    :mensagem,
                    'SISTEMA'
                )
            """,
                status   = status,
                mensagem = mensagem[:500]
            )
            print(f"[DB] Nenhum job RODANDO encontrado → INSERT realizado")

        conn.commit()
        print(f"[DB] Status atualizado → {status} | {mensagem}")

    except Exception as e:
        print(f"[DB] Falha ao atualizar status: {e}")

    finally:
        if cursor: cursor.close()
        if conn:   conn.close()


def registra_log_sistema(descricao: str) -> None:
    """Insere log manual na auditoria."""
    conn   = None
    cursor = None

    try:
        conn   = get_connection()
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO TB_AUDITORIA_RF (
                TIPO_REGISTRO,
                DESCRICAO,
                DATA_HORA
            ) VALUES (
                'LOG_SISTEMA',
                :descricao,
                SYSTIMESTAMP
            )
        """, descricao=descricao[:500])

        conn.commit()
        print(f"[LOG] {descricao}")

    except Exception as e:
        print(f"[DB] Falha ao registrar log: {e}")

    finally:
        if cursor: cursor.close()
        if conn:   conn.close()
