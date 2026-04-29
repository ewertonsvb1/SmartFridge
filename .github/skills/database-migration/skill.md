---
name: database-migration
description: "Use when evolving JPA entities, columns, relationships, indexes, or production schema assumptions in the Spring Boot backend."
---

# Database Migration

## Objetivo

Alterar persistencia com seguranca dentro do modelo atual baseado em JPA e profiles dev/prod.

## Antes de Comecar

Leia `.ai/context/backend.md`, `.ai/core/architecture.md`, `.ai/core/conventions.md` e os arquivos `application-dev.yml` e `application-prod.yml`.

## Saida

- ajuste de entidade e repository
- impacto esperado em H2 e PostgreSQL
- orientacao de rollout quando houver mudanca estrutural

## Regras

- Considere que o projeto nao usa Flyway nem Liquibase hoje.
- Em dev, `ddl-auto: update` pode mascarar problemas; revise compatibilidade com PostgreSQL.
- Em prod, `ddl-auto: validate` exige schema pronto antes do deploy.
- Preserve nomes de tabela e colunas existentes salvo mudanca explicita.
- Revise relacoes `ManyToOne` com ownership por usuario.
