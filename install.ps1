# install.ps1

$ErrorActionPreference = "Stop"

$installDir = "$env:USERPROFILE\.agile-agent"
$repoUrl = "https://github.com/andreseloysv/agile-agent-release.git"

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "   Installing Agile Agent...     " -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# 1. Clone or pull repo
if (Test-Path "$installDir\.git") {
    Write-Host "`nUpdating existing installation..."
    Set-Location $installDir
    git pull origin main
} else {
    Write-Host "`nCloning release repository..."
    if (Test-Path $installDir) { Remove-Item -Force -Recurse $installDir }
    git clone $repoUrl $installDir
}

# Compile Windows App
Write-Host "`nPreparing Agile Agent launcher..."
& "$installDir\scripts\build-windows-app.ps1"

# 2. Add Tray App to Startup folder
Write-Host "`nAdding shortcut to Startup..."
$startupFolder = [Environment]::GetFolderPath("Startup")

# Tray App Shortcut
$trayShortcutPath = "$startupFolder\AgileAgent.lnk"
$TrayShortcut = $WshShell.CreateShortcut($trayShortcutPath)
$TrayShortcut.TargetPath = "$installDir\Agile Agent.exe"
$TrayShortcut.WorkingDirectory = $installDir
$TrayShortcut.Save()

Write-Host "Added startup shortcut: $trayShortcutPath"

# 3. Start the Tray App
Write-Host "`nStarting Agile Agent..."
Start-Process "$installDir\Agile Agent.exe" -WorkingDirectory $installDir

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host " Installation Complete! Agile Agent is up." -ForegroundColor Green
Write-Host " Web UI: http://localhost:4372" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green

# Open browser
Start-Process "http://localhost:4372"
