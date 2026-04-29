---
name: bug-triage
description: "Use when investigating backend or Flutter defects in SmartFridge: auth redirect issues, invalidation gaps, API contract mismatches, scheduler side effects, or ownership leaks."
---

# Bug Triage

## Objetivo

Investigar bugs com foco nos pontos mais provaveis do projeto atual.

## Antes de Comecar

Leia `.ai/core/architecture.md`, `.ai/core/patterns.md` e os contextos do fluxo afetado.

## Saida

- causa raiz provavel
- arquivos impactados
- correcao minima segura
- risco de regressao

## Regras

- Verifique primeiro ownership por usuario, JWT e invalidacao Riverpod.
- Em problemas de produto, revise `calculateStatus`, filtros e notificacoes.
- Em problemas de navegacao, revise `GoRouter` e `AuthSession`.
- Em problemas de erro visivel ao usuario, revise `GlobalExceptionHandler` e `formatApiError`.
