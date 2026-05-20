# -*- coding: utf-8 -*-
# backend/etl_nfe_rf/main.py

import os
import sys
import subprocess
from modulo0.logger_config import get_logger
from modulo0 import config
from modulo1 import extractor
from modulo2 import database_operations
from db_status import atualiza_status_job

sys_log   = get_logger("Main",  log_type="system")
audit_log = get_logger("Audit", log_type="audit")

DIR_PALCO_LIMPO = os.environ.get("DIR_PALCO_LIMPO", "/xmls/1234_TT")
MAESTRO_SCRIPT  = os.path.join(os.path.dirname(__file__), "modulo1", "nfe_parser_engine.py")
TAMANHO_DO_LOTE = 5000


def executar_pipeline():

    stats = {"validos": 0, "corrompidos": 0, "erros": 0}

    sys_log.info("### [START] INICIO DO PROCESSO DE INGESTAO NFe ###")
    sys.stdout.flush()

    # ---------------------------------------------------------
    # FASE 1: MAESTRO (Limpeza e Preparacao do Palco)
    # ---------------------------------------------------------
    try:
        sys_log.info("Acionando o motor de purificacao de arquivos (Maestro)...")
        sys.stdout.flush()

        processo_maestro = subprocess.Popen(
            ['python3', MAESTRO_SCRIPT],
            stdout             = subprocess.PIPE,
            stderr             = subprocess.STDOUT,
            universal_newlines = True,
            bufsize            = 1
        )

        for linha in iter(processo_maestro.stdout.readline, ''):
            sys.stdout.write(linha)
            sys.stdout.flush()

        processo_maestro.stdout.close()
        processo_maestro.wait()

        if processo_maestro.returncode != 0:
            msg = "Erro critico no Maestro. returncode: {}".format(processo_maestro.returncode)
            sys_log.error(msg)
            atualiza_status_job(status='ERRO', mensagem='[FASE 1] {}'.format(msg))
            sys.exit(1)

        sys_log.info("Maestro finalizado com sucesso.")
        sys.stdout.flush()

    except Exception as e:
        msg = "Excecao na Fase 1 (Maestro): {}".format(str(e))
        sys_log.error(msg)
        atualiza_status_job(status='ERRO', mensagem='[FASE 1] {}'.format(msg))
        sys.exit(1)

    # ---------------------------------------------------------
    # FASE 2: PREPARACAO DO BANCO (Truncate e Conexao)
    # ---------------------------------------------------------
    if not os.path.exists(DIR_PALCO_LIMPO):
        msg = "Diretorio {} nao encontrado.".format(DIR_PALCO_LIMPO)
        print("ERRO|{}".format(msg))
        sys.stdout.flush()
        atualiza_status_job(status='ERRO', mensagem='[FASE 2] {}'.format(msg))
        return

    arquivos       = [f for f in os.listdir(DIR_PALCO_LIMPO) if f.endswith('.xml')]
    total_no_disco = len(arquivos)

    if total_no_disco == 0:
        print("SUCESSO|0|0|0")
        sys.stdout.flush()
        atualiza_status_job(
            status   = 'CONCLUIDO',
            mensagem = '[FASE 2] Nenhum XML encontrado no diretorio. Processo encerrado.'
        )
        return

    try:
        conexao = database_operations.obter_conexao()
        cursor  = conexao.cursor()
        database_operations.limpar_stg_nfe(cursor)
        print("[CARGA ORACLE] Tabela limpa. Iniciando insercao de {} XMLs...".format(total_no_disco))
        sys.stdout.flush()

    except Exception as e:
        msg = "Erro critico no banco de dados: {}".format(str(e))
        print("ERRO CRITICO BANCO: {}".format(e))
        sys.stdout.flush()
        atualiza_status_job(status='ERRO', mensagem='[FASE 2] {}'.format(msg))
        return

    lote_atual    = []
    caminhos_lote = []

    # ---------------------------------------------------------
    # FASE 3: LOOP DE INGESTAO MASSIVA (Array DML)
    # ---------------------------------------------------------
    for indice, arquivo in enumerate(arquivos, start=1):
        caminho_xml = os.path.join(DIR_PALCO_LIMPO, arquivo)

        try:
            dados = extractor.validar_e_extrair(caminho_xml)

            if not dados:
                with open(caminho_xml, 'r') as f:
                    conteudo = f.read()
                chave_bkp = "".join(filter(str.isdigit, arquivo))[:44]
                dados = {
                    'chave'    : chave_bkp if chave_bkp else 'SEM_CHAVE',
                    'cnpj'     : '00000000000000',
                    'xml_bruto': conteudo
                }

            lote_atual.append((
                dados['chave'],
                dados['cnpj'],
                arquivo,
                dados['xml_bruto']
            ))
            caminhos_lote.append(caminho_xml)

        except Exception as e:
            sys_log.error("Erro ao preparar arquivo {}: {}".format(arquivo, e))
            stats["corrompidos"] += 1
            continue

        if len(lote_atual) >= TAMANHO_DO_LOTE:
            try:
                database_operations.inserir_lote_stg_nfe(lote_atual, cursor)
                conexao.commit()
                stats["validos"] += len(lote_atual)
                print("[CARGA ORACLE] Progresso: {} de {} inseridas...".format(stats['validos'], total_no_disco))
                sys.stdout.flush()

            except Exception as e:
                print("Erro no lote: {}".format(e))
                sys.stdout.flush()
                conexao.rollback()
                stats["erros"] += len(lote_atual)

            del lote_atual[:]
            del caminhos_lote[:]

    # ---------------------------------------------------------
    # FASE 4: SOBRAS E FINALIZACAO
    # ---------------------------------------------------------
    if lote_atual:
        try:
            database_operations.inserir_lote_stg_nfe(lote_atual, cursor)
            conexao.commit()
            stats["validos"] += len(lote_atual)

        except Exception as e:
            print("Erro no lote final: {}".format(e))
            sys.stdout.flush()
            stats["erros"] += len(lote_atual)

    cursor.close()
    conexao.close()

    # ---------------------------------------------------------
    # RELATORIO FINAL DE AUDITORIA
    # ---------------------------------------------------------
    audit_log.info("==================================================")
    audit_log.info("RELATORIO DE AUDITORIA")
    audit_log.info("XMLs Inseridos no Oracle:     {}".format(stats['validos']))
    audit_log.info("XMLs REJEITADOS (Falha DB):   {}".format(stats['erros']))
    audit_log.info("Arquivos Ignorados/Lixo:      {}".format(stats['corrompidos']))
    audit_log.info("==================================================")

    sys_log.info("### [END] PROCESSO FINALIZADO ###")

    print("\n[CONCLUIDO] Carga finalizada!")
    print("SUCESSO|{}|{}|{}".format(stats['validos'], stats['erros'], stats['corrompidos']))
    sys.stdout.flush()

    atualiza_status_job(
        status   = 'CONCLUIDO',
        mensagem = 'Parser NFe concluido. Inseridos: {} | Erros: {} | Ignorados: {}'.format(
            stats["validos"], stats["erros"], stats["corrompidos"]
        )
    )


if __name__ == "__main__":
    try:
        executar_pipeline()

    except Exception as e:
        msg = "Falha critica no pipeline: {}".format(str(e))
        sys_log.error(msg)
        sys.stdout.flush()
        atualiza_status_job(status='ERRO', mensagem='[PIPELINE] {}'.format(msg))
        sys.exit(1)
