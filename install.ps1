# install.ps1 — Agile Agent installer / updater for Windows (PowerShell 5.1+)
#
#   irm https://raw.githubusercontent.com/andreseloysv/agile-agent-release/main/install.ps1 | iex
#
# Installs into %USERPROFILE%\.agile-agent without needing Git, Bun or admin rights:
#   1. stops a running Agile Agent (only our own processes)
#   2. downloads the release files (web UI, migrations, scripts) as a .zip
#   3. downloads the server (agile-agent-service.exe) atomically
#   4. builds the tray launcher with the C# compiler that ships with Windows
#   5. installs the VS Code extension (if VS Code is present)
#   6. adds a Startup shortcut and starts Agile Agent
# User data in %USERPROFILE%\.agile-agent\data is never deleted or overwritten.
# Running it again updates an existing installation.

param(
    [string]$ZipUrl = 'https://github.com/andreseloysv/agile-agent-release/archive/refs/heads/main.zip',
    [string]$ExeUrl = 'https://github.com/andreseloysv/agile-agent-release/releases/latest/download/agile-agent-service.exe',
    # Folder copied over the installation after extraction (for testing unreleased scripts)
    [string]$OverlayDir = '',
    # Update mode: start the tray silently instead of opening the browser
    [switch]$Update,
    [switch]$NoStart
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is very slow with the progress bar in PS 5.1
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$InstallDir = Join-Path $env:USERPROFILE '.agile-agent'
$DataDir = Join-Path $InstallDir 'data'
$ServiceExe = Join-Path $InstallDir 'agile-agent-service.exe'
$LauncherExe = Join-Path $InstallDir 'Agile Agent.exe'

function Write-Step($msg) { Write-Host "`n== $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "  OK  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  !!  $msg" -ForegroundColor Yellow }

function Stop-AgileAgent {
    # Only processes that belong to this installation (never "whatever listens on the port")
    Get-Process -Name 'Agile Agent' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path -like "$InstallDir*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    $pidFile = Join-Path $DataDir 'server.pid'
    if (Test-Path -LiteralPath $pidFile) {
        $serverPid = (Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1)
        if ($serverPid -match '^\d+$') {
            $proc = Get-Process -Id ([int]$serverPid) -ErrorAction SilentlyContinue
            if ($proc -and $proc.Path -and $proc.Path -like "$InstallDir*") { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
        }
        Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    }
    Get-Process -Name 'agile-agent-service' -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -and $_.Path -like "$InstallDir*" } | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

function Get-File([string]$Source, [string]$Dest) {
    if (Test-Path -LiteralPath $Source) { Copy-Item -LiteralPath $Source -Destination $Dest -Force }
    else { Invoke-WebRequest -Uri $Source -OutFile $Dest -UseBasicParsing }
}

# Download/copy to "<dest>.download", check it is a real Windows executable, then replace <dest>.
function Install-Executable([string]$Source, [string]$Dest) {
    $tmp = "$Dest.download"
    Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    try {
        Get-File $Source $tmp
        $size = (Get-Item -LiteralPath $tmp).Length
        $fs = [IO.File]::OpenRead($tmp)
        try { $b0 = $fs.ReadByte(); $b1 = $fs.ReadByte() } finally { $fs.Dispose() }
        if ($size -lt 10000000 -or $b0 -ne 0x4D -or $b1 -ne 0x5A) {   # "MZ"
            throw "downloaded file is not a valid executable ($size bytes)"
        }
        Move-Item -LiteralPath $tmp -Destination $Dest -Force
    } catch {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
        throw
    }
}

try {
    Write-Host '=================================' -ForegroundColor Cyan
    Write-Host '   Installing Agile Agent...     ' -ForegroundColor Cyan
    Write-Host '=================================' -ForegroundColor Cyan
    Write-Host "Install folder: $InstallDir"

    Write-Step 'Stopping a running Agile Agent'
    Stop-AgileAgent
    Write-Ok 'Stopped (if it was running)'

    Write-Step 'Downloading release files'
    New-Item -ItemType Directory -Force -Path $InstallDir, $DataDir | Out-Null
    $tmpRoot = Join-Path ([IO.Path]::GetTempPath()) ('agile-agent-install-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null
    try {
        $zip = Join-Path $tmpRoot 'release.zip'
        Get-File $ZipUrl $zip
        Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $tmpRoot 'x') -Force
        $top = Get-ChildItem -LiteralPath (Join-Path $tmpRoot 'x') -Directory | Select-Object -First 1
        if (-not $top) { throw 'release archive is empty' }
        # Copy over the installation; data\ is not in the archive, so user data is untouched
        Get-ChildItem -LiteralPath $top.FullName -Force | ForEach-Object {
            if ($_.Name -ne 'data') { Copy-Item -LiteralPath $_.FullName -Destination $InstallDir -Recurse -Force }
        }
    } finally {
        Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($OverlayDir) {
        Get-ChildItem -LiteralPath $OverlayDir -Force | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $InstallDir -Recurse -Force }
        Write-Ok "Overlay applied from $OverlayDir"
    }
    Write-Ok 'Release files installed'

    Write-Step 'Downloading the Agile Agent server'
    Install-Executable $ExeUrl $ServiceExe
    $version = Get-Content -LiteralPath (Join-Path $InstallDir 'VERSION') -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($version) { Set-Content -LiteralPath (Join-Path $InstallDir '.binary-version') -Value $version }
    Write-Ok ("agile-agent-service.exe ready" + $(if ($version) { " ($version)" } else { '' }))

    Write-Step 'Building the tray launcher'
    $launcherOk = $false
    try {
        & (Join-Path $InstallDir 'scripts\build-windows-app.ps1') -OutPath $LauncherExe
        $launcherOk = Test-Path -LiteralPath $LauncherExe
    } catch { Write-Warn "Could not build the launcher: $($_.Exception.Message)" }
    if ($launcherOk) { Write-Ok 'Agile Agent.exe built' }

    Write-Step 'VS Code extension'
    $extScript = Join-Path $InstallDir 'scripts\install-vscode-extension.ps1'
    if (Test-Path -LiteralPath $extScript) { & $extScript -InstallDir $InstallDir }
    else { Write-Warn 'Extension installer not found in this release - skipping' }

    if ($launcherOk) {
        Write-Step 'Start with Windows'
        $startup = [Environment]::GetFolderPath('Startup')
        Remove-Item -LiteralPath (Join-Path $startup 'AgileAgent.lnk') -Force -ErrorAction SilentlyContinue   # legacy name
        $shell = New-Object -ComObject WScript.Shell
        $lnk = $shell.CreateShortcut((Join-Path $startup 'Agile Agent.lnk'))
        $lnk.TargetPath = $LauncherExe
        $lnk.Arguments = '--tray'
        $lnk.WorkingDirectory = $InstallDir
        $lnk.Save()
        Write-Ok 'Startup shortcut created'
    }

    if (-not $NoStart) {
        Write-Step 'Starting Agile Agent'
        if ($launcherOk) {
            $launchArgs = @()
            if ($Update) { $launchArgs += '--tray' }
            if ($launchArgs.Count -gt 0) { Start-Process -FilePath $LauncherExe -ArgumentList $launchArgs -WorkingDirectory $InstallDir }
            else { Start-Process -FilePath $LauncherExe -WorkingDirectory $InstallDir }
        } else {
            & (Join-Path $InstallDir 'agile-agent-start.ps1')
        }
        Write-Ok 'Started'
    }

    Write-Host "`n==========================================" -ForegroundColor Green
    Write-Host ' Agile Agent is installed.' -ForegroundColor Green
    Write-Host ' Web UI: http://localhost:4372' -ForegroundColor Yellow
    Write-Host ' Uninstall: powershell -ExecutionPolicy Bypass -File "%USERPROFILE%\.agile-agent\uninstall.ps1"'
    Write-Host '==========================================' -ForegroundColor Green
} catch {
    Write-Host "`nInstallation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Your data in %USERPROFILE%\.agile-agent\data was not changed. Fix the problem above and run the installer again.'
    # As a script file (-File, the .exe installer, update.ps1) report failure through the exit code.
    # Under "irm | iex" an exit would close the user's PowerShell window, so just stop.
    if ($PSCommandPath) { exit 1 } else { return }
}
