# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo1/mod2_validador.py
"""
MÓDULO 2: VALIDADOR FISCAL E ESTRUTURAL
Garante que o XML é um documento oficial do Governo (layouts SEFAZ).
Tudo que não for layout válido vai para /zip/corrompidos.
"""

import os
import shutil
import xml.etree.ElementTree as ET
from datetime import datetime

DIR_VALIDOS     = os.environ.get("DIR_PALCO_LIMPO",   "/xmls/1234_TT")
DIR_CORROMPIDOS = os.environ.get("DIR_CORROMPIDOS",   "/zip/corrompidos")
ARQUIVO_LOG     = os.path.join(os.path.dirname(__file__), "log", "auditoria_nfe.log")
ARQUIVO_DEBUG   = os.path.join(os.path.dirname(__file__), "log", "debug_sistemico.log")

TAGS_VALIDAS_SEFAZ = {
    # NFe, NFCe e Envelopes de Lote
    'nfeProc', 'NFe', 'enviNFe', 'retEnviNFe', 'retConsReciNFe',
    # Eventos (Cancelamentos, CCe, Manifestação)
    'procEventoNFe', 'evento', 'envEvento', 'retEvento', 'retEnvEvento',
    # Inutilizações
    'procInutNFe', 'inutNFe', 'envInutNFe', 'retInutNFe',
    # CTe
    'cteProc', 'CTe', 'procEventoCTe', 'inutCTe', 'procInutCTe',
    # MDFe
    'mdfeProc', 'MDFe', 'procEventoMDFe',
    # CFe (SAT)
    'CFe', 'envCFe',
    # NFS-e
    'CompNfse', 'ConsultarNfseResposta', 'GerarNfseResposta',
    'EnviarLoteRpsResposta', 'Nfse', 'NFSE',
}


def debug_log(etapa, mensagem):
    os.makedirs(os.path.dirname(ARQUIVO_DEBUG), exist_ok=True)
    agora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(ARQUIVO_DEBUG, 'a') as f:
        f.write("[{}] [{}] {}\n".format(agora, etapa, mensagem))


def gravar_log(nivel, status, arquivo, detalhe):
    os.makedirs(os.path.dirname(ARQUIVO_LOG), exist_ok=True)
    with open(ARQUIVO_LOG, 'a') as f:
        f.write("INFO;{};{};{};{}\n".format(nivel, status, arquivo, detalhe))


def validar_xml_governo(caminho_arquivo):
    if os.path.getsize(caminho_arquivo) == 0:
        return False, "Arquivo vazio (0 bytes)"

    try:
        tree = ET.parse(caminho_arquivo)
        root = tree.getroot()
        tag_raiz_limpa = root.tag.split('}')[-1]

        if tag_raiz_limpa in TAGS_VALIDAS_SEFAZ:
            return True, tag_raiz_limpa
        else:
            return False, "Layout Desconhecido: <{}>".format(tag_raiz_limpa)

    except ET.ParseError:
        return False, "Estrutura XML Quebrada (ParseError)"
    except Exception:
        return False, "Erro de Leitura"


def executar():
    debug_log("MODULO_2", "Iniciando inspeção fiscal e estrutural.")
    gravar_log("SISTEMA", "MODULO_2", "INICIO", "Iniciando validacao de layouts do governo.")

    if not os.path.exists(DIR_VALIDOS):
        return

    os.makedirs(DIR_CORROMPIDOS, exist_ok=True)
    arquivos = os.listdir(DIR_VALIDOS)

    if not arquivos:
        return

    qtd_validos = 0
    qtd_lixo    = 0

    for arquivo in arquivos:
        caminho_origem = os.path.join(DIR_VALIDOS, arquivo)
        e_valido, motivo = validar_xml_governo(caminho_origem)

        if e_valido:
            qtd_validos += 1
        else:
            caminho_destino = os.path.join(DIR_CORROMPIDOS, arquivo)
            try:
                shutil.move(caminho_origem, caminho_destino)
                qtd_lixo += 1
                debug_log("EXPURGO", "Lixo: {} | Motivo: {}".format(arquivo, motivo))
            except Exception:
                pass

    debug_log("MODULO_2", "Notas Oficiais: {}. Expurgados: {}.".format(qtd_validos, qtd_lixo))
    gravar_log("INFO", "VALIDACAO_CONCLUIDA", "LOTE",
               "Notas Válidas: {}. Expurgados: {}.".format(qtd_validos, qtd_lixo))

    print("Módulo 2 (Inspeção Fiscal) Concluído!")
    print("-> Notas Sefaz Aprovadas: {}".format(qtd_validos))
    print("-> Lixos Expurgados: {}".format(qtd_lixo))


if __name__ == "__main__":
    executar()
