#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# /home/oracle/etl_nfe_rf/modulo1/mod1_descompactador.py
# Versão 2.0 — Motor Inteligente de Extração com fallback adaptativo
import os
import shutil
import zipfile
import tarfile
import uuid
import subprocess
from datetime import datetime

# =================================================================
# INFRAESTRUTURA DE DIRETORIOS
# =================================================================
DIR_VALIDOS       = "/xmls/1234_TT"
DIR_CORROMPIDOS   = "/xmls/zip/corrompidos"
DIR_IGNORADOS     = "/xmls/zip/ignorado"
DIR_DESCONHECIDOS = "/xmls/zip/desconhecido"
DIR_LANDING       = "/zip"
DIR_BACKUP        = "/backup/"
DIR_STAGING       = "/xmls/staging_temp"
ARQUIVO_LOG       = "/home/oracle/etl_nfe_rf/modulo1/log/auditoria_nfe.log"
ARQUIVO_DEBUG     = "/home/oracle/etl_nfe_rf/modulo1/log/debug_sistemico.log"


# =================================================================
# DETECTOR DE CAPACIDADES (executa uma vez no início)
# =================================================================
def comando_existe(cmd):
    try:
        subprocess.call([cmd, '--help'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except OSError:
        return False

def modulo_python_existe(nome):
    try:
        __import__(nome)
        return True
    except ImportError:
        return False

CAPACIDADES = {
    'rarfile_py': False,
    'unrar_so':   False,
    '7za_so':     False,
    '7z_so':      False,
    'unzip_so':   False,
}

def detectar_capacidades():
    CAPACIDADES['rarfile_py'] = modulo_python_existe('rarfile')
    CAPACIDADES['unrar_so']   = comando_existe('unrar')
    CAPACIDADES['7za_so']     = comando_existe('7za')
    CAPACIDADES['7z_so']      = comando_existe('7z')
    CAPACIDADES['unzip_so']   = comando_existe('unzip')


# =================================================================
# UTILITÁRIOS
# =================================================================
def criar_dir_seguro(caminho):
    try:
        os.makedirs(caminho)
    except OSError:
        pass

def debug_log(etapa, mensagem):
    criar_dir_seguro(os.path.dirname(ARQUIVO_DEBUG))
    agora = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(ARQUIVO_DEBUG, 'a') as f:
        f.write("[{}] [{}] {}\n".format(agora, etapa, mensagem))

def gravar_log(nivel, status, arquivo, detalhe):
    criar_dir_seguro(os.path.dirname(ARQUIVO_LOG))
    with open(ARQUIVO_LOG, 'a') as f:
        f.write("INFO;{};{};{};{}\n".format(nivel, status, arquivo, detalhe))

def limpar_diretorios_regra_1():
    diretorios = [DIR_VALIDOS, DIR_CORROMPIDOS, DIR_IGNORADOS, DIR_DESCONHECIDOS, DIR_STAGING]
    for diretorio in diretorios:
        if not os.path.exists(diretorio):
            criar_dir_seguro(diretorio)
            continue
        for item in os.listdir(diretorio):
            caminho_item = os.path.join(diretorio, item)
            try:
                if os.path.isfile(caminho_item) or os.path.islink(caminho_item):
                    try: os.chmod(caminho_item, 0o777)
                    except Exception: pass
                    os.unlink(caminho_item)
                elif os.path.isdir(caminho_item):
                    def forcar_delecao(func, path, exc_info):
                        try:
                            os.chmod(path, 0o777)
                            func(path)
                        except: pass
                    shutil.rmtree(caminho_item, onerror=forcar_delecao)
            except Exception:
                pass


# =================================================================
# MOTORES DE EXTRAÇÃO ESPECIALIZADOS
# =================================================================
def _executar_subprocess(cmd_lista, etapa):
    try:
        proc = subprocess.Popen(cmd_lista, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = proc.communicate()
        if proc.returncode == 0:
            return True
        else:
            debug_log(etapa, "Falha (rc={}): {}".format(proc.returncode, stderr[:200] if stderr else ''))
            return False
    except Exception as e:
        debug_log(etapa, "Excecao: {}".format(e))
        return False


def extrair_zip(caminho, destino):
    try:
        with zipfile.ZipFile(caminho, 'r') as z:
            z.extractall(destino)
        return True
    except Exception as e:
        debug_log("ZIP_PYTHON", "Falhou em {}: {}".format(caminho, e))
    if CAPACIDADES['unzip_so']:
        return _executar_subprocess(['unzip', '-o', '-q', caminho, '-d', destino], 'ZIP_SO')
    return False


def extrair_tar(caminho, destino):
    try:
        with tarfile.open(caminho, 'r:*') as t:
            t.extractall(destino)
        return True
    except Exception as e:
        debug_log("TAR", "Falhou em {}: {}".format(caminho, e))
        return False


def extrair_rar(caminho, destino):
    if CAPACIDADES['rarfile_py']:
        try:
            import rarfile
            with rarfile.RarFile(caminho, 'r') as r:
                r.extractall(destino)
            return True
        except Exception as e:
            debug_log("RAR_PYTHON", "rarfile falhou em {}: {}".format(caminho, e))
    if CAPACIDADES['unrar_so']:
        if _executar_subprocess(['unrar', 'x', '-o+', '-y', caminho, destino + '/'], 'RAR_UNRAR'):
            return True
    if CAPACIDADES['7za_so']:
        if _executar_subprocess(['7za', 'x', caminho, '-o' + destino, '-y'], 'RAR_7ZA'):
            return True
    if CAPACIDADES['7z_so']:
        if _executar_subprocess(['7z', 'x', caminho, '-o' + destino, '-y'], 'RAR_7Z'):
            return True
    debug_log("RAR_TODAS", "Nenhuma ferramenta conseguiu extrair {}".format(caminho))
    return False


def extrair_7z(caminho, destino):
    if CAPACIDADES['7za_so']:
        if _executar_subprocess(['7za', 'x', caminho, '-o' + destino, '-y'], '7Z_7ZA'):
            return True
    if CAPACIDADES['7z_so']:
        if _executar_subprocess(['7z', 'x', caminho, '-o' + destino, '-y'], '7Z_7Z'):
            return True
    debug_log("7Z", "Nenhuma ferramenta para 7z disponivel para {}".format(caminho))
    return False


# =================================================================
# DISPATCHER INTELIGENTE
# =================================================================
def motor_extracao(caminho_pacote, dir_destino):
    nome_lower = caminho_pacote.lower()
    if nome_lower.endswith('.zip'):
        sucesso = extrair_zip(caminho_pacote, dir_destino)
    elif nome_lower.endswith(('.tar', '.tar.gz', '.tgz', '.tar.bz2', '.bz2')):
        sucesso = extrair_tar(caminho_pacote, dir_destino)
    elif nome_lower.endswith('.rar'):
        sucesso = extrair_rar(caminho_pacote, dir_destino)
    elif nome_lower.endswith('.7z'):
        sucesso = extrair_7z(caminho_pacote, dir_destino)
    elif nome_lower.endswith('.gz') and not nome_lower.endswith('.tar.gz'):
        try:
            import gzip
            destino_arq = os.path.join(dir_destino, os.path.basename(caminho_pacote)[:-3])
            with gzip.open(caminho_pacote, 'rb') as f_in:
                with open(destino_arq, 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            sucesso = True
        except Exception as e:
            debug_log("GZ", "Falhou em {}: {}".format(caminho_pacote, e))
            sucesso = False
    else:
        debug_log("DISPATCH", "Formato nao reconhecido: {}".format(caminho_pacote))
        sucesso = False
    return sucesso


# =================================================================
# MATRIOSKA
# =================================================================
def resolver_matrioska(dir_base):
    extensoes = (".zip", ".tar", ".gz", ".tgz", ".bz2", ".rar", ".7z")
    processando = True
    loops = 0
    sucessos = 0
    falhas = 0
    MAX_LOOPS = 20
    while processando and loops < MAX_LOOPS:
        processando = False
        loops += 1
        zips_encontrados = []
        for root, dirs, files in os.walk(dir_base):
            for f in files:
                if f.lower().endswith(extensoes):
                    zips_encontrados.append(os.path.join(root, f))
        if zips_encontrados:
            processando = True
            for caminho_zip in zips_encontrados:
                pasta_extracao = caminho_zip + "_ext"
                criar_dir_seguro(pasta_extracao)
                ok = motor_extracao(caminho_zip, pasta_extracao)
                if ok:
                    sucessos += 1
                    try:
                        os.remove(caminho_zip)
                    except: pass
                else:
                    falhas += 1
                    try:
                        nome_falha = "FALHA_{}_{}".format(uuid.uuid4().hex[:6], os.path.basename(caminho_zip))
                        shutil.move(caminho_zip, os.path.join(DIR_CORROMPIDOS, nome_falha))
                    except: pass
    debug_log("MATRIOSKA", "Niveis varridos: {} | Sucessos: {} | Falhas: {}".format(loops, sucessos, falhas))
    return sucessos, falhas


# =================================================================
# COLETA DE XMLs PARA O PALCO FINAL
# =================================================================
def pescar_xmls_para_palco(dir_origem):
    qtd = 0
    for root, dirs, files in os.walk(dir_origem):
        for f in files:
            if f.lower().endswith(".xml"):
                origem_xml = os.path.join(root, f)
                destino_xml = os.path.join(DIR_VALIDOS, f)
                nome_base, ext = os.path.splitext(f)
                while os.path.exists(destino_xml):
                    destino_xml = os.path.join(DIR_VALIDOS, "{}_{}{}".format(nome_base, uuid.uuid4().hex[:8], ext))
                shutil.move(origem_xml, destino_xml)
                qtd += 1
    return qtd

def gerar_nome_versionado(nome_arquivo):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    if nome_arquivo.lower().endswith(".tar.gz"):
        base = nome_arquivo[:-7]
        ext = ".tar.gz"
    else:
        base, ext = os.path.splitext(nome_arquivo)
    return "{}_v{}{}".format(base, timestamp, ext)

def processar_xmls_soltos(arquivos_ordenados):
    qtd_soltos = 0
    for arquivo in arquivos_ordenados:
        if arquivo.lower().endswith(".xml"):
            caminho_origem = os.path.join(DIR_LANDING, arquivo)
            destino_xml = os.path.join(DIR_VALIDOS, arquivo)
            nome_base, ext = os.path.splitext(arquivo)
            while os.path.exists(destino_xml):
                destino_xml = os.path.join(DIR_VALIDOS, "{}_{}{}".format(nome_base, uuid.uuid4().hex[:8], ext))
            try:
                shutil.copy2(caminho_origem, os.path.join(DIR_BACKUP, gerar_nome_versionado(arquivo)))
                shutil.copy2(caminho_origem, destino_xml)
                try: os.chmod(caminho_origem, 0o777)
                except Exception: pass
                os.remove(caminho_origem)
                qtd_soltos += 1
            except Exception as e:
                debug_log("ERRO_SOLTO", "Falha ao processar o xml solto {}: {}".format(arquivo, e))
    if qtd_soltos > 0:
        gravar_log("INFO", "XML_SOLTOS", "DIRETORIO_ZIP", "{} XMLs soltos movidos para 1234_TT".format(qtd_soltos))


# =================================================================
# EXECUÇÃO PRINCIPAL
# =================================================================
def executar():
    if os.path.exists(ARQUIVO_DEBUG): open(ARQUIVO_DEBUG, "w").close()
    if os.path.exists(ARQUIVO_LOG):   open(ARQUIVO_LOG, "w").close()
    detectar_capacidades()
    debug_log("CAPACIDADES", "rarfile_py={} | unrar={} | 7za={} | 7z={} | unzip={}".format(
        CAPACIDADES["rarfile_py"], CAPACIDADES["unrar_so"],
        CAPACIDADES["7za_so"], CAPACIDADES["7z_so"], CAPACIDADES["unzip_so"]
    ))
    if not (CAPACIDADES["rarfile_py"] or CAPACIDADES["unrar_so"]
            or CAPACIDADES["7za_so"] or CAPACIDADES["7z_so"]):
        debug_log("ALERTA", "NENHUMA ferramenta para RAR disponivel! Instale: pip install rarfile OU yum install unrar")
        gravar_log("WARN", "DEPENDENCIA_FALTANDO", "SISTEMA",
                   "Nenhuma ferramenta para RAR. RARs serao movidos para corrompidos.")
    limpar_diretorios_regra_1()
    gravar_log("SISTEMA", "MODULO_1", "INICIO", "Diretorios limpos. Iniciando Modulo 1.")
    if not os.path.exists(DIR_LANDING):
        debug_log("EXEC", "DIR_LANDING nao existe: {}".format(DIR_LANDING))
        return
    arquivos = sorted(os.listdir(DIR_LANDING))
    criar_dir_seguro(DIR_BACKUP)
    processar_xmls_soltos(arquivos)
    pacotes = [f for f in arquivos if f.lower().endswith(
        (".zip", ".tar", ".gz", ".tgz", ".bz2", ".rar", ".7z")
    )]
    if len(pacotes) == 0:
        debug_log("EXEC", "Nenhum pacote para processar.")
        return
    for pacote in pacotes:
        caminho_pacote = os.path.join(DIR_LANDING, pacote)
        nome_versionado = gerar_nome_versionado(pacote)
        caminho_backup = os.path.join(DIR_BACKUP, nome_versionado)
        try:
            shutil.copy2(caminho_pacote, caminho_backup)
            debug_log("BACKUP", "Copia garantida: {}".format(caminho_backup))
            gravar_log("INFO", "BKP_CRIADO", pacote, "Versionado como: {}".format(nome_versionado))
        except Exception as e:
            debug_log("ERRO_BKP", "Falha ao fazer backup do pacote {}: {}".format(pacote, e))
            continue
        criar_dir_seguro(DIR_STAGING)
        try:
            ok_topo = motor_extracao(caminho_pacote, DIR_STAGING)
            if not ok_topo:
                try:
                    nome_falha = "FALHA_TOPO_{}_{}".format(uuid.uuid4().hex[:6], pacote)
                    destino_falha = os.path.join(DIR_CORROMPIDOS, nome_falha)
                    shutil.move(caminho_pacote, destino_falha)
                    debug_log("CORROMPIDO_TOPO", "Movido: {} -> {}".format(pacote, destino_falha))
                    gravar_log("ERROR", "ERRO_EXTRACAO_TOPO", pacote,
                               "Pacote corrompido movido para: {}".format(nome_falha))
                except Exception as e_mov:
                    debug_log("CORROMPIDO_TOPO", "Falha ao mover {}: {}".format(pacote, e_mov))
                    gravar_log("ERROR", "ERRO_EXTRACAO_TOPO", pacote,
                               "Falha extracao + falha ao mover: {}".format(e_mov))
                continue
            sucessos, falhas = resolver_matrioska(DIR_STAGING)
            qtd_xmls = pescar_xmls_para_palco(DIR_STAGING)
            os.remove(caminho_pacote)
            gravar_log("INFO", "DESCOMPACTADO", pacote,
                       "Sucesso. {} XMLs | {} sub-pacotes OK | {} falhas".format(qtd_xmls, sucessos, falhas))
        except Exception as e:
            gravar_log("ERROR", "ERRO_EXTRACAO", pacote, "Falha critica: {}".format(e))
        finally:
            if os.path.exists(DIR_STAGING):
                shutil.rmtree(DIR_STAGING, ignore_errors=True)


if __name__ == "__main__":
    executar()
