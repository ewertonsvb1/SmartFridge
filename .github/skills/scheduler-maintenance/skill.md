---
name: scheduler-maintenance
description: "Use when changing scheduled maintenance jobs in the backend: product status recalculation, periodic cleanup, or recurring domain maintenance."
---

# Scheduler Maintenance

## Objetivo

Criar ou ajustar jobs agendados no backend seguindo o modelo atual do projeto.

## Antes de Comecar

Leia `.ai/context/backend.md`, `.ai/context/products.md`, `.ai/core/architecture.md` e `scheduler/ProductStatusScheduler.java`.

## Saida

- job agendado
- chamada de service correspondente
- observacoes operacionais relevantes

## Regras

- Use `@Component` e `@Scheduled` como no scheduler atual.
- Coloque a regra no service, nao dentro do scheduler.
- Evite side effects duplicados; revise idempotencia quando houver logs ou contagens.
- Registre logs objetivos com `Slf4j` quando fizer sentido operacional.
