$ErrorActionPreference = "Stop"

param(
    [string]$ApiBaseUrl = "http://192.168.15.12:8080",
    [switch]$Debug
)

function Write-Step($message) {
    Write-Host ""
    Write-Host "==> $message" -ForegroundColor Cyan
}

function Require-Command($commandName) {
    if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
        throw "Comando '$commandName' nao encontrado no PATH."
    }
}

function Get-JavaMajorVersion() {
    $javaVersionOutput = & java -version 2>&1 | Select-Object -First 1
    if (-not $javaVersionOutput) {
        throw "Nao foi possivel ler a versao do Java."
    }

    if ($javaVersionOutput -match '"1\.(?<legacy>\d+)\.') {
        return [int]$Matches["legacy"]
    }

    if ($javaVersionOutput -match '"(?<modern>\d+)(\.\d+)*') {
        return [int]$Matches["modern"]
    }

    throw "Formato de versao do Java nao reconhecido: $javaVersionOutput"
}

Require-Command "java"
Require-Command "flutter"

$javaMajorVersion = Get-JavaMajorVersion
if ($javaMajorVersion -lt 17) {
    throw "Java 17 ou superior e obrigatorio para gerar o APK. Versao detectada: $javaMajorVersion"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $ApiBaseUrl = Read-Host "Informe a URL da API (exemplo: http://192.168.15.12:8080)"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    throw "A URL da API nao pode ficar vazia."
}

if (-not ($ApiBaseUrl -match '^http://')) {
    throw "Use uma URL HTTP da sua rede local, por exemplo: http://192.168.15.12:8080"
}

$mobileDir = Join-Path $PSScriptRoot "..\\mobile"
$mobileDir = (Resolve-Path $mobileDir).Path

$buildMode = if ($Debug) { "debug" } else { "release" }

Push-Location $mobileDir
try {
    Write-Step "Executando flutter pub get"
    & flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar flutter pub get."
    }

    Write-Step "Gerando APK Android ($buildMode)"
    & flutter build apk "--$buildMode" `
        --dart-define=APP_ENV=prod `
        --dart-define="API_BASE_URL=$ApiBaseUrl"
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao gerar o APK."
    }
}
finally {
    Pop-Location
}

$apkName = if ($Debug) { "app-debug.apk" } else { "app-release.apk" }
$apkPath = Join-Path $mobileDir "build\\app\\outputs\\flutter-apk\\$apkName"

Write-Step "APK gerado"
Write-Host $apkPath -ForegroundColor Green
