# Backend Context

## Stack real

- Java 21
- Spring Boot 3.3.4
- Spring Web
- Spring Data JPA
- Spring Security
- Spring Validation
- Spring Actuator
- JWT com `io.jsonwebtoken:jjwt`
- Lombok
- H2 no profile `dev`
- PostgreSQL no profile `prod`

Arquivo de referencia:

- `backend/pom.xml`
- `backend/src/main/resources/application.yml`
- `backend/src/main/resources/application-dev.yml`
- `backend/src/main/resources/application-prod.yml`

## Estrutura de pastas

Codigo principal:

- `backend/src/main/java/com/smartfridge/backend`

Pacotes atuais:

- `auth`
- `common/exception`
- `notification`
- `product`
- `scheduler`
- `security`
- `shopping`
- `user`

## Arquitetura observada

O backend e um monolito modular por pacote de dominio. Cada modulo tende a seguir este desenho:

1. `Controller` exposto por REST
2. `Service` com regra de negocio
3. `Repository` JPA
4. `Entity`
5. `Mapper`
6. `dto` com `record`

Exemplo forte:

- `product/ProductController.java`
- `product/ProductService.java`
- `product/ProductRepository.java`
- `product/ProductEntity.java`
- `product/ProductMapper.java`
- `product/dto/*`

## Seguranca e autenticacao

- `SecurityConfig` libera apenas `/auth/**` e `/h2-console/**`
- todo o resto exige JWT
- `JwtAuthenticationFilter` injeta o principal no contexto
- `AuthenticatedUserService` e o caminho padrao para obter o usuario atual
- as regras multiusuario sao aplicadas por filtro de `userId` dentro dos services e repositories

## Persistencia

Padrao atual:

- entidades com `@Entity`, `@Table`, `@Id`, `@GeneratedValue`
- `createdAt` preenchido em `@PrePersist`
- relacoes com `@ManyToOne(fetch = FetchType.LAZY, optional = false)`
- status de produto e notificacao persistidos como `EnumType.STRING`
- filtros opcionais sensiveis a `null` em PostgreSQL devem preferir `Specification`/Criteria dinamica em vez de `@Query` com `:param is null or ...`

## Convencoes de API

- controllers usam `@RequestMapping` no plural do recurso, exceto `shopping-list`
- criacao retorna `201 Created`
- delete retorna `204 No Content`
- validacao usa `@Valid` no controller e constraints em `record`
- erros de negocio e validacao passam por `GlobalExceptionHandler`

## Integracoes externas

- banco H2 em desenvolvimento
- PostgreSQL em producao
- cliente mobile Flutter via HTTP
- CI com GitHub Actions em `.github/workflows/backend-ci.yml`

## Observacoes importantes

- Nao existe camada DDD formal, aggregate root, use case ou ports/adapters.
- Nao existe migracao versionada com Flyway/Liquibase; o projeto usa `ddl-auto: update` em dev e `validate` em prod.
- O scheduler `ProductStatusScheduler` recalcula status diariamente as 02:00.
