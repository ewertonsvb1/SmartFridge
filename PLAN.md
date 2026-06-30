# Checklist de Subida do Projeto

## Resumo
O código está perto do ponto de deploy. O que falta agora é principalmente execução operacional: provisionar infraestrutura real, preencher secrets reais, publicar o backend e validar o app Android contra a API pública. Abaixo eu separo claramente o que eu posso fazer no repositório e o que só você pode fazer fora dele.

## O Que Eu Posso Fazer
1. Revisar e ajustar qualquer configuração restante no código antes do deploy.
2. Validar novamente os checks locais:
   - `cd backend && mvn -B test`
   - `cd mobile && flutter analyze`
   - `cd mobile && flutter build apk --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://smartfridge-backend-c27p.onrender.com`
3. Corrigir problemas de configuração de runtime, CORS, manifest Android, `API_BASE_URL` e docs do fluxo.
4. Ajudar a interpretar qualquer erro que aparecer no Render, Supabase, Maven, Flutter ou Gradle.
5. Montar comandos exatos para smoke test e rollback quando você tiver a URL publicada.

## O Que Só Você Pode Fazer
1. Criar o projeto no Supabase.
2. Obter as credenciais reais do banco:
   - host
   - porta
   - database
   - username
   - password
3. Criar o serviço no Render e conectar ao repositório.
4. Cadastrar os secrets reais no Render:
   - `DB_URL`
   - `DB_USER`
   - `DB_PASS`
   - `JWT_SECRET`
   - `CORS_ALLOWED_ORIGINS`
5. Definir a URL pública final do backend.
6. Gerar ou fornecer a keystore real de release Android.
7. Instalar o APK em um Android físico e validar o fluxo real publicado.

## Passo a Passo Que Você Precisa Fazer

### 1. Subir o banco no Supabase
1. Crie um projeto no Supabase.
2. Vá na área de database/connection details.
3. Copie a conexão PostgreSQL direta.
4. Monte a `DB_URL` no formato:
   `jdbc:postgresql://HOST:5432/postgres?sslmode=require`
5. Guarde também:
   - `DB_USER`
   - `DB_PASS`

### 2. Publicar o backend no Render
1. Crie um novo Web Service no Render.
2. Aponte para este repositório.
3. Configure o deploy via `backend/Dockerfile`.
4. Cadastre as env vars:
   - `DB_URL=...`
   - `DB_USER=...`
   - `DB_PASS=...`
   - `JWT_SECRET=...`
   - `CORS_ALLOWED_ORIGINS=https://SEU_FRONT_OU_ORIGEM`
5. Não configure `PORT` manualmente; o Render injeta isso.
6. Configure o healthcheck para:
   `/actuator/health`
7. Execute o deploy.

### 3. Validar o backend publicado
1. Abra:
   `https://smartfridge-backend-c27p.onrender.com/actuator/health`
2. Confirme resposta `200`.
3. Teste cadastro e login com usuário real.
4. Se falhar no startup:
   - verifique logs do Render
   - confirme `DB_URL`, `DB_USER`, `DB_PASS`
   - confirme se o banco aceita conexão direta e não pooler transacional
   - confirme `JWT_SECRET` e `CORS_ALLOWED_ORIGINS`

### 4. Preparar o Android release
1. Gere ou localize sua keystore.
2. Preencha `mobile/android/key.properties` ou use env vars:
   - `ANDROID_STORE_FILE`
   - `ANDROID_STORE_PASSWORD`
   - `ANDROID_KEY_ALIAS`
   - `ANDROID_KEY_PASSWORD`
3. Use a URL pública real do backend.

### 5. Gerar o APK/AAB
1. Rode:
   `cd mobile`
2. Gere o APK:
   `flutter build apk --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://smartfridge-backend-c27p.onrender.com`
3. Se quiser bundle:
   `flutter build appbundle --release --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://smartfridge-backend-c27p.onrender.com`

### 6. Validar no celular
1. Instale o APK no Android físico.
2. Abra o app sem `adb reverse`.
3. Faça cadastro ou login.
4. Entre no fluxo principal.
5. Confirme que o app usa a API pública e não depende de:
   - `localhost`
   - `127.0.0.1`
   - `10.0.2.2`

## Testes e Critérios de Aceite
- Backend:
  - `mvn -B test` verde
  - `/actuator/health` público com `200`
- Mobile:
  - `flutter analyze` verde
  - `flutter build apk --release ...` verde
  - instalação e login funcionando no device
- Risco residual atual:
  - `flutter test` ainda falha no baseline em `mobile/test/features/product/nfce_import_page_test.dart`

## Assumptions
- Vamos usar Render para o backend HTTP.
- Vamos usar conexão PostgreSQL direta do Supabase com `sslmode=require`.
- O deploy inicial não depende de automação de Play Store.
- A falha atual do teste de NFC-e será tratada como pendência paralela, não bloqueio absoluto para publicar backend e gerar release Android.
