---
name: api-integration
description: "Use when connecting the Flutter app to existing Spring endpoints: Dio calls, JSON parsing, auth headers, and Riverpod refresh flows."
---

# API Integration

## Objetivo

Conectar o app Flutter a endpoints do backend sem quebrar o contrato atual.

## Antes de Comecar

Leia `.ai/context/backend.md`, `.ai/context/frontend.md`, `.ai/core/patterns.md` e o contexto do modulo.

## Saida

- Repositorio `Dio`
- Model de resposta quando necessario
- Provider Riverpod
- Ajuste de pagina consumidora

## Regras

- Reuse `dioProvider` de `core/network/api_client.dart`.
- Preserve o formato atual de datas como string ISO.
- Se a API usar pagina Spring, leia `response.data['content']`.
- Para erros, deixe a UI consumir `formatApiError`.
- Para rotas autenticadas, nao duplique manualmente o header Authorization; o interceptor ja faz isso.
