# build-windows-app.ps1 — compile the Agile Agent tray launcher (AgileAgent.cs)
# with the C# compiler that ships with the .NET Framework on every Windows 10/11.
# No Bun / Node / Visual Studio needed. The icon is the committed scripts\icon.ico.

param(
    [string]$OutPath = ''
)

$ErrorActionPreference = 'Stop'

$scriptsDir = $PSScriptRoot
$repoRoot = Split-Path -Parent $scriptsDir
if (-not $OutPath) { $OutPath = Join-Path $repoRoot 'Agile Agent.exe' }

$csc = @(
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $csc) {
    throw 'C# compiler (csc.exe) from the .NET Framework 4 was not found'
}

$source = Join-Path $scriptsDir 'AgileAgent.cs'
$icon = Join-Path $scriptsDir 'icon.ico'
$tmpOut = "$OutPath.build"
Remove-Item -LiteralPath $tmpOut -Force -ErrorAction SilentlyContinue

$cscArgs = @('/nologo', '/target:winexe', '/optimize+', "/out:$tmpOut")
if (Test-Path -LiteralPath $icon) { $cscArgs += "/win32icon:$icon" }
$cscArgs += $source

Write-Host 'Compiling Agile Agent.exe (native Windows launcher)...'
& $csc @cscArgs
if ($LASTEXITCODE -ne 0) {
    Remove-Item -LiteralPath $tmpOut -Force -ErrorAction SilentlyContinue
    throw "Compilation failed (csc exit code $LASTEXITCODE)"
}
# Replace only after a successful build (the old launcher keeps working if compilation fails)
Move-Item -LiteralPath $tmpOut -Destination $OutPath -Force
Write-Host "Built $OutPath" -ForegroundColor Green
