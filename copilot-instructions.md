# SmartFridge - Copilot Instructions

## 📋 Visão Geral do Projeto

**SmartFridge** é uma aplicação completa de gerenciamento de geladeira inteligente com:
- **Backend**: Java 21 + Spring Boot 3.3.4 + Spring Security + JWT + Spring Data JPA
- **Mobile**: Flutter 3.4+ + Riverpod + Dio
- **Infraestrutura**: Docker Compose para orquestração
- **Banco de Dados**: H2 (dev) / PostgreSQL (prod)

---

## 🏗️ Arquitetura do Projeto

### Backend (Spring Boot)

```
backend/src/main/java/com/smartfridge/backend/
├── SmartFridgeApplication.java (entrada principal)
├── auth/              (autenticação, login, JWT)
├── user/              (usuários, perfis)
├── product/           (produtos da geladeira)
├── shopping/          (lista de compras)
├── notification/      (notificações)
├── scheduler/         (tarefas agendadas)
├── security/          (configuração segurança, JWT handler)
└── common/            (DTOs, exceções, constantes)
```

**Padrão arquitetural**: Camadas (Controller → Service → Repository)
- Controllers: Recebem requisições HTTP, validam entrada
- Services: Lógica de negócio
- Repositories: Acesso a dados via JPA
- Security: JWT (JJWT 0.12.6), Spring Security

### Mobile (Flutter)

```
mobile/lib/src/
├── app.dart           (entry point)
├── core/              (serviços, providers, utilitários)
│   ├── http/          (cliente Dio configurado)
│   ├── storage/       (persistent storage: shared_preferences, flutter_secure_storage)
│   ├── providers/     (Riverpod providers globais)
│   └── router/        (GoRouter configuração)
└── features/          (telas e lógica por feature)
    ├── auth/          (login, logout, registro)
    ├── products/      (lista, detalhes de produtos)
    ├── shopping/      (lista de compras)
    └── [outras features]/
```

**Padrão arquitetural**: Clean Architecture + Riverpod
- Features isoladas por funcionalidade
- State management com Riverpod
- HTTP requests via Dio com interceptadores
- Storage seguro com flutter_secure_storage (tokens)

---

## 🔧 Stack Tecnológico

### Backend
- **Linguagem**: Java 21 (LTS)
- **Framework**: Spring Boot 3.3.4
- **Segurança**: JWT (JJWT 0.12.6), Spring Security
- **Persistência**: Spring Data JPA, Hibernate
- **Validation**: Spring Validation (Bean Validation 3.0)
- **Build**: Maven 3.9+
- **Logging**: SLF4J + Logback (padrão Spring Boot)

### Mobile
- **Framework**: Flutter 3.4+
- **Dart SDK**: ^3.4.0 <4.0.0
- **State Management**: Riverpod 2.5.1
- **HTTP Client**: Dio 5.7.0
- **Navigation**: GoRouter 14.2.7
- **Storage**: flutter_secure_storage 9.2.2, shared_preferences 2.3.2
- **Build**: Gradle (Android), Xcode (iOS)

---

## 🚀 Inicialização e Desenvolvimento

### Requisitos do Sistema
- **Java 21+** (OpenJDK ou Oracle JDK)
- **Maven 3.9+**
- **Flutter 3.4+**
- **Dart SDK** (incluído no Flutter)
- **Docker & Docker Compose** (para infraestrutura completa)
- **Git**

### Ordem de Inicialização Obrigatória
1. **Backend PRIMEIRO** (porta 8080)
   ```bash
   cd backend
   mvn clean spring-boot:run
   ```
   - Aguarde: `Tomcat started on port(s): 8080`
   - Perfil padrão: `dev` (H2 in-memory)

2. **Mobile DEPOIS** (conecta ao backend em `http://localhost:8080`)
   ```bash
   cd mobile
   flutter pub get
   flutter run -d chrome  # ou Android/iOS conforme configurado
   ```

### Credenciais Padrão (Dev)
- **Email**: `demo@smartfridge.local`
- **Senha**: `123456`

### Profiles & Variáveis de Ambiente

#### Development (H2)
```bash
cd backend
mvn spring-boot:run  # sem -D profiles, usa dev por padrão
```
- Banco H2 em memória
- CORS liberado para `http://localhost:*`
- JWT_SECRET: configurado localmente

#### Production (PostgreSQL)
```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

**Variáveis obrigatórias** (`application-prod.yml`):
- `DB_URL`: URL JDBC PostgreSQL (ex: `jdbc:postgresql://localhost:5432/smartfridge`)
- `DB_USER`: Usuário PostgreSQL
- `DB_PASS`: Senha PostgreSQL
- `JWT_SECRET`: Mínimo 32 caracteres, seguro (não usar em código)
- `CORS_ALLOWED_ORIGINS`: URLs permitidas separadas por vírgula (ex: `https://app.seudominio.com,https://admin.seudominio.com`)

### Docker Compose
```bash
# Subir toda a infraestrutura (backend + postgres + redis, etc)
docker-compose up -d

# Logs
docker-compose logs -f backend

# Parar
docker-compose down
```

