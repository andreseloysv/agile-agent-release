# agile-agent-start.ps1 — start the Agile Agent server (without the tray launcher).
# Records the server PID in data\server.pid so it can be stopped precisely.

$ErrorActionPreference = 'Stop'
$InstallDir = $PSScriptRoot
$exe = Join-Path $InstallDir 'agile-agent-service.exe'
$dataDir = Join-Path $InstallDir 'data'
$pidFile = Join-Path $dataDir 'server.pid'

if (-not (Test-Path -LiteralPath $exe)) { throw "Server not found: $exe. Run install.ps1 again." }
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

if (Test-Path -LiteralPath $pidFile) {
    $existing = Get-Process -Id ([int](Get-Content -LiteralPath $pidFile | Select-Object -First 1)) -ErrorAction SilentlyContinue
    if ($existing -and $existing.Path -eq $exe) { Write-Host "Agile Agent is already running (PID $($existing.Id))."; return }
}

$env:AGILE_AGENT_HOME = $InstallDir
$env:AGILE_AGENT_STATIC = Join-Path $InstallDir 'public'
$p = Start-Process -FilePath $exe -WorkingDirectory $InstallDir -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput (Join-Path $dataDir 'server.log') -RedirectStandardError (Join-Path $dataDir 'server.err')
Set-Content -LiteralPath $pidFile -Value $p.Id

for ($i = 0; $i -lt 30; $i++) {
    $portFile = Join-Path $dataDir 'server.port'
    if (Test-Path -LiteralPath $portFile) {
        $port = (Get-Content -LiteralPath $portFile | Select-Object -First 1)
        Write-Host "Agile Agent is running at http://localhost:$port (PID $($p.Id))" -ForegroundColor Green
        return
    }
    if ($p.HasExited) { throw "The server exited (code $($p.ExitCode)). See $dataDir\server.err" }
    Start-Sleep -Seconds 1
}
Write-Host "Started (PID $($p.Id)); still starting up. Logs: $dataDir\server.log" -ForegroundColor Yellow
