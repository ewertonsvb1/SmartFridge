# Backend Instructions

Estas instrucoes valem para mudancas no backend Spring Boot do SmartFridge.

## Sempre faca

- Leia `.ai/context/backend.md` e o contexto modular relevante.
- Mantenha o estilo de pacote por modulo.
- Use `@RequiredArgsConstructor` para injecao.
- Use `AuthenticatedUserService` para ownership por usuario.
- Use `record` para novos DTOs request/response quando seguir o padrao existente.
- Centralize regras em services.
- Reaproveite `GlobalExceptionHandler` para erros de negocio e validacao.

## Evite

- criar camada generica extra sem necessidade
- bypass de filtros por usuario
- retorno de entidade JPA diretamente no controller
- logica de negocio em repository ou controller

## Referencias locais

- `backend/src/main/java/com/smartfridge/backend/product/ProductService.java`
- `backend/src/main/java/com/smartfridge/backend/auth/AuthService.java`
- `backend/src/main/java/com/smartfridge/backend/shopping/ShoppingListService.java`
