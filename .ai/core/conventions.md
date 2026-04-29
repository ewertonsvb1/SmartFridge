# Conventions

## Backend

### Organizacao

- um pacote por modulo funcional
- nomes de classes terminam com `Controller`, `Service`, `Repository`, `Mapper`, `Entity`
- DTOs ficam em subpacote `dto`
- requests e responses usam `record`

### Estilo de implementacao

- injecao por construtor com `@RequiredArgsConstructor`
- services anotados com `@Service`
- controllers anotados com `@RestController`
- operacoes de escrita usam `@Transactional`
- leituras geralmente usam `@Transactional(readOnly = true)`

### Regras de dominio recorrentes

- ownership por usuario autenticado
- validacao simples fica no service
- validacao de payload fica nos DTOs com Jakarta Validation
- mapping manual em componentes dedicados

### Nomes e contratos

- entidades usam sufixo `Entity`
- enums como `ProductStatus` e `NotificationType` usam caixa alta com underscore
- responses retornam ids e timestamps quando fizer sentido

## Frontend

### Organizacao

- `core` para infraestrutura transversal
- `features/<modulo>/data` para repositorios e models
- `features/<modulo>/presentation` para controllers e pages

### Estado

- Riverpod e a fonte principal de estado
- consultas usam `FutureProvider`
- fluxos com loading e mutacao usam `StateNotifierProvider` ou estado local do widget
- apos mutacao, o padrao e invalidar providers dependentes

### Navegacao

- rotas centralizadas em `src/app.dart`
- autenticacao resolvida por redirect do `GoRouter`
- edicao de produto usa `state.extra`

### UX

- erros do backend devem passar por `formatApiError`
- feedback de mutacao usa `SnackBar`
- formularios validam no cliente antes de chamar a API
