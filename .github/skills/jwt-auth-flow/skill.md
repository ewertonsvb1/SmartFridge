---
name: jwt-auth-flow
description: "Use when changing authentication or session behavior in SmartFridge: register, login, token storage, route guards, and authenticated API access."
---

# JWT Auth Flow

## Objetivo

Modificar autenticacao e sessao mantendo o fluxo atual entre Spring Security, JWT e Flutter.

## Antes de Comecar

Leia `.ai/context/auth.md`, `.ai/context/backend.md`, `.ai/context/frontend.md` e `.ai/core/patterns.md`.

## Saida

- ajuste de endpoint ou servico de auth
- ajuste de storage e sessao no app quando necessario
- revisao de redirects autenticados

## Regras

- Backend deve continuar emitindo token em `AuthResponse`.
- Emails devem continuar sendo normalizados em lowercase.
- O app deve persistir o token via `TokenStorage`.
- Guardas de navegacao devem continuar concentrados em `GoRouter` + `AuthSession`.
- Nao introduza refresh token ou RBAC sem demanda explicita do dominio.
