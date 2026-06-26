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

Para validar apenas o bootstrap versionado do schema:

```bash
cd backend
mvn -B "-Dtest=DatabaseMigrationTest" test
```

### Profile prod (PostgreSQL)

```bash
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

No profile `prod`, o schema passa a ser bootstrapado por migrations versionadas em `backend/src/main/resources/db/migration` antes da validacao final do Hibernate com `ddl-auto: validate`.

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

Se o banco estiver vazio, o Flyway aplica a migration inicial antes da subida da aplicacao. Evolucoes futuras de schema devem entrar como novas migrations versionadas, sem criacao manual de tabelas.

### Render + Supabase

Configuracao minima esperada para publicacao do backend:

- Render Web Service com deploy por `backend/Dockerfile`
- `PORT` fornecida pelo Render e consumida automaticamente pelo backend
- healthcheck em `/actuator/health`
- `DB_URL`, `DB_USER`, `DB_PASS`, `JWT_SECRET` e `CORS_ALLOWED_ORIGINS` como secrets de producao

Estrategia de conexao adotada:

- usar conexao PostgreSQL direta do Supabase com `sslmode=require`
- manter Flyway e Hibernate validando o schema na mesma conexao JDBC de `prod`
- nao usar transaction pooler como padrao inicial, para evitar friccao com migrations e com o ciclo de conexao JDBC do Spring Boot

Exemplo de `DB_URL` para Supabase:

```text
jdbc:postgresql://db.seu-projeto.supabase.co:5432/postgres?sslmode=require
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

- Android Emulator: http://10.0.2.2:8080
- Web/Windows/Linux/macOS: http://localhost:8080

Override opcional da URL da API ao rodar o app:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_HOST:PORTA
```

Quando `APP_ENV=prod`, `API_BASE_URL` passa a ser obrigatoria e deve ser uma URL absoluta `http(s)` que nao aponte para `localhost`, `127.0.0.1` ou `10.0.2.2`.

### Rodar no Android fisico

Para aparelho Android real, o backend local precisa estar acessivel fora do emulador.

Opcoes suportadas:

1. Mesmo Wi-Fi:
   - descubra o IP da sua maquina na rede local
   - suba o backend em `http://0.0.0.0:8080` ou mantenha a porta acessivel na rede
   - rode o app com:

```bash
flutter run --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:8080
```

2. USB com `adb reverse`:
   - conecte o Android com depuracao USB ativa
   - execute:

```bash
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Observacoes importantes:

- `10.0.2.2` funciona apenas no Android Emulator
- `localhost` no celular aponta para o proprio aparelho, nao para o seu PC
- a leitura de QR Code no Android usa permissao de camera declarada no manifesto

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

No `release`, o manifesto Android desabilita `cleartext traffic`, entao o endpoint configurado em `API_BASE_URL` deve estar acessivel pela URL publica planejada para publicacao. O fluxo local atual continua preservado em `debug`.

### Smoke test em device para release

Use um APK release apontando para a API publicada:

```bash
cd mobile
flutter build apk --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.seudominio.com
```

Checklist minimo no Android fisico:

1. instalar o APK release gerado
2. abrir o app sem depender de `adb reverse`
3. criar conta ou autenticar com uma conta real
4. validar carregamento do fluxo principal contra a API publica
5. confirmar que nao ha dependencia de `localhost` ou `10.0.2.2`

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

Use o script unico de inicializacao:

###########
###LIGAR###
###########
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_smarthouse_web.ps1 -ForceRestart
```


- executa `flutter pub get`
- sobe o backend Spring Boot em `http://127.0.0.1:8080`
- sobe o Flutter Web em `http://127.0.0.1:3000`
- abre o app no Chrome automaticamente

Se preferir nao abrir o navegador:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start_smarthouse_web.ps1 -ForceRestart -NoChrome
```

Os logs ficam em `scripts/logs/`.

Para encerrar backend e Flutter Web com um unico comando:
###########
###DESLIGAR###
###########
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\stop_smarthouse_web.ps1
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
