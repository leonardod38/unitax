# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo0/config.py

import os
from dotenv import load_dotenv

load_dotenv()

# Credenciais Oracle — lidas do arquivo .env
DB_USER = os.environ.get("DB_USER")
DB_PASS = os.environ.get("DB_PASS")
DB_DSN  = os.environ.get("DB_DSN")

# Diretórios base — configuráveis via .env
BASE_DIR    = os.environ.get("BASE_DIR", "/home/oracle/etl_nfe_rf")
MODULO1_DIR = os.path.join(BASE_DIR, "modulo1")

# Caminhos de log
LOG_SISTEMICO = os.path.join(BASE_DIR, "log", "execucao.log")
LOG_AUDITORIA = os.path.join(MODULO1_DIR, "log", "auditoria_nfe.log")

# Pastas de destino
DIR_PROCESSADOS = os.path.join(MODULO1_DIR, "processados")
DIR_ERROS       = os.path.join(MODULO1_DIR, "erros")
DIR_CORROMPIDOS = os.path.join(MODULO1_DIR, "corrompidos")
