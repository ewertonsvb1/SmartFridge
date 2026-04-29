# Fullstack Instructions

Para features que cruzam backend e app Flutter:

1. Comece pelo contrato existente da API.
2. Implemente o endpoint Spring no modulo certo.
3. Atualize ou crie o repositorio Flutter correspondente.
4. Atualize providers Riverpod e invalidacoes.
5. Ajuste navegacao e feedback de UI se necessario.

## Checklist de consistencia

- ownership por usuario mantido no backend
- payload JSON compativel com models do app
- tratamento de erro exibindo `message` da API
- atualizacao visual apos mutacao sem reload manual complexo

## Referencias locais

- fluxo produto completo em:
  - `backend/src/main/java/com/smartfridge/backend/product/*`
  - `mobile/lib/src/features/product/*`
- fluxo auth completo em:
  - `backend/src/main/java/com/smartfridge/backend/auth/*`
  - `mobile/lib/src/features/auth/*`
