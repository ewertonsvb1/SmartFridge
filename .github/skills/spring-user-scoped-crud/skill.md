---
name: spring-user-scoped-crud
description: "Use when creating or changing CRUD endpoints in the Spring Boot API that belong to the authenticated user: products, shopping list, profile-owned resources."
---

# Spring User Scoped CRUD

## Objetivo

Criar ou alterar CRUDs do backend mantendo o padrao de ownership por usuario autenticado.

## Antes de Comecar

Leia `.ai/context/backend.md`, `.ai/context/users.md`, `.ai/core/conventions.md` e o contexto do modulo alvo.

## Saida

- Controller REST
- Service com regra
- Repository JPA
- DTOs `record`
- Mapper manual

## Regras

- Use `AuthenticatedUserService` para obter o usuario atual.
- Filtre leituras e updates por `userId`.
- Retorne DTOs, nao entidades JPA.
- Mantenha `@Transactional` em escrita e `readOnly = true` em leitura quando fizer sentido.
- Siga o desenho visto em `ProductService` e `ShoppingListService`.
