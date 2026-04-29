---
name: product-status-flow
description: "Use when changing expiration rules, dashboard counts, expiring filters, or notification side effects for products."
---

# Product Status Flow

## Objetivo

Alterar a logica de status de produto e seus efeitos colaterais no sistema.

## Antes de Comecar

Leia `.ai/context/products.md`, `.ai/context/notifications.md`, `.ai/core/patterns.md` e `ProductService.java`.

## Saida

- regra atualizada de status
- impacto em endpoints e dashboard
- ajuste de notificacao e scheduler se necessario

## Regras

- A fonte da verdade do status e `ProductService.calculateStatus`.
- Mudancas de status precisam considerar `recalculateAllStatusesAndPrepareLogs()`.
- Logs de notificacao nao podem duplicar no mesmo dia para o mesmo produto e tipo.
- O app deve continuar consumindo os status `OK`, `NEAR_EXPIRATION` e `EXPIRED`, salvo mudanca intencional de contrato.
