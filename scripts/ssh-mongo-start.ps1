Param(
  [int]$LocalPort = 27027,
  [string]$LocalBind = '127.0.0.1',
  [string]$BastionHost = '172.17.100.31',  # Dokploy server (internal IP)
  [string]$RemoteHost = '127.0.0.1',  # Where MongoDB is accessible on the remote server
  [int]$RemotePort = 27027,  # Dokploy publishes MongoDB on 27027
  [string]$User = 'cpuchip',
  [switch]$FindContainer  # Use this to auto-discover MongoDB container IP
)

$ErrorActionPreference = 'Stop'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Homeschool Keeper - MongoDB SSH Tunnel" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# If MongoDB is running in Docker Swarm, we may need to find its IP
# The container DNS name (e.g., hmslogscom-mongodb-zpbnhu) only works inside Docker network
# Options:
#   1. If MongoDB port is published to host: use 127.0.0.1:27017 (default)
#   2. If MongoDB is only on Docker network: use -FindContainer to discover IP
#   3. Manual: specify -RemoteHost with container IP

if ($FindContainer) {
  Write-Host "Discovering MongoDB container IP on remote server..." -ForegroundColor Yellow
  Write-Host "(This requires SSH access and docker permissions)" -ForegroundColor Gray
  
  # Find MongoDB container IP via SSH
  $sshCmd = "docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' `$(docker ps -q --filter 'name=mongodb' | head -1) 2>/dev/null || echo 'NOT_FOUND'"
  $containerIp = ssh "${User}@${BastionHost}" $sshCmd 2>$null
  
  if ($containerIp -and $containerIp -ne 'NOT_FOUND' -and $containerIp -ne '') {
    $RemoteHost = $containerIp.Trim()
    Write-Host "Found MongoDB container at: $RemoteHost" -ForegroundColor Green
  } else {
    Write-Host "Could not find MongoDB container. Falling back to 127.0.0.1" -ForegroundColor Yellow
    Write-Host "Make sure MongoDB port is published to host, or specify -RemoteHost manually" -ForegroundColor Yellow
  }
}

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
  Write-Host "  Tunnel: localhost:${LocalPort} -> ${RemoteHost}:${RemotePort}" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "For VS Code MongoDB extension, use:" -ForegroundColor Yellow
  Write-Host "  mongodb://hmslogs:<password>@localhost:${LocalPort}/hmslogs_dev" -ForegroundColor White
  Write-Host ""
  Write-Host "Or set in .env:" -ForegroundColor Yellow
  Write-Host "  MONGODB_URI=mongodb://hmslogs:<password>@localhost:${LocalPort}" -ForegroundColor White
  Write-Host "  MONGO_DB=hmslogs_dev" -ForegroundColor White
  Write-Host ""
  Write-Host "To stop the tunnel:" -ForegroundColor Gray
  Write-Host "  ./scripts/ssh-mongo-stop.ps1" -ForegroundColor White
  Write-Host ""
  Write-Host "Troubleshooting Docker Swarm MongoDB:" -ForegroundColor Gray
  Write-Host "  If connection fails, MongoDB may not be published to host." -ForegroundColor Gray
  Write-Host "  Try: ./scripts/ssh-mongo-start.ps1 -FindContainer" -ForegroundColor Gray
  Write-Host "  Or manually specify: -RemoteHost <container-ip>" -ForegroundColor Gray
  
} finally {
  Remove-Item $stdErr -ErrorAction SilentlyContinue
}
