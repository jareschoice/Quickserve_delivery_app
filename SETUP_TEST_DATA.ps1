# QuickServe Complete Setup Script
# This creates 20 vendors, 10 dispatchers, and seeds 20 products per vendor

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         QuickServe Complete Database Setup                    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Navigate to backend directory
Set-Location "c:\Users\HP-PC\Desktop\quickserve\backend"

# Step 1: Create vendors and dispatchers
Write-Host "🏪 Step 1: Creating 20 vendors and 10 dispatchers..." -ForegroundColor Yellow
Write-Host ""
node seed-vendors-and-dispatchers.js

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create vendors and dispatchers!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Vendors and dispatchers created successfully!" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 2

# Step 2: Seed products
Write-Host "📦 Step 2: Seeding 20 products for each vendor..." -ForegroundColor Yellow
Write-Host ""
node seed-products-bulk.js

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to seed products!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Products seeded successfully!" -ForegroundColor Green
Write-Host ""

# Step 3: Display summary
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  ✅ SETUP COMPLETE!                            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   ✅ 20 vendors created (5 restaurants, 5 pharmacies, 5 shops, 5 supermarkets)"
Write-Host "   ✅ 10 dispatchers created"
Write-Host "   ✅ 400 products created (20 per vendor)"
Write-Host "   ✅ All accounts verified and active"
Write-Host "   ✅ Auto-incrementing IDs assigned (VEN-0001 to VEN-0020, DIS-0001 to DIS-0010)"
Write-Host ""
Write-Host "📄 Credentials saved in: TEST_ACCOUNTS_CREDENTIALS.txt" -ForegroundColor Yellow
Write-Host ""
Write-Host "🌐 Test the setup:" -ForegroundColor Cyan
Write-Host "   1. Home page: http://192.168.88.104:5555/event-frontend/home.html"
Write-Host "   2. All 20 vendors should appear grouped by category"
Write-Host "   3. Click any vendor to see their 20 products"
Write-Host "   4. Login with credentials from TEST_ACCOUNTS_CREDENTIALS.txt"
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Open TEST_ACCOUNTS_CREDENTIALS.txt to see all login details"
Write-Host "   2. Test vendor login: http://192.168.88.104:5555/event-frontend/vendor-dashboard.html"
Write-Host "   3. Test dispatcher login: http://192.168.88.104:5555/event-frontend/dispatcher.html"
Write-Host "   4. Admin panel: http://localhost:3000"
Write-Host ""
Write-Host "Press any key to open the credentials file..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Open credentials file
Start-Process notepad "TEST_ACCOUNTS_CREDENTIALS.txt"

Write-Host ""
Write-Host "✨ All done! Happy testing! ✨" -ForegroundColor Green
Write-Host ""
