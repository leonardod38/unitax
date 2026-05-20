# CLAUDE.md — Unitax

Este arquivo documenta o projeto Unitax para o Claude Code. Leia antes de qualquer intervenção.

---

## Visão Geral

**Unitax** é um sistema de **conciliação fiscal da Reforma Tributária** que processa Notas Fiscais Eletrônicas (NF-e) e Cupons Fiscais (CF-e) em massa, consolida os dados no Oracle e gera relatórios de auditoria em XLSX/CSV para o APEX.

O projeto cobre três camadas:

| Camada | Tecnologia | Localização no repo |
|---|---|---|
| ETL / Ingestão | Python 3 | `backend/etl_nfe_rf/` |
| Banco de dados | Oracle 21c / PL/SQL | `database/` |
| Interface | Oracle APEX | `database/apex/` |

---

## Fluxo Completo de Dados

```
Arquivos ZIP/RAR com XMLs
         │
         ▼
[backend/etl_nfe_rf]  ← Python ETL (5 módulos)
  1. Descompactação recursiva (mod1)
  2. Validação de layout SEFAZ (mod2)
  3. Conciliação de cancelamentos (mod3)
  4. Filtro de extensões desconhecidas (mod4)
  5. Deduplicação por assinatura (mod5)
         │
         ▼ INSERT massivo (Array DML, lotes de 5000)
    stg_nfe  ← tabela de staging Oracle
         │
         ▼ PRC_NFE_REFORMA_CONSOLIDADA (orquestrador)
         ├── PRC_LOTE_NFE_REFORMA_CONSOLIDADA → TB_REFORMA_CONSOLIDADA
         └── PRC_CFE_REFORMA_CONSOLIDADA      → TB_REFORMA_CONSOLIDADA
                                                    │
                                                    ▼
                                       PRC_NFE_UNIFICAR_DADOS
                                    (JOIN com TB_REFORMA_TRIBUTARIA)
                                                    │
                                                    ▼
                                             TB_UNIFICADA_RF
                                                    │
                                                    ▼
                                         PRC_NFE_GERAR_XLSX
                                    (via VW_UNIFICADA_RF + PKG_AS_XLSX)
                                                    │
                              ┌─────────────────────┴──────────────────────┐
                              ▼                                             ▼
                   XLSX (< 700.000 linhas)                     CSV (>= 700.000 linhas)
                   DIR_XMLSDOCS/AUDITORIA_*.xlsx               DIR_XMLSDOCS/AUDITORIA_*.csv
                              │
                              ▼
                    Oracle APEX (f102)  ← interface do usuário
```

---

## Infraestrutura Oracle

- **Servidor:** `192.168.0.250:1521`
- **Serviço:** `ORCLPDB1`
- **Schema:** `USER_XMLS`
- **Credenciais:** nunca no código — usar variáveis de ambiente ou `.env`

### Tabelas principais

| Tabela | Papel |
|---|---|
| `stg_nfe` | Staging — recebe os XMLs brutos do Python (CLOB) |
| `TB_REFORMA_CONSOLIDADA` | Dados extraídos do XML (NF-e e CF-e) |
| `TB_REFORMA_TRIBUTARIA` | Dados fiscais da Reforma Tributária (fonte externa) |
| `TB_UNIFICADA_RF` | Resultado do JOIN entre as duas tabelas acima |
| `TB_LOG_NFE_REFORMA` | Log de erros de processamento (AUTONOMOUS_TRANSACTION) |
| `TB_JOB_CONTROLE` | Status de execução do job (RODANDO / CONCLUIDO / ERRO) |
| `TB_AUDITORIA_RF` | Log de auditoria geral do sistema |

### View

| View | Papel |
|---|---|
| `VW_UNIFICADA_RF` | Visão sobre `TB_UNIFICADA_RF` usada pelo gerador de relatórios |

---

## Estrutura do Repositório

