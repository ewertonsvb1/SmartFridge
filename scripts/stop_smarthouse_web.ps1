param(
    [int]$BackendPort = 8080,
    [int]$WebPort = 3000
)

$ErrorActionPreference = "Stop"

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

function Stop-PortProcess {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Port,
        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    $processId = Get-PortProcessId -Port $Port
    if ($null -eq $processId) {
        Write-Host "$Label nao estava ativo na porta $Port."
        return $false
    }

    $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
    if ($null -eq $process) {
        Write-Warning "Nao foi possivel localizar o processo do $Label na porta $Port."
        return $false
    }

    Write-Host "Encerrando $Label na porta $Port (PID $processId)..."
    Stop-Process -Id $processId -Force
    Start-Sleep -Seconds 2
    return $true
}

$backendStopped = Stop-PortProcess -Port $BackendPort -Label "Backend"
$webStopped = Stop-PortProcess -Port $WebPort -Label "Flutter Web"

Write-Host ""
if (-not $backendStopped -and -not $webStopped) {
    Write-Host "Nenhum processo do SmartHouse Web estava em execucao."
} else {
    Write-Host "Ambiente web do SmartHouse encerrado."
}
