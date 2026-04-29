# Auth Module

## Responsabilidade

Registrar usuarios, autenticar por email e senha, emitir JWT e restaurar sessao no cliente.

## Backend

Arquivos principais:

- `backend/src/main/java/com/smartfridge/backend/auth/AuthController.java`
- `backend/src/main/java/com/smartfridge/backend/auth/AuthService.java`
- `backend/src/main/java/com/smartfridge/backend/auth/dto/LoginRequest.java`
- `backend/src/main/java/com/smartfridge/backend/auth/dto/RegisterRequest.java`
- `backend/src/main/java/com/smartfridge/backend/security/*`

Fluxo real:

1. `POST /auth/register`
2. `AuthService.register` valida email unico
3. senha e codificada com `BCryptPasswordEncoder`
4. usuario e salvo em `users`
5. token JWT e devolvido em `AuthResponse`

Login:

1. `POST /auth/login`
2. `AuthenticationManager` autentica email e senha
3. usuario e buscado por email
4. `JwtService` gera token

## Frontend

Arquivos principais:

- `mobile/lib/src/features/auth/data/auth_repository.dart`
- `mobile/lib/src/features/auth/presentation/auth_controller.dart`
- `mobile/lib/src/features/auth/presentation/login_page.dart`
- `mobile/lib/src/features/auth/presentation/register_page.dart`
- `mobile/lib/src/core/auth/auth_session.dart`
- `mobile/lib/src/core/auth/token_storage.dart`

Fluxo real:

1. `AuthRepository` chama `/auth/login` ou `/auth/register`
2. token retornado e salvo no storage
3. `AuthController` marca a sessao como autenticada
4. `GoRouter` redireciona para `/home`

## Integracoes

- Spring Security
- JWT
- Flutter Secure Storage e SharedPreferences

## Regras implicitas

- email e normalizado para lowercase no backend
- o restante da API assume usuario autenticado no contexto
- logout apenas remove o token do lado cliente
