# Delete all test vendors, dispatchers, and products
# WARNING: This will delete ALL vendors, dispatchers, and their products!

Write-Host "⚠️  WARNING: This will delete ALL vendors, dispatchers, and products!" -ForegroundColor Red
Write-Host ""
$confirmation = Read-Host "Type 'YES' to continue"

if ($confirmation -ne 'YES') {
    Write-Host "❌ Operation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🗑️  Cleaning up database..." -ForegroundColor Yellow
Write-Host ""

cd c:\Users\HP-PC\Desktop\quickserve\backend
node cleanup-test-data.js

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Cleanup failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Cleanup complete! Database is ready for fresh data." -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Now run: .\SETUP_TEST_DATA.ps1" -ForegroundColor Cyan
Write-Host ""
