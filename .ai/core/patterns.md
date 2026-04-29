# Patterns

## Padrao 1: CRUD com ownership por usuario

Recorrencia:

- buscar usuario atual via `AuthenticatedUserService`
- criar entidade com relacao `user`
- consultar por `findByIdAndUser_Id(...)` ou specification com `userId`

Onde aparece:

- `ProductService`
- `ShoppingListService`
- `NotificationController`

## Padrao 2: Mapper manual

O projeto prefere mapper manual em classe simples, sem MapStruct.

Onde aparece:

- `ProductMapper`
- `ShoppingListMapper`
- `UserMapper`

## Padrao 3: DTO request/response com `record`

Requests e responses do backend usam `record`, com validacao diretamente nos campos.

Onde aparece:

- `ProductCreateRequest`
- `ProductUpdateRequest`
- `LoginRequest`
- `RegisterRequest`
- `ShoppingListCreateRequest`

## Padrao 4: Regras de dominio no service

A camada service concentra regras como:

- datas validas
- calculo de status
- prevencao de email duplicado
- criacao de notificacao sem duplicidade diaria

## Padrao 5: Query de produto por filtros incrementais

Produtos usam `Specification` para compor filtros opcionais.

Onde aparece:

- `ProductSpecification.belongsToUser`
- `ProductSpecification.withName`
- `ProductSpecification.withStatus`

## Padrao 6: Cliente Flutter com repositorio fino

Repositorios Flutter sao diretos:

- constroem request com `Dio`
- fazem parsing minimo para model
- nao concentram muita regra de negocio

## Padrao 7: Refresh via invalidacao Riverpod

Apos mutacoes, o app nao atualiza listas manualmente; ele invalida providers.

Onde aparece:

- formulario de produto
- exclusao de produto
- operacoes da lista de compras
- fechamento do modal de notificacoes

## Padrao 8: Feedback simples de erro

- backend retorna `ErrorResponse(status, message, timestamp)`
- frontend usa `formatApiError` para exibir mensagem amigavel

## Padrao 9: Automacao de status

- `ProductService.recalculateAllStatusesAndPrepareLogs()`
- `ProductStatusScheduler` executa diariamente

Esse e o padrao certo para jobs relacionados a manutencao de produto.
