# QuickServe Event Edition - Quick Start Script
# This script will help you get the event system up and running quickly

Write-Host "🥇 QuickServe Event Edition - Quick Start" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Check if in correct directory
if (-not (Test-Path ".\backend") -or -not (Test-Path ".\event-frontend")) {
    Write-Host "❌ Error: Please run this script from the quickserve root directory" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Pre-flight Checklist:" -ForegroundColor Yellow
Write-Host ""

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Cyan
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js not found. Please install Node.js first." -ForegroundColor Red
    exit 1
}

# Check MongoDB connection
Write-Host ""
Write-Host "⚠️  Make sure you have:" -ForegroundColor Yellow
Write-Host "  1. MongoDB Atlas account set up" -ForegroundColor White
Write-Host "  2. .env file configured in backend folder" -ForegroundColor White
Write-Host "  3. Paystack account (test or live)" -ForegroundColor White
Write-Host ""

$continue = Read-Host "Have you set up the .env file? (y/n)"
if ($continue -ne "y") {
    Write-Host ""
    Write-Host "📝 Please create backend/.env with:" -ForegroundColor Yellow
    Write-Host "  PORT=5000" -ForegroundColor White
    Write-Host "  MONGODB_URI=your_mongodb_connection" -ForegroundColor White
    Write-Host "  JWT_SECRET=your_secret_key" -ForegroundColor White
    Write-Host "  PAYSTACK_SECRET_KEY=sk_test_xxx" -ForegroundColor White
    Write-Host "  PAYSTACK_PUBLIC_KEY=pk_test_xxx" -ForegroundColor White
    Write-Host ""
    exit 0
}

Write-Host ""
Write-Host "🚀 Starting setup process..." -ForegroundColor Green
Write-Host ""

# Install backend dependencies
Write-Host "📦 Installing backend dependencies..." -ForegroundColor Cyan
Set-Location backend
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install backend dependencies" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Backend dependencies installed" -ForegroundColor Green

# Create test data
Write-Host ""
$createData = Read-Host "Do you want to create test vendors and dispatchers? (y/n)"
if ($createData -eq "y") {
    Write-Host "📊 Creating test data..." -ForegroundColor Cyan
    node create-event-test-data.js
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Test data created successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📝 Test Credentials Created:" -ForegroundColor Yellow
        Write-Host "  Vendors: vendor1@event.test to vendor20@event.test" -ForegroundColor White
        Write-Host "  Dispatchers: dispatcher1@event.test to dispatcher10@event.test" -ForegroundColor White
        Write-Host "  Password: password123" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📖 Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start the backend:" -ForegroundColor White
Write-Host "   cd backend" -ForegroundColor Cyan
Write-Host "   npm run dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. In a new terminal, serve the frontend:" -ForegroundColor White
Write-Host "   cd event-frontend" -ForegroundColor Cyan
Write-Host "   npx http-server -p 8080" -ForegroundColor Cyan
Write-Host "   (or use VS Code Live Server)" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Open in browser:" -ForegroundColor White
Write-Host "   http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Test the system:" -ForegroundColor White
Write-Host "   - Browse vendors and products" -ForegroundColor Gray
Write-Host "   - Place a test order" -ForegroundColor Gray
Write-Host "   - Login as vendor at /login.html" -ForegroundColor Gray
Write-Host "   - Accept and update order status" -ForegroundColor Gray
Write-Host "   - Login as dispatcher" -ForegroundColor Gray
Write-Host "   - Claim and deliver order" -ForegroundColor Gray
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "  - Setup Guide: event-frontend/SETUP_GUIDE.md" -ForegroundColor White
Write-Host "  - API Docs: event-frontend/API_DOCUMENTATION.md" -ForegroundColor White
Write-Host "  - Summary: EVENT_IMPLEMENTATION_SUMMARY.md" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Ready to make history! Good luck with your event! 🥇" -ForegroundColor Green
Write-Host ""

# Ask if user wants to start the backend now
$startNow = Read-Host "Start the backend server now? (y/n)"
if ($startNow -eq "y") {
    Write-Host ""
    Write-Host "🚀 Starting backend server..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
    Write-Host ""
    npm run dev
}

Set-Location ..
