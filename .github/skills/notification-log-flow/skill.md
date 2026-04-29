---
name: notification-log-flow
description: "Use when changing notification history behavior: creation rules, polling, modal presentation, log deduplication, or scheduler-driven alerts."
---

# Notification Log Flow

## Objetivo

Trabalhar no fluxo de notificacoes persistidas do SmartFridge.

## Antes de Comecar

Leia `.ai/context/notifications.md`, `.ai/context/products.md`, `.ai/core/patterns.md` e o contexto frontend.

## Saida

- ajuste no endpoint ou logica de logs
- ajuste no repositorio Flutter e apresentacao no modal quando necessario

## Regras

- Notificacao hoje significa `NotificationLogEntity` persistido.
- Preserve suporte a `afterId` e `limit` no endpoint quando a feature ainda depender deles.
- Nao troque o fluxo por push em tempo real sem mudar a arquitetura conscientemente.
- Mantenha o badge e o modal do app sincronizados via provider e invalidacao.
