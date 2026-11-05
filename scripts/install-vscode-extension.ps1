# install-vscode-extension.ps1
# Downloads the Agile Agent Copilot Bridge (.vsix) from the latest release and installs it
# into VS Code, wherever VS Code lives on this machine:
#   - `code` / `code-insiders` on PATH
#   - per-user install  (%LOCALAPPDATA%\Programs\Microsoft VS Code)
#   - system install    (%ProgramFiles%, %ProgramFiles(x86)%)
#   - custom folders    (InstallLocation from the Windows uninstall registry keys)
# Compatible with Windows PowerShell 5.1 and PowerShell 7. Never throws: a missing VS Code
# or a network error only prints a warning, so the main installer keeps going.

param(
    [string]$InstallDir = (Join-Path $env:USERPROFILE '.agile-agent'),
    [string]$VsixUrl = 'https://github.com/andreseloysv/agile-agent-release/releases/latest/download/copilot-bridge.vsix'
)

$ErrorActionPreference = 'Continue'

function Find-VSCodeCli {
    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($name in @('code', 'code-insiders')) {
        $cmd = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) { $candidates.Add($cmd.Source) }
    }

    $roots = @()
    if ($env:LOCALAPPDATA) { $roots += (Join-Path $env:LOCALAPPDATA 'Programs') }
    if ($env:ProgramFiles) { $roots += $env:ProgramFiles }
    if (${env:ProgramFiles(x86)}) { $roots += ${env:ProgramFiles(x86)} }
    foreach ($root in $roots) {
        $candidates.Add((Join-Path $root 'Microsoft VS Code\bin\code.cmd'))
        $candidates.Add((Join-Path $root 'Microsoft VS Code Insiders\bin\code-insiders.cmd'))
    }

    # Custom install folders: read InstallLocation from the uninstall registry entries
    $uninstallKeys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($key in $uninstallKeys) {
        $entries = Get-ItemProperty -Path $key -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like 'Microsoft Visual Studio Code*' -and $_.InstallLocation }
        foreach ($entry in $entries) {
            $candidates.Add((Join-Path $entry.InstallLocation 'bin\code.cmd'))
            $candidates.Add((Join-Path $entry.InstallLocation 'bin\code-insiders.cmd'))
        }
    }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { return $c }
    }
    return $null
}

$vsixPath = Join-Path $InstallDir 'copilot-bridge.vsix'

# 1. Download the .vsix (a GitHub Release asset, not part of the git repo)
try {
    # Windows PowerShell 5.1 defaults to TLS 1.0, which GitHub rejects
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    if (-not (Test-Path -LiteralPath $InstallDir)) { New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null }
    Write-Host 'Downloading VS Code Copilot Bridge extension...'
    Invoke-WebRequest -Uri $VsixUrl -OutFile $vsixPath -UseBasicParsing
} catch {
    Write-Host "WARNING: Could not download the VS Code extension: $($_.Exception.Message)" -ForegroundColor Yellow
}

if (-not (Test-Path -LiteralPath $vsixPath -PathType Leaf)) {
    Write-Host 'No VS Code extension available - skipping.' -ForegroundColor Yellow
    return
}

# 2. Install it with whichever VS Code is present
$cli = Find-VSCodeCli
if (-not $cli) {
    Write-Host 'VS Code not found. After installing VS Code, run:' -ForegroundColor Yellow
    Write-Host "  code --install-extension `"$vsixPath`"" -ForegroundColor Yellow
    return
}

Write-Host "Installing VS Code extension via $cli ..."
# The VS Code launcher is an Electron app; never let it run as plain Node
Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
try {
    & $cli --install-extension $vsixPath --force | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Write-Host 'Copilot Bridge extension installed in VS Code.' -ForegroundColor Green
    } else {
        Write-Host "WARNING: VS Code returned exit code $LASTEXITCODE. Install manually: code --install-extension `"$vsixPath`"" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Could not install the extension: $($_.Exception.Message)" -ForegroundColor Yellow
}
