# Mobile Instructions

Estas instrucoes valem para mudancas no app Flutter.

## Sempre faca

- Leia `.ai/context/frontend.md` e o contexto do modulo alvo.
- Coloque acesso HTTP em `data/*_repository.dart`.
- Exponha leitura por Riverpod em `presentation/*_controller.dart` ou provider equivalente.
- Use `formatApiError` para mensagens de falha vindas da API.
- Invalide providers apos mutacoes.
- Respeite o roteamento central em `mobile/lib/src/app.dart`.

## Evite

- chamadas HTTP diretamente nas paginas
- duplicar regra de negocio que o backend ja resolve
- criar gerenciador de estado paralelo ao Riverpod
- quebrar o fluxo de token em `AuthSession` e `TokenStorage`

## Referencias locais

- `mobile/lib/src/features/product/data/product_repository.dart`
- `mobile/lib/src/features/auth/presentation/auth_controller.dart`
- `mobile/lib/src/features/home/presentation/home_page.dart`
