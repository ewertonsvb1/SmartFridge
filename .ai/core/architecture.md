# Architecture

## Tipo de arquitetura

O projeto atual e um monolito modular com dois executaveis principais:

1. backend REST em Spring Boot
2. cliente Flutter que consome essa API

Nao ha microservicos, BFF separado nem frontend web independente.

## Comunicacao entre modulos

### Backend

Os modulos se comunicam por chamada direta entre services e repositories dentro do mesmo processo.

Exemplos reais:

- `ProductService` chama `NotificationLogService`
- `UserService` chama `AuthenticatedUserService`
- `NotificationController` consulta `NotificationLogRepository` e `AuthenticatedUserService`

### Frontend

As features se comunicam principalmente por:

- providers Riverpod
- invalidacao de cache com `ref.invalidate(...)`
- navegacao `GoRouter`

## Fronteira backend x frontend

- autenticacao por JWT Bearer
- contratos JSON simples
- datas enviadas como string ISO
- lista de produtos reaproveita pagina Spring (`content`)

## Persistencia e ambiente

- dev: H2 em memoria com `ddl-auto: update`
- prod: PostgreSQL com `ddl-auto: validate`
- deploy local integrado por `docker-compose.yml`

## Agregados praticos do sistema

Mesmo sem DDD formal, o codigo aponta estes centros de responsabilidade:

- `auth/user`: identidade e sessao
- `product`: estoque da geladeira e dashboard
- `shopping`: lista de compras
- `notification`: historico de alertas
- `scheduler`: manutencao automatica de status

## Consequencias para agentes de IA

- novas features devem nascer dentro de um modulo existente ou de um novo pacote vertical
- ownership por usuario e obrigatorio nas entidades de negocio
- toda feature full-stack relevante tende a exigir: endpoint Spring, repositorio Flutter, provider Riverpod e atualizacao da UI
