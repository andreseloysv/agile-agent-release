$ErrorActionPreference = 'SilentlyContinue'
$port = 4372

$listening = netstat -ano | findstr ":$port "
if (-not $listening) {
    Write-Host "Agile Agent is not running on port $port"
    exit 0
}

# The PID is the last token on the netstat line
$lines = $listening -split "`r`n"
foreach ($line in $lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $tokens = -split $line
    $pidStr = $tokens[$tokens.Length - 1]
    if ($pidStr -match "^\d+$") {
        Write-Host "Stopping process ID $pidStr..."
        Stop-Process -Id $pidStr -Force
    }
}
Write-Host "Stopped Agile Agent."