---

## 🔐 Autenticação & Segurança

### Fluxo JWT
1. **Login** (`POST /api/auth/login`): Retorna `access_token` + `refresh_token`
2. **Token armazenado**: Mobile salva em `flutter_secure_storage`
3. **Headers**: `Authorization: Bearer <token>` em todas requisições
4. **Renovação**: Refresh token quando access expirar
5. **Logout**: Remove tokens do storage, invalida no servidor

### Endpoints Públicos (sem autenticação)
- `POST /api/auth/login`
- `POST /api/auth/register` (se habilitado)
- `GET /actuator/health`

### Endpoints Protegidos
- Todos endpoints `/api/*` requerem token JWT válido

### Configuração Spring Security
- Arquivo: `backend/src/main/java/com/smartfridge/backend/security/`
- JwtTokenProvider: Geração, validação e parsing de tokens
- SecurityConfig: Configuração de autorização e CORS

---

## 🗂️ Convenções de Código

### Backend (Java)

**Nomenclatura**:
- Classes: PascalCase (ex: `ProductService`, `UserController`)
- Métodos: camelCase (ex: `findProductById()`, `updateUserProfile()`)
- Constantes: UPPER_SNAKE_CASE (ex: `DEFAULT_PAGE_SIZE`, `JWT_EXPIRATION_HOURS`)
- Pacotes: lowercase (ex: `com.smartfridge.backend.product`)

**Estrutura de Camadas**:
```
feature/
├── FeaturedNameController.java      // REST endpoints
├── FeaturedNameService.java         // Lógica de negócio
├── FeaturedNameRepository.java      // JPA Repository
├── FeaturedNameEntity.java          // @Entity JPA
├── FeaturedNameDTO.java             // Data Transfer Object
└── FeaturedNameMapper.java          // Conversão Entity ↔ DTO
```

**Anotações Padrão**:
- `@RestController` + `@RequestMapping("/api/feature")` para controllers
- `@Service` para services
- `@Repository` para repositories (JPA)
- `@Entity` para modelos JPA
- `@Data` (Lombok) em entidades quando apropriado
- `@Validated` + `@Valid` para validação
- `@Transactional` para operações que precisam

**Exemplo**:
```java
@RestController
@RequestMapping("/api/products")
@RequiredArgsConstructor
public class ProductController {
    private final ProductService productService;
    
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<List<ProductDTO>> listAll() {
        return ResponseEntity.ok(productService.findAll());
    }
}
```

### Mobile (Flutter/Dart)

**Nomenclatura**:
- Classes: PascalCase (ex: `ProductProvider`, `AuthScreen`)
- Arquivos: snake_case (ex: `product_provider.dart`, `auth_screen.dart`)
- Métodos/Funções: camelCase (ex: `fetchProducts()`, `logout()`)
- Constantes: camelCase (ex: `kBaseUrl`, `kDefaultTimeout`)
- Riverpod Providers: camelCase terminando em `Provider` (ex: `authProvider`, `productsProvider`)

**Estrutura de Features**:
```
features/auth/
├── presentation/
│   ├── pages/         // Telas (widgets de topo)
│   ├── widgets/       // Componentes reutilizáveis
│   └── providers/     // Riverpod state management
├── data/
│   ├── datasources/   // APIs, databases
│   └── models/        // DTOs/entities
└── domain/
    ├── entities/      // Modelos de negócio
    └── repositories/  // Abstract repositories
```

**Exemplo Riverpod**:
```dart
// Notifier para gerenciar estado
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());
  
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authRepository.login(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
```

---

## 📡 API REST - Convenções

### Endpoints Padrão

**Recursos**:
- `GET /api/products` - Listar todos
- `GET /api/products/{id}` - Obter um
- `POST /api/products` - Criar novo
- `PUT /api/products/{id}` - Atualizar
- `DELETE /api/products/{id}` - Deletar

**Autenticação**:
- `POST /api/auth/login` - Fazer login
- `POST /api/auth/logout` - Fazer logout
- `POST /api/auth/refresh` - Renovar token

### Response Format

**Sucesso (2xx)**:
```json
{
  "data": { /* conteúdo */ },
  "success": true
}
```

**Erro (4xx/5xx)**:
```json
{
  "error": "Mensagem de erro descritiva",
  "code": "ERROR_CODE",
  "timestamp": "2026-04-27T12:00:00Z",
  "status": 400
}
```

---

## 🧪 Testes

### Backend

**Executar todos testes**:
```bash
cd backend
mvn clean test
```

**Padrão**:
- Testes em `backend/src/test/java/`
- Nomeação: `*Test.java` ou `*Tests.java`
- Usar JUnit 5 + Mockito + AssertJ
- `@SpringBootTest` para integração
- `@WebMvcTest` para testes de controller isolado

**Exemplo**:
```java
@SpringBootTest
class AuthControllerTest {
    @MockBean
    private AuthService authService;
    
    @Test
    void shouldLoginSuccessfully() {
        // given, when, then
    }
}
```

