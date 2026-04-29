---
name: performance-audit
description: "Use when auditing performance in SmartFridge: JPA queries, product dashboard aggregation, notification fetches, scheduler loops, or excessive Flutter rebuilds."
---

# Performance Audit

## Objetivo

Encontrar gargalos reais no backend Spring ou no app Flutter sem introduzir arquitetura desnecessaria.

## Antes de Comecar

Leia `.ai/core/patterns.md`, `.ai/context/products.md`, `.ai/context/notifications.md` e `.ai/context/frontend.md`.

## Saida

- hotspot identificado
- causa tecnica
- melhoria incremental proposta
- pontos de medicao ou verificacao

## Regras

- Em backend, revise consultas por usuario, counts de dashboard e loops do scheduler.
- Em frontend, revise providers observados em cascata e rebuilds do `HomePage`.
- Prefira otimizar o caminho existente antes de trocar tecnologia.
- Preserve contratos da API e da UI.
