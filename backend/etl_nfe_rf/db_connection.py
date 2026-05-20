# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/db_connection.py
# Módulo centralizado de conexão Oracle

import os
import cx_Oracle

DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASS")
DB_DSN  = os.environ.get("DB_DSN")


def get_connection() -> cx_Oracle.Connection:
    """Retorna uma conexão ativa com o banco Oracle."""
    try:
        conn = cx_Oracle.connect(
            user     = DB_USER,
            password = DB_PASS,
            dsn      = DB_DSN,
            encoding = "UTF-8"
        )
        return conn

    except cx_Oracle.DatabaseError as e:
        erro, = e.args
        raise ConnectionError(
            f"[ORACLE] Falha na conexão: {erro.message} "
            f"| Código: {erro.code}"
        ) from e
