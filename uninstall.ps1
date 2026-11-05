# uninstall.ps1 — remove Agile Agent from Windows.
#
#   powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.agile-agent\uninstall.ps1"
#
# Stops Agile Agent, removes the Startup shortcut, the VS Code extension and the program files.
# Your data (%USERPROFILE%\.agile-agent\data: projects, conversations, settings) is KEPT unless
# you pass -RemoveData.

param(
    [switch]$RemoveData
)

$ErrorActionPreference = 'Continue'
$InstallDir = Join-Path $env:USERPROFILE '.agile-agent'
$DataDir = Join-Path $InstallDir 'data'

Write-Host 'Uninstalling Agile Agent...' -ForegroundColor Cyan

# 1. Stop our own processes only
Get-Process -Name 'Agile Agent', 'agile-agent-service' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path -like "$InstallDir*" } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 2. Startup shortcuts (current and legacy names)
$startup = [Environment]::GetFolderPath('Startup')
foreach ($name in 'Agile Agent.lnk', 'AgileAgent.lnk') {
    Remove-Item -LiteralPath (Join-Path $startup $name) -Force -ErrorAction SilentlyContinue
}
Write-Host '  Startup shortcut removed'

# 3. VS Code extension
$code = Get-Command code -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Source
if (-not $code) {
    $code = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
}
if ($code) {
    Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
    & $code --uninstall-extension agile-agent.agile-agent-copilot-bridge 2>$null | Out-Null
    Write-Host '  VS Code extension removed'
}

# 4. Program files (keep data unless -RemoveData)
if (Test-Path -LiteralPath $InstallDir) {
    if ($RemoveData) {
        Remove-Item -LiteralPath $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host '  Program files and data removed'
    } else {
        Get-ChildItem -LiteralPath $InstallDir -Force | Where-Object { $_.Name -ne 'data' } |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        # Runtime files that only make sense while the server runs
        foreach ($f in 'server.pid', 'server.port') { Remove-Item -LiteralPath (Join-Path $DataDir $f) -Force -ErrorAction SilentlyContinue }
        Write-Host "  Program files removed. Your data was kept in $DataDir"
        Write-Host '  (run again with -RemoveData to delete it too)'
    }
}

Write-Host 'Agile Agent has been uninstalled.' -ForegroundColor Green
