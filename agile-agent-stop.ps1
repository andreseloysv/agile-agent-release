# agile-agent-stop.ps1 — stop the Agile Agent server started from this folder.
# Stops only our own server process (by PID file / executable path), never other programs on the port.

$InstallDir = $PSScriptRoot
$exe = Join-Path $InstallDir 'agile-agent-service.exe'
$pidFile = Join-Path $InstallDir 'data\server.pid'
$stopped = $false

if (Test-Path -LiteralPath $pidFile) {
    $p = Get-Process -Id ([int](Get-Content -LiteralPath $pidFile | Select-Object -First 1)) -ErrorAction SilentlyContinue
    if ($p -and $p.Path -eq $exe) { Stop-Process -Id $p.Id -Force; $stopped = $true }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}
Get-Process -Name 'agile-agent-service' -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe } |
    ForEach-Object { Stop-Process -Id $_.Id -Force; $stopped = $true }
Remove-Item -LiteralPath (Join-Path $InstallDir 'data\server.port') -Force -ErrorAction SilentlyContinue

if ($stopped) { Write-Host 'Agile Agent stopped.' } else { Write-Host 'Agile Agent was not running.' }
