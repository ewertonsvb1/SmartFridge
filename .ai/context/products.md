# Products Module

## Responsabilidade

Gerenciar o estoque da geladeira por usuario, incluindo CRUD, dashboard, filtros por status e recalculo de vencimento.

## Backend

Arquivos principais:

- `backend/src/main/java/com/smartfridge/backend/product/ProductController.java`
- `backend/src/main/java/com/smartfridge/backend/product/ProductService.java`
- `backend/src/main/java/com/smartfridge/backend/product/ProductRepository.java`
- `backend/src/main/java/com/smartfridge/backend/product/ProductSpecification.java`
- `backend/src/main/java/com/smartfridge/backend/product/ProductMapper.java`
- `backend/src/main/java/com/smartfridge/backend/product/dto/*`

Endpoints atuais:

- `POST /products`
- `GET /products`
- `GET /products/{id}`
- `PUT /products/{id}`
- `DELETE /products/{id}`
- `GET /products/expired`
- `GET /products/expiring?days=3`
- `GET /products/dashboard`

Fluxos centrais:

1. Criacao ou update validam se `expirationDate >= manufactureDate`
2. o usuario e obtido via `AuthenticatedUserService`
3. `status` e calculado por `calculateStatus`
4. listas sempre filtram por usuario autenticado
5. o dashboard devolve `total`, `expired` e `nearExpiration`

Status reais:

- `OK`
- `NEAR_EXPIRATION`
- `EXPIRED`

## Notificacoes relacionadas

Ao salvar ou recalcular status, `ProductService` chama `NotificationLogService.registerIfNotExists` para:

- `EXPIRED`
- `NEAR_EXPIRATION`

## Frontend

Arquivos principais:

- `mobile/lib/src/features/product/data/product_repository.dart`
- `mobile/lib/src/features/product/presentation/product_controller.dart`
- `mobile/lib/src/features/product/presentation/product_form_page.dart`
- `mobile/lib/src/features/home/presentation/home_page.dart`

Fluxos reais no app:

- listagem principal usa `GET /products?size=50&sort=createdAt,desc`
- filtros usam `status=EXPIRED` e `status=NEAR_EXPIRATION`
- dashboard consome `/products/dashboard`
- create e update invalidam `productListProvider`, `dashboardProvider`, `expiredProductsProvider` e `nearExpirationProductsProvider`

## Regras importantes

- nunca consultar produto de outro usuario
- manter o contrato JSON atual de datas em string ISO
- nao calcular status no cliente como fonte da verdade; usar o backend
