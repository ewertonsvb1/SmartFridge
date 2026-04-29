# SmartFridge

Projeto completo do zero com:

- Backend: Java 21 + Spring Boot 3 + JWT + PostgreSQL/H2
- Mobile: Flutter + Riverpod + Dio

## Estrutura

- backend
- mobile

## Backend

### Requisitos

- Java 21+
- Maven 3.9+

### Rodar em dev (H2)

```bash
cd backend
mvn spring-boot:run
```

### Testes

```bash
cd backend
mvn clean test
```

### Profile prod (PostgreSQL)

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

Variáveis obrigatórias para prod:

- DB_URL
- DB_USER
- DB_PASS
- JWT_SECRET (mínimo 32 caracteres)
- CORS_ALLOWED_ORIGINS (separado por virgula, ex.: https://app.seudominio.com)

**Configuração recomendada:**

Copie o arquivo de exemplo:
```bash
cd backend
copy .env.example .env
```

Edite `backend/.env` com suas credenciais de produção.

Execute com:
```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

**Importante:** O arquivo `.env` está no `.gitignore` e nunca será commitado.

Veja [backend/.env.example](backend/.env.example) para documentação completa das variáveis.

## Mobile

### Requisitos

- Flutter 3.22+

### Rodar app

```bash
cd mobile
flutter pub get
flutter run
```

Base URL atual no app:

- Android Emulator: http://10.0.2.2:8081
- Web/Windows/Linux/macOS: http://localhost:8081

Override opcional da URL da API ao rodar o app:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_HOST:PORTA
```

### Configuração do App - Android

1. **Nome do app**: Edite `mobile/android/app/src/main/res/values/strings.xml`
   - Tag: `<string name="app_name">SmartFridge</string>`

2. **Identificador único (Package)**: `com.smartfridge.mobile`
   - Arquivo: `mobile/android/app/build.gradle.kts`

3. **Versão do app**: Edite `mobile/pubspec.yaml`
   - Formato: `version: X.Y.Z+buildNumber`
   - Ex: `version: 1.0.0+1`

4. **Permissões necessárias**: Já incluídas em `mobile/android/app/src/main/AndroidManifest.xml`
   - `INTERNET` - requisição à API
   - `ACCESS_NETWORK_STATE` - verificar conectividade

### Build de release Android (APK/AAB)

1. Configure assinatura copiando o template:

```bash
cd mobile/android
copy key.properties.example key.properties
```

2. Preencha `key.properties` com os dados da sua keystore.

3. Gere os artefatos:

```bash
cd mobile
flutter build apk --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.seudominio.com
flutter build appbundle --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.seudominio.com
```

Variáveis de ambiente para assinatura (CI):
- ANDROID_STORE_FILE
- ANDROID_STORE_PASSWORD
- ANDROID_KEY_ALIAS
- ANDROID_KEY_PASSWORD

### Gerar Keystore Android

**Primeira vez apenas** - Execute para criar a keystore:

**Windows PowerShell:**
```powershell
cd mobile/android
.\generate-keystore.ps1
```

**Linux/macOS:**
```bash
cd mobile/android
keytool -genkey -v -keystore ./keystore/smartfridge-release.jks \
  -keyalg RSA -keysize 2048 -validity 10950 \
  -alias smartfridge
```

Veja instruções completas em [mobile/android/KEYSTORE_SETUP.md](mobile/android/KEYSTORE_SETUP.md)

**Importante:** 
- Nunca commite `key.properties` ou o arquivo `.jks` no repositório
- Faça backup seguro da keystore e senhas

### Configuração do App - iOS

1. **Nome do app**: `Smartfridge Mobile` (em `mobile/ios/Runner/Info.plist`)

2. **Bundle ID**: `com.smartfridge.mobile` (configurado no Xcode)

3. **Versão do app**: Automática pelo `mobile/pubspec.yaml`

4. **Permissões necessárias**: Já configuradas em `mobile/ios/Runner/Info.plist`
   - NSLocalNetworkUsageDescription - comunicação com backend
   - NSBonjourServices - descoberta de serviços locais

5. **Build para release (requer macOS)**:
   - Abra `mobile/ios/Runner.xcworkspace` no Xcode
   - Configure Team ID e Signing Certificate
   - Build > Archive > Distribuir

Veja guia completo de assinatura em [mobile/ios/IOS_SIGNING_GUIDE.md](mobile/ios/IOS_SIGNING_GUIDE.md)

## CI/CD Pipeline

Workflows automáticos executam em cada push/PR:

### Backend Pipeline
- ✅ Build + testes com Maven
- ✅ Gera JAR (`backend-1.0.0.jar`)
- ✅ Publica artefato por 30 dias

**Artefato disponível em:** GitHub Actions > Artifacts > `backend-jar`

### Mobile Pipeline
- ✅ Análise estática com flutter analyze
- ✅ Testes unitários com flutter test
- ✅ Build APK e AAB
- ✅ Publica artefatos por 30 dias

**Artefatos disponíveis em:** GitHub Actions > Artifacts > `android-apk`, `android-aab`

### Usar Artefatos do CI

1. Acesse seu repositório > Actions
2. Selecione última run bem-sucedida
3. Baixe artifacts desejados
4. APK/AAB prontos para testes ou publicação na Play Store
5. JAR pronto para deployment

### Conta de acesso (dev)

Quando o backend roda com profile `dev`, uma conta padrao e criada automaticamente:

- Login: demo@smartfridge.local
- Senha: 123456

## Executar projeto completo

### Windows (PowerShell)

```powershell
cd backend; Start-Process cmd -ArgumentList "/k mvn spring-boot:run"; cd ../mobile; flutter pub get; flutter run
```

### Linux/macOS/Git Bash

```bash
cd backend && mvn spring-boot:run & cd ../mobile && flutter pub get && flutter run
```

## Funcionalidades implementadas

- Auth: /auth/register e /auth/login
- User: /users/me
- Product: CRUD, /expired, /expiring, /dashboard
- Shopping List: CRUD
- Scheduler diário para recálculo de status e geração de notification log sem duplicidade diária
- Erros globais com status, message e timestamp
- Paginação e filtros dinâmicos para produtos

## Observação

O ambiente local de Maven pode exibir warnings de SLF4J duplicado por instalação local, mas os testes do projeto passam normalmente.
