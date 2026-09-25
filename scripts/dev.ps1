# Development script for Windows PowerShell
# Runs both Go backend and Vue frontend in development mode

Write-Host "Starting Homeschool Keeper Development Environment" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Check if MongoDB is running
Write-Host "`nChecking MongoDB..." -ForegroundColor Yellow
$mongoRunning = $false
try {
    $result = Invoke-Expression "mongosh --eval 'db.adminCommand(\"ping\")' --quiet 2>&1"
    if ($LASTEXITCODE -eq 0) {
        $mongoRunning = $true
        Write-Host "MongoDB is running" -ForegroundColor Green
    }
} catch {
    Write-Host "MongoDB check failed - make sure MongoDB is running" -ForegroundColor Red
}

if (-not $mongoRunning) {
    Write-Host "Starting MongoDB via Docker Compose..." -ForegroundColor Yellow
    docker-compose up -d mongo
    Start-Sleep -Seconds 5
}

# Start backend
Write-Host "`nStarting Go backend..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    Set-Location backend
    go run .
}

# Wait for backend to start
Start-Sleep -Seconds 3

# Start frontend dev server
Write-Host "Starting Vue frontend..." -ForegroundColor Yellow
$frontendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    Set-Location backend/frontend
    npm run dev
}

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "Development servers starting..." -ForegroundColor Cyan
Write-Host "Backend:  http://localhost:8080" -ForegroundColor White
Write-Host "Frontend: http://localhost:5173 (with hot reload)" -ForegroundColor White
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "`nPress Ctrl+C to stop all servers" -ForegroundColor Yellow

# Wait for Ctrl+C
try {
    while ($true) {
        Start-Sleep -Seconds 1
        
        # Check if jobs are still running
        $backendState = (Get-Job -Id $backendJob.Id).State
        $frontendState = (Get-Job -Id $frontendJob.Id).State
        
        if ($backendState -eq "Failed") {
            Write-Host "Backend crashed, restarting..." -ForegroundColor Red
            Receive-Job -Id $backendJob.Id
        }
    }
} finally {
    Write-Host "`nStopping servers..." -ForegroundColor Yellow
    Stop-Job -Id $backendJob.Id -ErrorAction SilentlyContinue
    Stop-Job -Id $frontendJob.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $backendJob.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $frontendJob.Id -ErrorAction SilentlyContinue
    Write-Host "Done" -ForegroundColor Green
}