```
Unitax/
├── CLAUDE.md
├── README.md
├── .gitignore
│
├── database/
│   ├── procedures/
│   │   ├── PRC_NFE_REFORMA_CONSOLIDADA.sql      # Orquestrador principal
│   │   ├── PRC_LOTE_NFE_REFORMA_CONSOLIDADA.sql # Extrai NF-e em lote de XML
│   │   ├── PRC_CFE_REFORMA_CONSOLIDADA.sql       # Extrai CF-e de XML
│   │   ├── PRC_NFE_UNIFICAR_DADOS.sql            # Consolida em TB_UNIFICADA_RF
│   │   └── PRC_NFE_GERAR_XLSX.sql                # Gera relatório XLSX ou CSV
│   ├── packages/
│   │   ├── specs/PKG_AS_XLSX.pks                 # Spec da lib de geração Excel
│   │   └── bodies/PKG_AS_XLSX.pkb                # Body da lib de geração Excel
│   ├── apex/
│   │   └── f102.sql                              # Exportação da aplicação APEX
│   ├── tables/        # DDLs das tabelas (a preencher)
│   ├── views/         # VW_UNIFICADA_RF e outras (a preencher)
│   ├── functions/     # Funções (a preencher)
│   ├── triggers/      # Gatilhos (a preencher)
│   ├── sequences/     # Sequências (a preencher)
│   ├── indexes/       # Índices (a preencher)
│   ├── types/         # Tipos de objeto (a preencher)
│   ├── synonyms/      # Sinônimos (a preencher)
│   ├── jobs/          # Agendamentos DBMS_SCHEDULER (a preencher)
│   └── scripts/
│       ├── ddl/       # Scripts de alteração de estrutura
│       └── dml/       # Scripts de carga e dados iniciais
│
└── backend/
    └── etl_nfe_rf/
        ├── main.py                    # Entry point — orquestra o pipeline completo
        ├── db_connection.py           # Conexão Oracle centralizada (cx_Oracle)
        ├── db_status.py               # Atualiza TB_JOB_CONTROLE e TB_AUDITORIA_RF
        ├── requirements.txt           # Dependências Python
        ├── .env.example               # Template de variáveis (copiar para .env)
        ├── modulo0/                   # Configuração e logging
        │   ├── config.py              # Variáveis de ambiente e caminhos
        │   └── logger_config.py      # Logger duplex (sistema + auditoria APEX)
        ├── modulo1/                   # Pipeline de limpeza e validação
        │   ├── nfe_parser_engine.py  # Maestro — chama os módulos em sequência
        │   ├── extractor.py          # Extrai metadados do XML (chave, CNPJ)
        │   ├── mod1_descompactador.py # Descompactação recursiva (ZIP/RAR/7Z/TAR)
        │   ├── mod2_validador.py     # Validação de layout SEFAZ
        │   ├── mod3_conciliador_eventos.py # Expurgo de cancelamentos/inutilizações
        │   ├── mod4_xmls_desconhecidos.py  # Filtro de extensões não-.xml
        │   └── mod5_deduplicador.py  # Deduplicação por assinatura criptográfica
        └── modulo2/
            └── database_operations.py # TRUNCATE stg_nfe + INSERT massivo (Array DML)
```

---

## Convenções de Nomenclatura — Banco de Dados

| Objeto | Padrão de arquivo |
|---|---|
| Tabela | `TAB_NOME.sql` |
| Visão | `VW_NOME.sql` |
| Procedimento | `PRC_NOME.sql` |
| Função | `FNC_NOME.sql` |
| Especificação de pacote | `PKG_NOME.pks` |
| Corpo de pacote | `PKG_NOME.pkb` |
| Gatilho | `TRG_NOME.sql` |
| Sequência | `SEQ_NOME.sql` |
| Tipo | `TYP_NOME.sql` |

---

## Padrões PL/SQL

- Indentação: **3 espaços** por nível
- Palavras-chave em **MAIÚSCULO**: `SELECT`, `FROM`, `WHERE`, `BEGIN`, `END`, `IF`, `THEN`, `ELSE`
- Prefixos de variáveis: `v_` (locais), `p_` (parâmetros), `c_` (constantes)
- Todo objeto deve ter bloco `EXCEPTION` com log via `DBMS_OUTPUT.PUT_LINE`
- Formato de log: `[NOME_OBJETO] mensagem`
- Erros em bulk: usar `FORALL ... SAVE EXCEPTIONS` + `PRAGMA EXCEPTION_INIT`
- Logs de erro em tabela: usar `PRAGMA AUTONOMOUS_TRANSACTION` (padrão `TB_LOG_NFE_REFORMA`)

---

## Padrões Python

- Credenciais **sempre** via `os.environ.get()` — nunca hardcoded
- Configurações em `.env` (nunca commitado) — usar `.env.example` como modelo
- Logging via módulo `logging` — nunca `print()` para debug
- Logger duplex:
  - `system` → log técnico (`log/execucao.log`)
  - `audit`  → log para APEX (`modulo1/log/auditoria_nfe.log`, delimitado por `;`)
- Caminhos de infraestrutura lidos de variáveis de ambiente (ver `.env.example`)

---

## PKG_AS_XLSX

Biblioteca de terceiro (Anton Scheffer) para geração de arquivos `.xlsx` diretamente do Oracle PL/SQL. Usada por `PRC_NFE_GERAR_XLSX`. Schema: `USER_XMLS.as_xlsx`.

**Lógica de geração de relatório:**
- `>= 700.000 linhas` → gera **CSV** (separador `;`)
- `< 700.000 linhas`  → gera **XLSX** formatado (Calibri, cores, freeze pane, validação)
- Limite da validação de lista: `10.000 linhas`
- Total fixo de colunas: **143** (invariante documentada no código)

---

## Git

- **Branch principal:** `main`
- **Remoto:** `git@github.com:leonardod38/unitax.git`
- **Regra:** após qualquer criação ou alteração de arquivo, fazer `commit` e `push` imediatamente, sem perguntar
- **Nunca commitar:** `.env`, senhas, tokens, logs de execução (`log/`, `*/log/`), `__pycache__`, arquivos `.bkp*` ou `.old`
- **Pasta `transito/`** está no `.gitignore` — é área de trabalho temporária, não vai para o git
