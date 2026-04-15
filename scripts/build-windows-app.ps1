$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

if (-not (Test-Path $cscPath)) {
    Write-Host "C# Compiler not found at $cscPath" -ForegroundColor Red
    exit 1
}

$cscArgs = @(
    "/target:winexe",
    "/out:`"$repoRoot\Agile Agent.exe`""
)

# Generate icon.ico from icon.png (zero-dependency, Node built-ins only)
$generateIcoScript = "$repoRoot\scripts\generate-ico.cjs"
$iconPath = "$repoRoot\scripts\icon.ico"
if (Test-Path $generateIcoScript) {
    Write-Host "Generating icon.ico from icon.png..."
    bun $generateIcoScript
}
if (Test-Path $iconPath) {
    $cscArgs += "/win32icon:`"$iconPath`""
}


$cscArgs += "`"$repoRoot\scripts\AgileAgent.cs`""

Write-Host "Compiling Agile Agent.exe native Windows launcher..."
$process = Start-Process -FilePath $cscPath -ArgumentList $cscArgs -NoNewWindow -Wait -PassThru

if ($process.ExitCode -ne 0) {
    Write-Host "Compilation failed" -ForegroundColor Red
    exit $process.ExitCode
}

Write-Host "Successfully built Agile Agent.exe!" -ForegroundColor Green
