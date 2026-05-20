# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo1/mod5_deduplicador.py
"""
MÓDULO 5: DEDUPLICADOR DE ARQUIVOS (CLONES EXATOS)
Extrai Chave de Acesso, Protocolo e DigestValue.
Mantém o primeiro XML e move cópias idênticas para /zip/duplicadas.
"""

import os
import shutil
import xml.etree.ElementTree as ET
from datetime import datetime

DIR_VALIDOS   = os.environ.get("DIR_PALCO_LIMPO", "/xmls/1234_TT")
DIR_DUPLICADAS = os.environ.get("DIR_DUPLICADAS", "/zip/duplicadas")
ARQUIVO_DEBUG = os.path.join(os.path.dirname(__file__), "log", "debug_sistemico.log")


def debug_log(etapa, mensagem):
    os.makedirs(os.path.dirname(ARQUIVO_DEBUG), exist_ok=True)
    agora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(ARQUIVO_DEBUG, 'a') as f:
        f.write("[{}] [{}] {}\n".format(agora, etapa, mensagem))


def gerar_assinatura_unica(caminho_arquivo):
    """
    Monta chave composta: CHAVE_44 + PROTOCOLO + DIGESTVALUE.
    Retorna None se não conseguir extrair chave.
    """
    try:
        tree = ET.parse(caminho_arquivo)
        root = tree.getroot()

        for elem in root.iter():
            if '}' in elem.tag:
                elem.tag = elem.tag.split('}', 1)[1]

        chave   = ""
        infNFe  = root.find('.//infNFe')
        if infNFe is not None:
            id_nfe = infNFe.attrib.get('Id', '')
            chave  = id_nfe[3:] if id_nfe.startswith('NFe') else id_nfe

        nProt    = root.find('.//nProt')
        protocolo = nProt.text if nProt is not None else "SEM_PROT"

        digest   = root.find('.//DigestValue')
        hash_nfe = digest.text if digest is not None else "SEM_HASH"

        if not chave:
            return None

        return "{}_{}_{}".format(chave, protocolo, hash_nfe)

    except Exception:
        return None


def executar():
    debug_log("MODULO_5", "Iniciando varredura de deduplicação.")

    if not os.path.exists(DIR_VALIDOS):
        return

    os.makedirs(DIR_DUPLICADAS, exist_ok=True)
    arquivos = os.listdir(DIR_VALIDOS)

    assinaturas_vistas = set()
    qtd_unicos     = 0
    qtd_duplicados = 0

    for arquivo in arquivos:
        caminho_origem = os.path.join(DIR_VALIDOS, arquivo)
        assinatura_doc = gerar_assinatura_unica(caminho_origem)

        if not assinatura_doc:
            qtd_unicos += 1
            continue

        if assinatura_doc in assinaturas_vistas:
            try:
                shutil.move(caminho_origem, os.path.join(DIR_DUPLICADAS, arquivo))
                qtd_duplicados += 1
            except Exception as e:
                debug_log("ERRO_MOD5", "Falha ao mover duplicada {}: {}".format(arquivo, e))
        else:
            assinaturas_vistas.add(assinatura_doc)
            qtd_unicos += 1

    print("Módulo 5 (Deduplicador de Clones) Concluído!")
    print("-> Notas Fiscais Únicas preservadas: {}".format(qtd_unicos))
    print("-> Clones arremessados para duplicadas: {}".format(qtd_duplicados))

    debug_log("MODULO_5", "Únicos: {} | Duplicados: {}".format(qtd_unicos, qtd_duplicados))


if __name__ == "__main__":
    executar()
