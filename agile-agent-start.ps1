$ErrorActionPreference = 'SilentlyContinue'
$port = 4372
$exePath = Join-Path $PSScriptRoot "agile-agent-windows.exe"

$running = netstat -ano | findstr ":$port "
if ($running) {
    Write-Host "Agile Agent is already running on port $port"
    exit 0
}

Write-Host "Starting Agile Agent..."
Start-Process -FilePath $exePath -WindowStyle Hidden
Write-Host "Started in background."
