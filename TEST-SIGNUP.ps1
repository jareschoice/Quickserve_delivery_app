# QuickServe Signup Test Helper
# This script helps you test the signup functionality

Write-Host "🚀 QuickServe Signup Test Helper" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if backend is running
Write-Host "Checking backend server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://127.0.0.1:5555/health" -Method GET -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Backend is running on http://127.0.0.1:5555" -ForegroundColor Green
        Write-Host ""
    }
} catch {
    Write-Host "❌ Backend is NOT running!" -ForegroundColor Red
    Write-Host "Please start it with: cd backend; node server.js" -ForegroundColor Yellow
    Write-Host ""
    exit
}

# Test the signup endpoint
Write-Host "Testing signup endpoint..." -ForegroundColor Yellow
try {
    $timestamp = [int][double]::Parse((Get-Date -UFormat %s))
    $testData = @{
        name = "Test User"
        email = "test$timestamp@example.com"
        password = "test123456"
        phone = "08012345678"
        seatNumber = "A-101"
        role = "customer"
    } | ConvertTo-Json

    $headers = @{
        "Content-Type" = "application/json"
    }

    $response = Invoke-WebRequest -Uri "http://127.0.0.1:5555/api/auth/register" -Method POST -Headers $headers -Body $testData -TimeoutSec 10
    
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Signup endpoint is working!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Response:" -ForegroundColor Cyan
        $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Write-Host
    }
} catch {
    Write-Host "❌ Signup test failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open test-signup.html in your browser to test the connection" -ForegroundColor White
Write-Host "2. Open event-frontend/signup.html to test the actual signup page" -ForegroundColor White
Write-Host "3. Make sure to access pages via http://127.0.0.1 (not file://)" -ForegroundColor White
Write-Host ""
Write-Host "Files to open:" -ForegroundColor Yellow
Write-Host "  - Test page: $PSScriptRoot\test-signup.html" -ForegroundColor White
Write-Host "  - Signup page: $PSScriptRoot\event-frontend\signup.html" -ForegroundColor White
Write-Host ""
Write-Host "To open signup page, run:" -ForegroundColor Cyan
Write-Host "  Start-Process 'http://127.0.0.1:5500/event-frontend/signup.html'" -ForegroundColor Gray
Write-Host "  (Requires a local web server like Live Server extension)" -ForegroundColor Gray
Write-Host ""
