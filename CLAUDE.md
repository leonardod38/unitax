# CLAUDE.md

Este arquivo fornece orientações ao Claude Code (claude.ai/code) ao trabalhar com o código neste repositório.

## Projeto

**Unitax** — projeto de banco de dados Oracle criado em 2026-05-19.

## Estrutura do repositório

```
Unitax/
└── database/
    ├── tables/          # Criação e alteração de tabelas (DDL)
    ├── views/           # Visões
    ├── procedures/      # Procedimentos armazenados
    ├── functions/       # Funções
    ├── packages/
    │   ├── specs/       # Especificações de pacotes
    │   └── bodies/      # Corpo dos pacotes
    ├── triggers/        # Gatilhos
    ├── sequences/       # Sequências
    ├── indexes/         # Índices
    ├── types/           # Tipos e tipos de objeto
    ├── synonyms/        # Sinônimos
    ├── jobs/            # Agendamentos via DBMS_SCHEDULER
    ├── scripts/
    │   ├── ddl/         # Scripts de criação e alteração de estrutura
    │   └── dml/         # Scripts de carga e manipulação de dados
    └── apex/            # Exportações de aplicações Oracle APEX
```

## Convenções de nomenclatura de arquivos

| Objeto | Padrão |
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

## Padrões PL/SQL

- Indentação: 3 espaços por nível
- Palavras-chave em MAIÚSCULO: `SELECT`, `FROM`, `WHERE`, `BEGIN`, `END`, `IF`, `THEN`, `ELSE`
- Prefixos de variáveis: `v_` (variáveis locais), `p_` (parâmetros), `c_` (constantes)
- Todo objeto deve ter bloco `EXCEPTION` com log via `DBMS_OUTPUT.PUT_LINE`
- Formato de log: `[NOME_OBJETO] mensagem`

## Git

- Branch principal: `main`
- Remoto: `git@github.com:leonardod38/unitax.git`
- Nunca commitar `.env` ou arquivos com credenciais de banco de dados