### Mobile

**Testes widget**:
```bash
cd mobile
flutter test
```

**Testes integração**:
```bash
flutter drive --target=integration_test/app_start_test.dart
```

---

## 🐛 Troubleshooting & Dicas

### Backend

**Porta 8080 em uso**:
```powershell
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

**Reconstruir sem cache**:
```bash
mvn clean install
```

**Modo debug**:
```bash
mvn spring-boot:run -Dspring-boot.run.jvmArguments="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005"
```

**Logs com mais detalhes** (`application.yml`):
```yaml
logging:
  level:
    com.smartfridge: DEBUG
    org.springframework: INFO
```

### Mobile

**Modo web Chrome**:
```bash
cd mobile
flutter run -d chrome
```
- Porta aleatória (ex: http://localhost:52486)

**Modo Android Emulator**:
- Backend deve estar em `http://10.0.2.2:8080` (host address no emulator)

**Modo iOS Simulator**:
- Backend em `http://localhost:8080` normalmente funciona

**Limpar cache**:
```bash
flutter clean
flutter pub get
```

**Reconstruir runners**:
```bash
cd mobile/android && ./gradlew clean
cd mobile/ios && rm -rf Pods && pod install
```

### Docker

**Verificar status**:
```bash
docker-compose ps
```

**Rebuild e restart**:
```bash
docker-compose down -v
docker-compose up --build
```

---

## 📚 Estrutura de Diretórios Relevantes

```
.
├── backend/
│   ├── src/main/java/com/smartfridge/backend/    ← Código Java
│   ├── src/main/resources/
│   │   ├── application.yml                        ← Config dev
│   │   ├── application-dev.yml                    ← Override dev
│   │   └── application-prod.yml                   ← Override prod
│   ├── src/test/java/com/smartfridge/backend/    ← Testes
│   ├── target/                                    ← Build output (ignorar)
│   ├── pom.xml                                    ← Maven config
│   └── Dockerfile
│
├── mobile/
│   ├── lib/src/                                   ← Código Dart/Flutter
│   ├── test/                                      ← Testes widget
│   ├── integration_test/                          ← Testes integração
│   ├── android/                                   ← Build Android
│   ├── ios/                                       ← Build iOS
│   ├── pubspec.yaml                               ← Dependências
│   └── build/                                     ← Build output (ignorar)
│
├── scripts/
│   └── api_sweep.ps1                              ← Utilitários
│
├── docker-compose.yml                             ← Orquestração
├── README.md                                      ← Documentação geral
└── copilot-instructions.md                        ← Este arquivo
```

---

## ✅ Checklist para Novas Features

### Ao implementar um novo recurso:

- [ ] **Backend**:
  - [ ] Criar entidade JPA (`*Entity.java`)
  - [ ] Criar DTO (`*DTO.java`)
  - [ ] Criar repository (extends `JpaRepository`)
  - [ ] Criar service com lógica de negócio
  - [ ] Criar controller com endpoints REST
  - [ ] Adicionar testes unitários
  - [ ] Documentar endpoints em comentários
  - [ ] Adicionar validações (`@Valid`, `@Validated`)
  - [ ] Considerar autorização (`@PreAuthorize`)

- [ ] **Mobile**:
  - [ ] Criar models/entities
  - [ ] Criar datasource (API client com Dio)
  - [ ] Criar provider (Riverpod state)
  - [ ] Criar telas/widgets
  - [ ] Adicionar rota em GoRouter
  - [ ] Testes widget para telas principais
  - [ ] Integrar com storage se necessário

---

## 🔗 Comunicação Backend ↔ Mobile

### URLs de Conectividade

| Ambiente | URL |
|----------|-----|
| **Web (Chrome)** | http://localhost:8080 |
| **Android Emulator** | http://10.0.2.2:8080 |
| **iOS Simulator** | http://localhost:8080 |
| **Device físico** | http://<IP_MACHINE>:8080 |

### Exemplo Client Dio (Mobile)

```dart
final dio = Dio(
  BaseOptions(
    baseUrl: 'http://localhost:8080/api',
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ),
);

// Interceptador para adicionar token
dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.watch(tokenProvider); // Riverpod
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ),
);
```

---

## 📝 Git & Commits

### Padrão de Commit
```
feat: Adicionar autenticação com JWT
fix: Corrigir validação de email inválido
refactor: Reorganizar estrutura de pacotes
test: Adicionar testes para ProductService
docs: Atualizar README com instruções Docker
chore: Atualizar dependências
```

### Branches
- `main` - Release/produção
- `develop` - Integração de features
- `feature/nome-feature` - Novas features
- `bugfix/nome-bug` - Correções
- `hotfix/nome-hotfix` - Correções urgentes em prod

---

## 📞 Contato & Referências

**Documentação**:
- [Spring Boot Docs](https://spring.io/projects/spring-boot)
- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev)
- [JWT.io](https://jwt.io)

---

**Última atualização**: 27 de abril de 2026
**Versão do projeto**: 1.0.0
**Status**: Em desenvolvimento
