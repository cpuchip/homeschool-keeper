Param(
  [int]$LocalPort = 27017,
  [string]$LocalBind = '127.0.0.1',
  [string]$BastionHost = '172.17.100.31',  # dokploy.hmslogs.com internal IP
  [string]$RemoteHost = '127.0.0.1',
  [int]$RemotePort = 27017,
  [string]$User = 'cpuchip'
)

$ErrorActionPreference = 'Stop'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Homeschool Keeper - MongoDB SSH Tunnel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Starting SSH tunnel: ${LocalBind}:${LocalPort} -> ${RemoteHost}:${RemotePort} via ${User}@${BastionHost}" -ForegroundColor Cyan

$repoRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $repoRoot 'scripts/ssh-mongo.pid'

# Check if tunnel is already running
if (Test-Path $pidFile) {
  $oldPid = Get-Content $pidFile -ErrorAction SilentlyContinue
  if ($oldPid) {
    try {
      $p = Get-Process -Id [int]$oldPid -ErrorAction SilentlyContinue
      if ($p) {
        Write-Host "Tunnel already running (PID $oldPid)." -ForegroundColor Yellow
        Write-Host "MongoDB available at: mongodb://${LocalBind}:${LocalPort}/homeschool-keeper" -ForegroundColor Green
        exit 0
      }
    } catch {}
  }
  Remove-Item $pidFile -ErrorAction SilentlyContinue
}

# Build ssh target
if ($User) {
  $sshTarget = "$User@$BastionHost"
} else {
  $sshTarget = $BastionHost
}

# Build ssh arguments
$sshArgs = @(
  '-N',  # No remote command
  '-L', "${LocalBind}:${LocalPort}:${RemoteHost}:${RemotePort}",  # Local port forward
  '-o', 'ServerAliveInterval=30',
  '-o', 'ServerAliveCountMax=3',
  '-o', 'ExitOnForwardFailure=yes',
  '-o', 'StrictHostKeyChecking=accept-new'
)

$allArgs = $sshArgs + $sshTarget

# Start ssh in background
$stdErr = New-TemporaryFile
try {
  $proc = Start-Process -FilePath 'ssh' -ArgumentList $allArgs -PassThru -WindowStyle Hidden -RedirectStandardError $stdErr.FullName
  
  if (-not $proc) { 
    throw 'Failed to start ssh process' 
  }
  
  Start-Sleep -Seconds 2
  
  if ($proc.HasExited) {
    $err = Get-Content $stdErr.FullName -Raw -ErrorAction SilentlyContinue
    throw "ssh exited with code $($proc.ExitCode). $err"
  }
  
  Set-Content -Path $pidFile -Value $proc.Id
  
  Write-Host ""
  Write-Host "SSH tunnel started successfully!" -ForegroundColor Green
  Write-Host "  PID: $($proc.Id)" -ForegroundColor Gray
  Write-Host "  MongoDB: mongodb://${LocalBind}:${LocalPort}/homeschool-keeper" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "Set your .env:" -ForegroundColor Yellow
  Write-Host "  MONGODB_URI=mongodb://localhost:27017/homeschool-keeper" -ForegroundColor White
  Write-Host ""
  Write-Host "To stop the tunnel:" -ForegroundColor Gray
  Write-Host "  ./scripts/ssh-mongo-stop.ps1" -ForegroundColor White
  
} finally {
  Remove-Item $stdErr -ErrorAction SilentlyContinue
}
