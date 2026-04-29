# Shopping Module

## Responsabilidade

Manter a lista de compras do usuario autenticado com criacao, marcacao, edicao e exclusao de itens.

## Backend

Arquivos principais:

- `backend/src/main/java/com/smartfridge/backend/shopping/ShoppingListController.java`
- `backend/src/main/java/com/smartfridge/backend/shopping/ShoppingListService.java`
- `backend/src/main/java/com/smartfridge/backend/shopping/ShoppingListRepository.java`
- `backend/src/main/java/com/smartfridge/backend/shopping/ShoppingListMapper.java`
- `backend/src/main/java/com/smartfridge/backend/shopping/dto/*`

Endpoints atuais:

- `POST /shopping-list`
- `GET /shopping-list`
- `PUT /shopping-list/{id}`
- `DELETE /shopping-list/{id}`

Fluxo real:

1. create cria item com `checked = false`
2. list ordena por `createdAt desc`
3. update sobrescreve `name`, `quantity` e `checked`
4. qualquer busca por id combina `id` + `userId`

## Frontend

Arquivos principais:

- `mobile/lib/src/features/shopping/data/shopping_repository.dart`
- `mobile/lib/src/features/shopping/presentation/shopping_controller.dart`
- `mobile/lib/src/features/home/presentation/home_page.dart`

Fluxo real no app:

- a aba Compras usa `shoppingListProvider`
- criacao e edicao acontecem via `AlertDialog`
- toggle do checkbox chama `repo.update(...)`
- apos mutacao, o padrao e `ref.invalidate(shoppingListProvider)`

## Regras importantes

- manter o endpoint singular atual `/shopping-list`
- nao introduzir pagina separada se a alteracao couber na aba atual
- seguir o modelo `ShoppingItem` no app e `ShoppingListResponse` no backend
