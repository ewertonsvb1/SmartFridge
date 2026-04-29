# Notifications Module

## Responsabilidade

Persistir eventos de produto vencido ou proximo do vencimento e exibi-los no app.

## Backend

Arquivos principais:

- `backend/src/main/java/com/smartfridge/backend/notification/NotificationController.java`
- `backend/src/main/java/com/smartfridge/backend/notification/NotificationLogEntity.java`
- `backend/src/main/java/com/smartfridge/backend/notification/NotificationLogRepository.java`
- `backend/src/main/java/com/smartfridge/backend/notification/NotificationLogService.java`
- `backend/src/main/java/com/smartfridge/backend/notification/NotificationType.java`

Endpoint atual:

- `GET /notifications`

Comportamento real:

- suporta `afterId` opcional
- suporta `limit`, limitado entre 1 e 100
- sem `afterId`, busca mais recentes por pagina
- com `afterId`, busca incrementos em ordem crescente
- resposta inclui `productId`, `productName`, `productExpirationDate` e `createdAt`

## Geracao de logs

Logs surgem por dois caminhos:

1. ao criar ou atualizar produto
2. no scheduler diario `ProductStatusScheduler`

Duplicidade diaria e evitada por:

- `existsByUser_IdAndProduct_IdAndTypeAndEventDate(...)`

## Frontend

Arquivos principais:

- `mobile/lib/src/features/notification/data/notification_repository.dart`
- `mobile/lib/src/features/home/presentation/home_page.dart`

Fluxo real no app:

- o sino no topo abre um `showModalBottomSheet`
- o badge verde aparece quando a lista nao esta vazia
- ao fechar o modal, o app faz `ref.invalidate(notificationsProvider)`

## Regras importantes

- notificacao hoje e log persistido, nao push em tempo real
- manter `NotificationType` restrito ao contrato atual, salvo mudanca intencional de dominio
