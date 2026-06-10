param(
    [switch]$ForceRestart,
    [switch]$NoChrome,
    [int]$BackendPort = 8080,
    [int]$WebPort = 3000
)

$ErrorActionPreference = "Stop"

function Get-ToolPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $command = Get-Command $Name -ErrorAction Stop
    return $command.Source
}

function Get-PortProcessId {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    $connection = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1

    if ($null -ne $connection) {
        return $connection.OwningProcess
    }

    return $null
}

function Ensure-PortAvailable {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $processId = Get-PortProcessId -Port $Port
    if ($null -eq $processId) {
        return
    }

    if (-not $ForceRestart) {
        throw "$Label ja esta usando a porta $Port. Rode novamente com -ForceRestart para reiniciar esse processo."
    }

    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($null -eq $process) {
        throw "Nao foi possivel identificar o processo que ocupa a porta $Port."
    }

    Write-Host "Encerrando $Label existente na porta $Port (PID $processId)..."
    Stop-Process -Id $processId -Force
    Start-Sleep -Seconds 2
}

function Wait-HttpReady {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [Parameter(Mandatory = $true)]
        [string]$Label,
        [int]$TimeoutSeconds = 120
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    while ($stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                Write-Host "$Label pronto em $Url"
                return
            }
        }
        catch {
            $statusCode = $null
            if ($null -ne $_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            if ($null -ne $statusCode -and $statusCode -ge 200 -and $statusCode -lt 500) {
                Write-Host "$Label pronto em $Url"
                return
            }

            Start-Sleep -Seconds 2
        }
    }

    throw "Timeout aguardando $Label em $Url. Verifique os logs gerados."
}

function Get-ChromePath {
    $candidates = @(
        "C:\Program Files\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$backendDir = Join-Path $repoRoot "backend"
$mobileDir = Join-Path $repoRoot "mobile"
$logsDir = Join-Path $scriptDir "logs"

New-Item -ItemType Directory -Path $logsDir -Force | Out-Null

$backendStdout = Join-Path $logsDir "backend.out.log"
$backendStderr = Join-Path $logsDir "backend.err.log"
$mobileStdout = Join-Path $logsDir "mobile-web.out.log"
$mobileStderr = Join-Path $logsDir "mobile-web.err.log"

Write-Host "Validando ferramentas..."
$mavenPath = Get-ToolPath -Name "mvn"
$flutterPath = Get-ToolPath -Name "flutter"

Ensure-PortAvailable -Port $BackendPort -Label "Backend"
Ensure-PortAvailable -Port $WebPort -Label "Flutter Web"

Write-Host "Atualizando dependencias do Flutter..."
& $flutterPath "pub" "get" | Out-Host

Write-Host "Subindo backend na porta $BackendPort..."
$backendProcess = Start-Process `
    -FilePath $mavenPath `
    -ArgumentList "spring-boot:run" `
    -WorkingDirectory $backendDir `
    -RedirectStandardOutput $backendStdout `
    -RedirectStandardError $backendStderr `
    -WindowStyle Hidden `
    -PassThru

Write-Host "Subindo Flutter Web na porta $WebPort..."
$flutterArguments = @(
    "run",
    "-d",
    "web-server",
    "--web-hostname",
    "127.0.0.1",
    "--web-port",
    $WebPort,
    "--dart-define=API_BASE_URL=http://127.0.0.1:$BackendPort"
)

$mobileProcess = Start-Process `
    -FilePath $flutterPath `
    -ArgumentList $flutterArguments `
    -WorkingDirectory $mobileDir `
    -RedirectStandardOutput $mobileStdout `
    -RedirectStandardError $mobileStderr `
    -WindowStyle Hidden `
    -PassThru

Wait-HttpReady -Url "http://127.0.0.1:$BackendPort/actuator/health" -Label "Backend"
Wait-HttpReady -Url "http://127.0.0.1:$WebPort" -Label "Flutter Web"

$appUrl = "http://127.0.0.1:$WebPort"

if (-not $NoChrome) {
    $chromePath = Get-ChromePath
    if ($null -ne $chromePath) {
        Write-Host "Abrindo Chrome em $appUrl"
        Start-Process -FilePath $chromePath -ArgumentList $appUrl
    }
    else {
        Write-Warning "Chrome nao encontrado. Abra manualmente: $appUrl"
    }
}

Write-Host ""
Write-Host "Projeto inicializado com sucesso."
Write-Host "Backend PID: $($backendProcess.Id)"
Write-Host "Flutter Web PID: $($mobileProcess.Id)"
Write-Host "App: $appUrl"
Write-Host "API: http://127.0.0.1:$BackendPort"
Write-Host "Logs backend: $backendStdout | $backendStderr"
Write-Host "Logs mobile: $mobileStdout | $mobileStderr"
