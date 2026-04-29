---
name: flutter-feature
description: "Use when creating or changing Flutter features in the project: routing, Riverpod providers, Dio repositories, forms, tabs, dialogs, and SmartFridge UI patterns."
---

# Flutter Feature

## Objetivo

Implementar telas e fluxos Flutter seguindo o padrao real do app SmartFridge.

## Antes de Comecar

Leia `.ai/context/frontend.md`, `.ai/core/conventions.md` e o contexto modular aplicavel em `.ai/context/*`.

## Saida

- Routing quando necessario
- Repository em `data`
- Provider ou controller em `presentation`
- Pagina, dialog ou aba
- Feedback com `SnackBar`

## Regras

- Use `GoRouter` centralizado em `mobile/lib/src/app.dart`.
- Use `Dio` via repositorios em `features/*/data`.
- Use Riverpod para leitura e refresh.
- Invalide providers apos mutacoes.
- Reaproveite padroes visuais atuais de Material 3, cards claros, dialogs e bottom sheets.
- Nao criar estrutura fora de `core` ou `features/<modulo>`.
