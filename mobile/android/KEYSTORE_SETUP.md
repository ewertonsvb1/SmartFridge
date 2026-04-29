# Android Keystore Setup

## Gerar Keystore para Release

Execute este comando para gerar uma nova keystore (execute uma única vez):

### Windows (PowerShell)
```powershell
keytool -genkey -v -keystore ./keystore/smartfridge-release.jks `
  -keyalg RSA -keysize 2048 -validity 10950 `
  -alias smartfridge
```

### Linux/macOS
```bash
keytool -genkey -v -keystore ./keystore/smartfridge-release.jks \
  -keyalg RSA -keysize 2048 -validity 10950 \
  -alias smartfridge
```

**Parâmetros:**
- `smartfridge-release.jks`: Nome do arquivo keystore
- `keyalg RSA`: Algoritmo de criptografia
- `keysize 2048`: Tamanho da chave
- `validity 10950`: Validade em dias (~30 anos)
- `alias smartfridge`: Alias da chave

## Informações Solicitadas

Durante a geração, você será solicitado a fornecer:

1. **Keystore Password**: Senha da keystore (use caracteres fortes)
2. **Key Password**: Senha da chave privada (pode ser igual à keystore)
3. **First and Last Name**: Nome da pessoa/empresa
4. **Organizational Unit**: Unidade organizacional
5. **Organization**: Organização
6. **City/Locality**: Cidade
7. **State/Province**: Estado/Província
8. **Country Code**: Código do país (2 letras, ex: BR)

## Configurar key.properties

1. Copie o template:
```bash
copy key.properties.example key.properties
```

2. Abra `key.properties` e preencha com suas informações:

```properties
storeFile=../keystore/smartfridge-release.jks
storePassword=SEU_PASSWORD_AQUI
keyAlias=smartfridge
keyPassword=SEU_PASSWORD_AQUI
```

**IMPORTANTE:** 
- ✅ Nunca commite `key.properties` no repositório
- ✅ Guarde as senhas em local seguro
- ✅ Faça backup do arquivo `.jks`

## Variáveis de Ambiente (CI/CD)

Para CI/CD, configure estas variáveis de ambiente:

```bash
ANDROID_STORE_FILE=/path/to/smartfridge-release.jks
ANDROID_STORE_PASSWORD=sua_password
ANDROID_KEY_ALIAS=smartfridge
ANDROID_KEY_PASSWORD=sua_password
```

## Verificar Keystore

Para listar chaves na keystore:

```bash
keytool -list -v -keystore ./keystore/smartfridge-release.jks -alias smartfridge
```

## Recriar Keystore

Se precisar recriar a keystore:

1. Remova o arquivo antigo
2. Execute o comando de geração novamente
3. Use as mesmas informações (alias, senhas) se possível

**AVISO:** Cada vez que você cria uma nova keystore, o app recebe um novo fingerprint. Usuários que instalaram versões anteriores NÃO conseguirão fazer update automático (deverão desinstalar e reinstalar).
