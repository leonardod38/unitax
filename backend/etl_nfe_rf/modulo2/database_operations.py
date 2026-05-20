# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo2/database_operations.py

import os
import oracledb

DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASS")
DB_DSN  = os.environ.get("DB_DSN")


def obter_conexao():
    return oracledb.connect(user=DB_USER, password=DB_PASS, dsn=DB_DSN)


def limpar_stg_nfe(cursor):
    """Executa TRUNCATE para esvaziar stg_nfe antes da carga."""
    print("[INFO] Limpando tabela stg_nfe (TRUNCATE)...")
    cursor.execute("TRUNCATE TABLE stg_nfe")
    return True


def inserir_lote_stg_nfe(lote_dados, cursor):
    """Executa INSERT massivo via Array DML."""
    sql = """
        INSERT INTO stg_nfe (chave_acesso, cnpj_emitente, nome_arquivo, conteudo_xml)
        VALUES (:1, :2, :3, :4)
    """
    cursor.executemany(sql, lote_dados)
    return True
