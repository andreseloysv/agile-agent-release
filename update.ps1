# update.ps1 — update Agile Agent on Windows.
# Started by the tray launcher ("Check for updates"), which exits first so its .exe can be replaced.
# Compares the published VERSION with the installed one and, if newer (or -Force), runs the latest
# install.ps1 in update mode (keeps data, restarts the tray silently).

param(
    [switch]$Force,
    [int]$WaitForPid = 0
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Raw = 'https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main'
$InstallDir = Join-Path $env:USERPROFILE '.agile-agent'
$Log = Join-Path $InstallDir 'data\update.log'

function Log($msg) {
    $line = '{0:yyyy-MM-dd HH:mm:ss} {1}' -f (Get-Date), $msg
    Write-Host $line
    try { Add-Content -LiteralPath $Log -Value $line } catch { }
}

try {
    if ($WaitForPid -gt 0) {
        # Let the launcher exit so its executable is not locked
        Wait-Process -Id $WaitForPid -Timeout 30 -ErrorAction SilentlyContinue
    }

    $remote = ((Invoke-WebRequest -Uri "$Raw/VERSION" -UseBasicParsing).Content -split "`n")[0].Trim()
    $local = (Get-Content -LiteralPath (Join-Path $InstallDir '.binary-version') -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $Force -and $remote -and $local -eq $remote -and (Test-Path -LiteralPath (Join-Path $InstallDir 'agile-agent-service.exe'))) {
        Log "Already up to date ($local)."
        $launcher = Join-Path $InstallDir 'Agile Agent.exe'
        if ($WaitForPid -gt 0 -and (Test-Path -LiteralPath $launcher)) { Start-Process -FilePath $launcher -ArgumentList '--tray' -WorkingDirectory $InstallDir }
        exit 0
    }

    Log "Updating $local -> $remote ..."
    $installer = Join-Path ([IO.Path]::GetTempPath()) ('agile-agent-install-' + [Guid]::NewGuid().ToString('N') + '.ps1')
    Invoke-WebRequest -Uri "$Raw/install.ps1" -OutFile $installer -UseBasicParsing
    try {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -Update
        $code = $LASTEXITCODE
    } finally {
        Remove-Item -LiteralPath $installer -Force -ErrorAction SilentlyContinue
    }
    if ($code -ne 0) { throw "installer failed with exit code $code" }
    Log "Updated to $remote."
    exit 0
} catch {
    Log "Update failed: $($_.Exception.Message)"
    exit 1
}
