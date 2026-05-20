# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo1/mod4_xmls_desconhecidos.py
"""
MÓDULO 4: FILTRO DE EXTENSÕES (DESCONHECIDOS)
Move para /zip/desconhecido qualquer arquivo que não seja .xml.
"""

import os
import shutil
from datetime import datetime

DIR_VALIDOS       = os.environ.get("DIR_PALCO_LIMPO",   "/xmls/1234_TT")
DIR_DESCONHECIDOS = os.environ.get("DIR_DESCONHECIDOS", "/zip/desconhecido")
ARQUIVO_DEBUG     = os.path.join(os.path.dirname(__file__), "log", "debug_sistemico.log")


def debug_log(etapa, mensagem):
    os.makedirs(os.path.dirname(ARQUIVO_DEBUG), exist_ok=True)
    agora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(ARQUIVO_DEBUG, 'a') as f:
        f.write("[{}] [{}] {}\n".format(agora, etapa, mensagem))


def executar():
    debug_log("MODULO_4", "Iniciando filtro de extensoes desconhecidas.")

    if not os.path.exists(DIR_VALIDOS):
        return

    os.makedirs(DIR_DESCONHECIDOS, exist_ok=True)
    arquivos = os.listdir(DIR_VALIDOS)

    qtd_desconhecidos = 0
    qtd_xml           = 0

    for arquivo in arquivos:
        caminho_origem = os.path.join(DIR_VALIDOS, arquivo)

        if not arquivo.lower().endswith('.xml'):
            try:
                shutil.move(caminho_origem, os.path.join(DIR_DESCONHECIDOS, arquivo))
                qtd_desconhecidos += 1
            except Exception as e:
                debug_log("ERRO_MOD4", "Falha ao mover {}: {}".format(arquivo, e))
        else:
            qtd_xml += 1

    print("Módulo 4 (Filtro de Desconhecidos) Concluído!")
    print("-> Arquivos não-XML expurgados: {}".format(qtd_desconhecidos))
    print("-> Arquivos .xml mantidos no palco: {}".format(qtd_xml))

    debug_log("MODULO_4", "Desconhecidos: {} | XMLs mantidos: {}".format(qtd_desconhecidos, qtd_xml))


if __name__ == "__main__":
    executar()
