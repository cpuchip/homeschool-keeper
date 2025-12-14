$ErrorActionPreference = 'Stop'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Homeschool Keeper - Stop MongoDB Tunnel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot 'scripts/ssh-mongo.pid'

if (-not (Test-Path $pidFile)) {
  Write-Host "No PID file found. Tunnel is not running." -ForegroundColor Yellow
  exit 0
}

$savedPid = Get-Content $pidFile -ErrorAction SilentlyContinue
if (-not $savedPid) {
  Remove-Item $pidFile -ErrorAction SilentlyContinue
  Write-Host "PID file was empty. Cleaned up." -ForegroundColor Yellow
  exit 0
}

try {
  $p = Get-Process -Id ([int]$savedPid) -ErrorAction SilentlyContinue
  if ($p) {
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    Write-Host "Stopped SSH tunnel process (PID $($p.Id))." -ForegroundColor Green
  } else {
    Write-Host "Process PID $savedPid not found (already stopped)." -ForegroundColor Yellow
  }
} finally {
  Remove-Item $pidFile -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "MongoDB tunnel stopped." -ForegroundColor Cyan
