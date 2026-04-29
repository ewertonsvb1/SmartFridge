---
name: angular-feature
description: "Use when a request mentions Angular features in this project. SmartFridge does not use Angular; map the request to the existing Flutter structure: routing, Riverpod providers, Dio repositories, forms, dialogs, and UI patterns."
---

# Angular Feature

## Objetivo

Evitar implementacao na stack errada e redirecionar pedidos para o padrao Flutter real do projeto.

## Antes de Comecar

Leia `.ai/context/frontend.md`, `.ai/core/conventions.md` e `.github/skills/flutter-feature/skill.md`.

## Saida

- Mapeamento da necessidade para Flutter
- Routing
- Componente ou pagina Flutter
- Repository
- Provider

## Regras

- Nao criar Angular no repositorio.
- Traduzir a necessidade para Flutter + Riverpod + GoRouter.
- Reaproveitar a estrutura `mobile/lib/src/features/<modulo>`.
- Respeitar o padrao visual e de navegacao existente no app.
