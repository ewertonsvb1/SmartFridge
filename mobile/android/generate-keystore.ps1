# Script para gerar Keystore Android

param(
    [string]$keystorePath = "../keystore",
    [string]$keystoreFile = "smartfridge-release.jks",
    [string]$alias = "smartfridge",
    [int]$validity = 10950  # ~30 anos
)

# Verificar se keytool existe
$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    Write-Error "keytool nao encontrado. Certifique-se de que Java JDK esta instalado e JAVA_HOME esta configurado."
    exit 1
}

# Criar diretorio se nao existir
if (-not (Test-Path $keystorePath)) {
    New-Item -ItemType Directory -Path $keystorePath -Force
    Write-Host "Diretorio criado: $keystorePath"
}

$fullPath = Join-Path $keystorePath $keystoreFile

# Verificar se ja existe
if (Test-Path $fullPath) {
    Write-Host "AVISO: Keystore ja existe em: $fullPath"
    $confirm = Read-Host "Deseja sobrescrever? (S/N)"
    if ($confirm -ne "S" -and $confirm -ne "s") {
        Write-Host "Operacao cancelada."
        exit 0
    }
}

Write-Host "Gerando keystore para Android..."
Write-Host "Arquivo: $fullPath"
Write-Host ""

# Gerar keystore
& keytool -genkey -v -keystore $fullPath `
    -keyalg RSA -keysize 2048 -validity $validity `
    -alias $alias

if ($?) {
    Write-Host ""
    Write-Host "✓ Keystore gerada com sucesso!"
    Write-Host ""
    Write-Host "Proximos passos:"
    Write-Host "1. Copie: copy key.properties.example key.properties"
    Write-Host "2. Edite key.properties com os dados:"
    Write-Host "   storeFile=../keystore/$keystoreFile"
    Write-Host "   storePassword=<USE_SUA_PASSWORD>"
    Write-Host "   keyAlias=$alias"
    Write-Host "   keyPassword=<USE_SUA_PASSWORD>"
    Write-Host ""
    Write-Host "Para CI/CD, configure variaveis de ambiente:"
    Write-Host "   ANDROID_STORE_FILE=../keystore/$keystoreFile"
    Write-Host "   ANDROID_STORE_PASSWORD=<USE_SUA_PASSWORD>"
    Write-Host "   ANDROID_KEY_ALIAS=$alias"
    Write-Host "   ANDROID_KEY_PASSWORD=<USE_SUA_PASSWORD>"
} else {
    Write-Error "Erro ao gerar keystore."
    exit 1
}
