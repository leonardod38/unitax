# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo1/mod3_conciliador_eventos.py
"""
MÓDULO 3: CONCILIADOR DE EVENTOS FISCAIS (EXPURGO)
Identifica Cancelamentos e Inutilizações. Quando encontra um Cancelamento,
caça a NFe original pela Chave de Acesso e arremessa o par para /zip/cancelada.
"""

import os
import shutil
import xml.etree.ElementTree as ET
from datetime import datetime

DIR_VALIDOS    = os.environ.get("DIR_PALCO_LIMPO", "/xmls/1234_TT")
DIR_CANCELADAS = os.environ.get("DIR_CANCELADAS",  "/zip/cancelada")
ARQUIVO_DEBUG  = os.path.join(os.path.dirname(__file__), "log", "debug_sistemico.log")


def debug_log(etapa, mensagem):
    os.makedirs(os.path.dirname(ARQUIVO_DEBUG), exist_ok=True)
    agora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(ARQUIVO_DEBUG, 'a') as f:
        f.write("[{}] [{}] {}\n".format(agora, etapa, mensagem))


def classificar_xml(caminho_arquivo):
    """
    Classifica o XML como NFe Normal, Cancelamento ou Inutilização.
    Retorna: (tipo, chave_44_digitos)
    """
    try:
        tree = ET.parse(caminho_arquivo)
        root = tree.getroot()

        # Remove namespaces para facilitar a busca
        for elem in root.iter():
            if '}' in elem.tag:
                elem.tag = elem.tag.split('}', 1)[1]

        # Inutilização
        if root.tag in ['inutNFe', 'procInutNFe', 'retInutNFe', 'envInutNFe'] \
                or root.find('.//infInut') is not None:
            return 'INUT', None

        # Cancelamento
        if root.find('.//infCanc') is not None:
            chNFe = root.find('.//chNFe')
            return 'CANC', chNFe.text if chNFe is not None else None

        tpEvento = root.find('.//tpEvento')
        if tpEvento is not None and tpEvento.text in ['110111', '110112']:
            chNFe = root.find('.//chNFe')
            return 'CANC', chNFe.text if chNFe is not None else None

        # NFe Normal
        infNFe = root.find('.//infNFe')
        if infNFe is not None:
            id_nfe = infNFe.attrib.get('Id', '')
            if id_nfe.startswith('NFe'):
                return 'NFE', id_nfe[3:]
            elif len(id_nfe) == 44:
                return 'NFE', id_nfe

        return None, None

    except Exception:
        return None, None


def executar():
    debug_log("MODULO_3", "Iniciando conciliação de Canceladas e Inutilizadas.")

    if not os.path.exists(DIR_VALIDOS):
        return

    os.makedirs(DIR_CANCELADAS, exist_ok=True)
    arquivos = os.listdir(DIR_VALIDOS)

    mapa_notas_normais = {}
    mapa_cancelamentos = {}
    lista_inutilizacoes = []

    for arquivo in arquivos:
        caminho_origem = os.path.join(DIR_VALIDOS, arquivo)
        tipo, chave    = classificar_xml(caminho_origem)

        if tipo == 'INUT':
            lista_inutilizacoes.append(arquivo)
        elif tipo == 'CANC' and chave:
            mapa_cancelamentos.setdefault(chave, []).append(arquivo)
        elif tipo == 'NFE' and chave:
            mapa_notas_normais.setdefault(chave, []).append(arquivo)

    qtd_pares_movidos = 0
    qtd_inut_movidas  = 0

    for chave, arquivos_canc in mapa_cancelamentos.items():
        for arq_canc in arquivos_canc:
            shutil.move(os.path.join(DIR_VALIDOS, arq_canc),
                        os.path.join(DIR_CANCELADAS, arq_canc))

        if chave in mapa_notas_normais:
            for arq_nfe in mapa_notas_normais[chave]:
                shutil.move(os.path.join(DIR_VALIDOS, arq_nfe),
                            os.path.join(DIR_CANCELADAS, arq_nfe))
                qtd_pares_movidos += 1
            del mapa_notas_normais[chave]

    for arq_inut in lista_inutilizacoes:
        shutil.move(os.path.join(DIR_VALIDOS, arq_inut),
                    os.path.join(DIR_CANCELADAS, arq_inut))
        qtd_inut_movidas += 1

    total_removidos = len(mapa_cancelamentos) + qtd_pares_movidos + qtd_inut_movidas

    print("Módulo 3 (Conciliador de Cancelamentos) Concluído!")
    print("-> Cancelamentos achados: {}".format(len(mapa_cancelamentos)))
    print("-> NFes originais removidas: {}".format(qtd_pares_movidos))
    print("-> Inutilizações removidas: {}".format(qtd_inut_movidas))
    print("-> Total enviado para /zip/cancelada: {}".format(total_removidos))

    debug_log("MODULO_3", "Conciliação finalizada. Removidos: {}".format(total_removidos))


if __name__ == "__main__":
    executar()
