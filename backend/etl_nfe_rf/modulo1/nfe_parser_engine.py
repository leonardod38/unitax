# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/modulo1/nfe_parser_engine.py
"""
ORQUESTRADOR PRINCIPAL (MAESTRO AUTÔNOMO)
Toma posse dos arquivos, limpa os diretórios e chama os módulos em sequência.
"""

import os
import shutil
import subprocess
import time

import mod1_descompactador
import mod2_validador
import mod3_conciliador_eventos
import mod4_xmls_desconhecidos
import mod5_deduplicador

DIR_LANDING       = os.environ.get("DIR_LANDING",       "/zip")
DIR_VALIDOS       = os.environ.get("DIR_PALCO_LIMPO",   "/xmls/1234_TT")
DIR_CORROMPIDOS   = os.environ.get("DIR_CORROMPIDOS",   "/zip/corrompidos")
DIR_IGNORADOS     = os.environ.get("DIR_IGNORADOS",     "/zip/ignorado")
DIR_DESCONHECIDOS = os.environ.get("DIR_DESCONHECIDOS", "/zip/desconhecido")
DIR_CANCELADAS    = os.environ.get("DIR_CANCELADAS",    "/zip/cancelada")
DIR_DUPLICADAS    = os.environ.get("DIR_DUPLICADAS",    "/zip/duplicadas")
DIR_BACKUP        = os.environ.get("DIR_BACKUP",        "/backup")
ARQUIVO_LOG       = os.path.join(os.path.dirname(__file__), "log", "auditoria_nfe.log")


def assumir_controle_infra():
    """Aciona privilégio delegado do root para tomar posse dos arquivos."""
    try:
        subprocess.run(['sudo', 'chown', '-R', 'oracle:oinstall', '/xmls'],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        subprocess.run(['sudo', 'chmod', '-R', '777', '/xmls'],
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    except Exception as e:
        print("Aviso de Infraestrutura: Nao foi possivel acionar o sudo — {}".format(e))


def forcar_delecao(func, path, exc_info):
    """Força a deleção de arquivos durante a limpeza."""
    try:
        os.chmod(path, 0o777)
        func(path)
    except Exception:
        pass


def esvaziar_diretorio(diretorio):
    """Garante que a pasta exista e esteja 100% vazia."""
    if not os.path.exists(diretorio):
        os.makedirs(diretorio, exist_ok=True)
        return

    for item in os.listdir(diretorio):
        caminho_item = os.path.join(diretorio, item)
        try:
            if os.path.isfile(caminho_item) or os.path.islink(caminho_item):
                try:
                    os.chmod(caminho_item, 0o777)
                except Exception:
                    pass
                os.unlink(caminho_item)
            elif os.path.isdir(caminho_item):
                shutil.rmtree(caminho_item, onerror=forcar_delecao)
        except Exception:
            pass


def preparar_ambiente():
    """Prepara o terreno antes da extração pesada começar."""
    if os.path.exists(ARQUIVO_LOG):
        open(ARQUIVO_LOG, 'w').close()

    assumir_controle_infra()

    for d in [DIR_VALIDOS, DIR_CORROMPIDOS, DIR_IGNORADOS,
              DIR_DESCONHECIDOS, DIR_CANCELADAS, DIR_DUPLICADAS]:
        esvaziar_diretorio(d)


if __name__ == "__main__":
    print("=" * 60)
    print(" INICIANDO PIPELINE MODULAR NFE (MODO AUTÔNOMO) ")
    print("=" * 60)

    print("[MAESTRO] Preparando ambiente e infraestrutura...")
    preparar_ambiente()

    print("\n[MAESTRO] Acionando Módulo 1 (Descompactador e Versionamento)...")
    inicio = time.time()
    mod1_descompactador.executar()
    print("[MAESTRO] Módulo 1 finalizado em {:.2f}s.".format(time.time() - inicio))

    print("\n[MAESTRO] Acionando Módulo 2 (Validação Fiscal e Estrutural)...")
    inicio = time.time()
    mod2_validador.executar()
    print("[MAESTRO] Módulo 2 finalizado em {:.2f}s.".format(time.time() - inicio))

    print("\n[MAESTRO] Acionando Módulo 3 (Conciliador de Canceladas e Inutilizadas)...")
    inicio = time.time()
    mod3_conciliador_eventos.executar()
    print("[MAESTRO] Módulo 3 finalizado em {:.2f}s.".format(time.time() - inicio))

    print("\n[MAESTRO] Acionando Módulo 4 (Filtro de XMLs Desconhecidos)...")
    inicio = time.time()
    mod4_xmls_desconhecidos.executar()
    print("[MAESTRO] Módulo 4 finalizado em {:.2f}s.".format(time.time() - inicio))

    print("\n[MAESTRO] Acionando Módulo 5 (Deduplicador de Clones)...")
    inicio = time.time()
    mod5_deduplicador.executar()
    tempo_mod5 = time.time() - inicio
    print("[MAESTRO] Módulo 5 finalizado em {:.2f}s.".format(tempo_mod5))

    print("\n" + "=" * 60)
    print(" PIPELINE CONCLUÍDO COM SUCESSO! ")
    print("=" * 60)
