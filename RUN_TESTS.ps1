# 🚀 QuickServe Event Edition - Quick Test Runner

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  QuickServe Event Edition Test Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if MongoDB is running
Write-Host "[1/5] Checking MongoDB connection..." -ForegroundColor Yellow
try {
    $mongoTest = & mongosh --eval "db.version()" --quiet 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MongoDB is running" -ForegroundColor Green
    } else {
        Write-Host "❌ MongoDB is not running. Please start MongoDB first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "⚠️  Cannot verify MongoDB. Continuing anyway..." -ForegroundColor Yellow
}

# Check if backend dependencies are installed
Write-Host ""
Write-Host "[2/5] Checking backend dependencies..." -ForegroundColor Yellow
if (Test-Path "backend\node_modules") {
    Write-Host "✅ Backend dependencies found" -ForegroundColor Green
} else {
    Write-Host "❌ Backend dependencies not found. Installing..." -ForegroundColor Red
    Set-Location backend
    npm install
    Set-Location ..
    Write-Host "✅ Backend dependencies installed" -ForegroundColor Green
}

# Generate test data
Write-Host ""
Write-Host "[3/5] Generating test data (20 vendors + 10 dispatchers)..." -ForegroundColor Yellow
Set-Location backend
$testDataOutput = & node create-event-test-data.js 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Test data generated successfully" -ForegroundColor Green
    Write-Host "   - 20 vendors created (mamput@test.com, burgerhub@test.com, etc.)" -ForegroundColor Gray
    Write-Host "   - 10 dispatchers created (dispatcher1-10@event.test)" -ForegroundColor Gray
    Write-Host "   - All passwords: password123" -ForegroundColor Gray
} else {
    Write-Host "⚠️  Test data generation had issues (may already exist)" -ForegroundColor Yellow
}
Set-Location ..

# Check if http-server is installed globally
Write-Host ""
Write-Host "[4/5] Checking frontend server..." -ForegroundColor Yellow
$httpServer = Get-Command http-server -ErrorAction SilentlyContinue
if (-not $httpServer) {
    Write-Host "⚠️  http-server not found. Installing globally..." -ForegroundColor Yellow
    npm install -g http-server
}
Write-Host "✅ Frontend server ready" -ForegroundColor Green

# Display startup instructions
Write-Host ""
Write-Host "[5/5] Starting servers..." -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SERVERS STARTING" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Start backend in new window
Write-Host "🚀 Starting Backend API on http://localhost:5000" -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\backend'; Write-Host 'Backend Server Starting...' -ForegroundColor Cyan; npm start"

Start-Sleep -Seconds 2

# Start frontend in new window
Write-Host "🌐 Starting Frontend on http://localhost:8080" -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD\event-frontend'; Write-Host 'Frontend Server Starting...' -ForegroundColor Cyan; npx http-server -p 8080"

Start-Sleep -Seconds 3

# Display test information
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  READY TO TEST! 🎉" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Frontend URLs:" -ForegroundColor White
Write-Host "   Home Page:         http://localhost:8080/index.html" -ForegroundColor Gray
Write-Host "   Vendor Dashboard:  http://localhost:8080/vendor-dashboard.html" -ForegroundColor Gray
Write-Host "   Dispatcher:        http://localhost:8080/dispatcher.html" -ForegroundColor Gray
Write-Host "   Admin Dashboard:   http://localhost:8080/admin.html" -ForegroundColor Gray
Write-Host "   Login:             http://localhost:8080/login.html" -ForegroundColor Gray
Write-Host ""
Write-Host "🔑 Test Credentials:" -ForegroundColor White
Write-Host "   Vendor 1:    mamput@test.com / password123" -ForegroundColor Gray
Write-Host "   Vendor 2:    burgerhub@test.com / password123" -ForegroundColor Gray
Write-Host "   Dispatcher:  dispatcher1@event.test / password123" -ForegroundColor Gray
Write-Host "   Admin:       admin@event.test / admin123" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 Testing Guide:  See EVENT_TESTING_GUIDE.md" -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Open browser to home page
Write-Host "🌐 Opening browser..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
Start-Process "http://localhost:8080/index.html"

Write-Host ""
Write-Host "✅ All systems running!" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  To stop servers: Close the PowerShell windows or press Ctrl+C" -ForegroundColor Yellow
Write-Host ""

# Keep this window open with helpful commands
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  HELPFUL COMMANDS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check active orders:" -ForegroundColor White
Write-Host '  mongosh quickserve --eval "db.eventorders.find({status: {' -NoNewline -ForegroundColor Gray
Write-Host '$ne' -NoNewline -ForegroundColor Yellow
Write-Host ': ' -NoNewline -ForegroundColor Gray
Write-Host "'delivered'" -NoNewline -ForegroundColor Yellow
Write-Host '}}).count()"' -ForegroundColor Gray
Write-Host ""
Write-Host "View all vendors:" -ForegroundColor White
Write-Host '  mongosh quickserve --eval "db.users.find({role: ' -NoNewline -ForegroundColor Gray
Write-Host "'vendor'" -NoNewline -ForegroundColor Yellow
Write-Host '}, {name: 1, email: 1})"' -ForegroundColor Gray
Write-Host ""
Write-Host "View all dispatchers:" -ForegroundColor White
Write-Host '  mongosh quickserve --eval "db.users.find({role: ' -NoNewline -ForegroundColor Gray
Write-Host "'dispatcher'" -NoNewline -ForegroundColor Yellow
Write-Host '}, {email: 1})"' -ForegroundColor Gray
Write-Host ""
Write-Host "Check ready orders:" -ForegroundColor White
Write-Host '  mongosh quickserve --eval "db.eventorders.find({status: ' -NoNewline -ForegroundColor Gray
Write-Host "'ready'" -NoNewline -ForegroundColor Yellow
Write-Host '})"' -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to continue or Ctrl+C to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
