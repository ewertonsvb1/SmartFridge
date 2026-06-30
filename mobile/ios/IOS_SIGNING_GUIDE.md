# iOS Code Signing & Distribution

## Pré-requisitos

- macOS com Xcode instalado
- Conta Apple Developer (https://developer.apple.com)
- Certificado de desenvolvimento ou distribuição
- Provisioning profile correspondente

## Passos para Assinatura e Build

### 1. Preparar Certificados e Profiles

No macOS, abra o Xcode:

```bash
cd mobile/ios
open Runner.xcworkspace
```

Na aba "Signing & Capabilities":

1. Selecione target "Runner"
2. Abra aba "Signing & Capabilities"
3. Configure:
   - Team: Selecione seu time Apple Developer
   - Bundle Identifier: `com.smartfridge.mobile`
   - Automatic signing: Ativar (recomendado para desenvolvimento)

### 2. Build para Development (Debug)

```bash
cd mobile
flutter build ios --debug
```

Ou via Xcode:
- Build > Build for Running

### 3. Build para Release (Archive)

**Via Flutter:**
```bash
cd mobile
flutter build ios --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://smartfridge-backend-c27p.onrender.com
```

**Via Xcode:**
1. Selecione "Any iOS Device (arm64)" ou seu device
2. Product > Build for > Profiling
3. Product > Archive
4. Organizer > Distribute App

### 4. Distribuição

#### App Store (Recomendado)

1. No Xcode Organizer, selecione seu archive
2. Clique "Distribute App"
3. Escolha "App Store Connect"
4. Configure:
   - Signing: Automático
   - Upload: Xcode gerencia assinatura
5. Envie para App Store

#### TestFlight (Beta)

1. Xcode Organizer > Archive
2. Distribute App > App Store Connect > TestFlight
3. Invite beta testers via App Store Connect
4. Testers recebem convite por email

#### Ad Hoc (Testers diretos)

1. Xcode Organizer > Archive
2. Distribute App > Ad Hoc
3. Gera `.ipa` para distribuição manual
4. Usuários precisam ter UUID dos seus devices na provisioning profile

## Configuração Automática (Recomendado)

Xcode pode gerenciar tudo automaticamente:

1. Enabling "Automatically manage signing"
2. Xcode cria certificates e profiles automaticamente
3. Para Production, use "Manual signing" + App Store Connect

## Manual Signing (Avançado)

Se precisar fazer manualmente:

1. Acesse [Apple Developer](https://developer.apple.com/account)
2. Vá em "Certificates, Identifiers & Profiles"
3. Crie:
   - App ID: `com.smartfridge.mobile`
   - Certificate: iOS App Distribution
   - Provisioning Profile: App Store
4. Download do profile
5. No Xcode: Build Settings > Code Signing > Selecione manualmente

## Variáveis de Versão

No Xcode ou Flutter automaticamente sincroniza:

- Version: `$(FLUTTER_BUILD_NAME)` → pubspec.yaml version
- Build: `$(FLUTTER_BUILD_NUMBER)` → pubspec.yaml build number

Para atualizar versão:

```bash
# pubspec.yaml
version: 1.1.0+2
```

Então execute Flutter:
```bash
flutter pub get
cd ios
pod install --repo-update
```

## Troubleshooting

### Erro: "No provisioning profile found"

- Certifique-se que o Bundle ID está registrado na Apple Developer
- Regenere o provisioning profile
- Baixe novamente o profile

### Erro: "Code signing identity not found"

- Xcode > Preferences > Accounts > Download Manual Profiles
- Ou habilite "Automatically manage signing"

### Erro: "Certificate is not trusted"

- Abra Keychain Access
- Localize o certificado
- Double-click e configure "Always Trust"

## Publicar em App Store

1. Crie aplicação em [App Store Connect](https://appstoreconnect.apple.com)
2. Preencha informações do app (nome, ícone, screenshots, descrição)
3. Configure pricing e availability
4. Build > Archive no Xcode
5. Distribute > App Store > Upload

Aprovação leva geralmente 1-2 dias.

## Guia de Entrega Contínua (CI/CD)

Para automatizar assinatura em CI/CD (GitHub Actions, etc):

1. Crie Signing Certificate em Apple Developer
2. Exporte para arquivo `.p8` (API Key)
3. Configure variáveis no CI/CD:
   - `APPLE_KEY_ID`
   - `APPLE_ISSUER_ID`
   - `APPLE_KEY_CONTENT` (conteúdo do .p8 em base64)
4. Use [Fastlane](https://fastlane.tools) para automatizar:

```bash
gem install fastlane
fastlane init ios
# Configure provisioning profiles e certificados
fastlane ios build_release
```

Veja [fastlane documentation](https://docs.fastlane.tools) para mais detalhes.
