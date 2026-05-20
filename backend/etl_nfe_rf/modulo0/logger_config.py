# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo0/logger_config.py

import logging
import os
from modulo0 import config


def get_logger(name, log_type="system"):
    """
    Retorna um logger configurado.
    'system': log técnico (execucao.log)
    'audit' : log para o APEX (auditoria_nfe.log — delimitado por ;)
    """
    logger = logging.getLogger(name)

    if not logger.handlers:
        logger.setLevel(logging.INFO)

        if log_type == "audit":
            formatter = logging.Formatter(
                '%(asctime)s;%(levelname)s;%(message)s',
                datefmt='%d/%m/%Y;%H:%M:%S'
            )
            log_path = config.LOG_AUDITORIA
        else:
            formatter = logging.Formatter(
                '%(asctime)s - %(levelname)s - %(message)s',
                datefmt='%d/%m/%Y %H:%M:%S'
            )
            log_path = config.LOG_SISTEMICO

        os.makedirs(os.path.dirname(log_path), exist_ok=True)

        file_handler = logging.FileHandler(log_path, encoding='utf-8')
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)

        if log_type == "system":
            console = logging.StreamHandler()
            console.setFormatter(formatter)
            logger.addHandler(console)

    return logger
