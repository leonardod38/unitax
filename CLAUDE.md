# CLAUDE.md

Este arquivo fornece orientações ao Claude Code (claude.ai/code) ao trabalhar com o código neste repositório.

## Projeto

**Unitax** — projeto de banco de dados Oracle criado em 2026-05-19.

## Estrutura do repositório

```
Unitax/
└── database/
    ├── tables/          # Criação e alteração de tabelas (DDL)
    ├── views/           # Views
    ├── procedures/      # Stored procedures
    ├── functions/       # Functions
    ├── packages/
    │   ├── specs/       # Package specifications
    │   └── bodies/      # Package bodies
    ├── triggers/        # Triggers
    ├── sequences/       # Sequences
    ├── indexes/         # Indexes
    ├── types/           # Types e object types
    ├── synonyms/        # Synonyms
    ├── jobs/            # DBMS_SCHEDULER jobs
    └── scripts/
        ├── ddl/         # Scripts de criação/alteração de estrutura
        └── dml/         # Scripts de carga e manipulação de dados
```

## Convenções de nomenclatura de arquivos

- Tabelas: `TAB_NOME.sql`
- Views: `VW_NOME.sql`
- Procedures: `PRC_NOME.sql`
- Functions: `FNC_NOME.sql`
- Packages spec: `PKG_NOME.pks`
- Packages body: `PKG_NOME.pkb`
- Triggers: `TRG_NOME.sql`
- Sequences: `SEQ_NOME.sql`
- Types: `TYP_NOME.sql`

## Padrões PL/SQL

- Indentação: 3 espaços por nível
- Palavras-chave em MAIÚSCULO: `SELECT`, `FROM`, `WHERE`, `BEGIN`, `END`, `IF`, `THEN`, `ELSE`
- Prefixos de variáveis: `v_` (variáveis locais), `p_` (parâmetros), `c_` (constantes)
- Todo objeto deve ter bloco `EXCEPTION` com log via `DBMS_OUTPUT.PUT_LINE`
- Formato de log: `[NOME_OBJETO] mensagem`

## Git

- Branch principal: `main`
- Remoto: `git@github.com:leonardod38/unitax.git`
- Nunca commitar `.env` ou arquivos com credenciais de banco
