# Frontend Context

## Stack real

O cliente atual do projeto nao e Angular nem React. Ele e um app Flutter.

- Flutter
- Dart 3
- `flutter_riverpod`
- `dio`
- `go_router`
- `flutter_secure_storage`
- `shared_preferences`
- Material 3

Arquivos de referencia:

- `mobile/pubspec.yaml`
- `mobile/lib/main.dart`
- `mobile/lib/src/app.dart`

## Estrutura de pastas

Codigo principal:

- `mobile/lib/src`

Divisao atual:

- `core/auth`
- `core/network`
- `features/auth`
- `features/home`
- `features/product`
- `features/shopping`
- `features/notification`

## Organizacao de features

O padrao atual e enxuto:

1. `data/*_repository.dart` encapsula chamadas HTTP e parsing
2. `presentation/*_controller.dart` expoe `Provider`, `FutureProvider` ou `StateNotifierProvider`
3. paginas ficam em `presentation/*_page.dart`

Exemplos:

- `features/auth/data/auth_repository.dart`
- `features/auth/presentation/auth_controller.dart`
- `features/product/data/product_repository.dart`
- `features/product/presentation/product_form_page.dart`

## Navegacao e autenticacao

- roteamento centralizado em `mobile/lib/src/app.dart`
- `GoRouter` usa `redirect` baseado em `AuthSession`
- telas publicas: `/login`, `/register`, `/splash`
- telas autenticadas: `/home`, `/product/new`, `/product/edit`
- o token JWT e salvo por `HybridTokenStorage`
- web usa `SharedPreferences`; plataformas nativas usam `FlutterSecureStorage`

## Padroes visuais observados

- Material 3 com `ColorScheme.fromSeed(seedColor: Color(0xFF0E7C7B))`
- home com fundo claro `Color(0xFFF4F5F3)`
- uso frequente de cards brancos, cantos bem arredondados e icones Material
- feedback de sucesso e erro com `SnackBar`
- modais e dialogs para editar e excluir itens

## Integracao com backend

- `Dio` configurado em `core/network/api_client.dart`
- JWT e anexado automaticamente para rotas fora de `/auth`
- URL base vem de `API_BASE_URL` ou do default publicado em `https://smartfridge-backend-c27p.onrender.com`
- produtos consomem pagina Spring, lendo `response.data['content']`

## Observacoes importantes

- O app e mais proximo de um cliente mobile/web unico do que de um frontend web tradicional.
- Nao existe sistema de permissoes por papel no cliente; existe apenas sessao autenticada.
- O modulo `home` concentra produtos, filtros e lista de compras em abas no mesmo `HomePage`.
