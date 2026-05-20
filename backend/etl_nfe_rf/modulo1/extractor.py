# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo1/extractor.py

import xml.etree.ElementTree as ET
import os
import shutil
from modulo0.logger_config import get_logger
from modulo0 import config

sys_log   = get_logger("Extractor_Sys",   log_type="system")
audit_log = get_logger("Extractor_Audit", log_type="audit")


def validar_e_extrair(caminho_completo):
    """
    Faz o parse do XML e extrai metadados da NFe.
    Se o parse falhar, move o arquivo para corrompidos.
    """
    nome_arq = os.path.basename(caminho_completo)

    try:
        tree = ET.parse(caminho_completo)
        root = tree.getroot()

        ns     = {'ns': 'http://www.portalfiscal.inf.br/nfe'}
        infNFe = root.find('.//ns:infNFe', ns)

        if infNFe is None:
            audit_log.warning(f"IGNORADO;{nome_arq};Estrutura XML nao e NFe")
            return None

        chave = infNFe.attrib.get('Id', '').replace('NFe', '')
        emit  = root.find('.//ns:emit/ns:CNPJ', ns)
        cnpj  = emit.text if emit is not None else "00000000000000"

        with open(caminho_completo, 'r', encoding='utf-8', errors='ignore') as f:
            xml_bruto = f.read()

        audit_log.info(f"VALIDO;{nome_arq};{chave}")

        return {"chave": chave, "cnpj": cnpj, "xml_bruto": xml_bruto}

    except ET.ParseError:
        os.makedirs(config.DIR_CORROMPIDOS, exist_ok=True)
        shutil.move(caminho_completo, os.path.join(config.DIR_CORROMPIDOS, nome_arq))
        audit_log.error(f"CORROMPIDO;{nome_arq};Erro fatal de parse XML")
        sys_log.error(f"Lixo detectado e isolado em corrompidos: {nome_arq}")
        raise ValueError("ARQUIVO_CORROMPIDO")
