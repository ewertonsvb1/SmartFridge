# Users Module

## Responsabilidade

Representar o usuario autenticado e expor seu perfil basico.

## Backend

Arquivos principais:

- `backend/src/main/java/com/smartfridge/backend/user/UserEntity.java`
- `backend/src/main/java/com/smartfridge/backend/user/UserRepository.java`
- `backend/src/main/java/com/smartfridge/backend/user/UserService.java`
- `backend/src/main/java/com/smartfridge/backend/user/UserController.java`
- `backend/src/main/java/com/smartfridge/backend/user/UserMapper.java`
- `backend/src/main/java/com/smartfridge/backend/user/DevUserSeeder.java`

Endpoint atual:

- `GET /users/me`

Fluxo real:

- `UserService.me()` usa `AuthenticatedUserService`
- `UserMapper` retorna `UserResponse`
- no profile `dev`, `DevUserSeeder` cria `demo@smartfridge.local / 123456`

## Integracoes com outros modulos

- produtos, compras e notificacoes pertencem a um `UserEntity`
- filtros de ownership acontecem por `userId`

## Regras importantes

- o projeto ainda nao tem papel, perfil administrativo ou RBAC
- qualquer extensao de usuario deve preservar o contrato simples atual
