# QuickServe - Build All Apps Script
# Run this from the 'frontend' directory

Write-Host "🚀 QuickServe - Building All 3 Apps" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$frontendPath = "C:\Users\HP-PC\Desktop\quickserve\frontend"

# Change to frontend directory
Set-Location $frontendPath

Write-Host "📍 Current directory: $PWD" -ForegroundColor Yellow
Write-Host ""

# Clean previous builds
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter clean failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Clean completed" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pub get failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Build Consumer App
Write-Host "🛒 Building Consumer App (QuickServe)..." -ForegroundColor Cyan
Write-Host "   Icon: Orange Q" -ForegroundColor Gray
Write-Host "   Target: lib/consumer_main.dart" -ForegroundColor Gray
flutter build apk --release --target=lib/consumer_main.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Consumer app build failed!" -ForegroundColor Red
    exit 1
}
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "QuickServe-Consumer.apk" -Force
Write-Host "✅ Consumer App built: QuickServe-Consumer.apk" -ForegroundColor Green
Write-Host ""

# Build Vendor App
Write-Host "🏪 Building Vendor App (QuickServe Vendor)..." -ForegroundColor Cyan
Write-Host "   Icon: Orange QV" -ForegroundColor Gray
Write-Host "   Target: lib/vendor_main.dart" -ForegroundColor Gray
flutter build apk --release --target=lib/vendor_main.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Vendor app build failed!" -ForegroundColor Red
    exit 1
}
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "QuickServe-Vendor.apk" -Force
Write-Host "✅ Vendor App built: QuickServe-Vendor.apk" -ForegroundColor Green
Write-Host ""

# Build Rider App
Write-Host "🏍️ Building Rider App (QuickServe Rider)..." -ForegroundColor Cyan
Write-Host "   Icon: Orange QR" -ForegroundColor Gray
Write-Host "   Target: lib/rider_main.dart" -ForegroundColor Gray
flutter build apk --release --target=lib/rider_main.dart
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Rider app build failed!" -ForegroundColor Red
    exit 1
}
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "QuickServe-Rider.apk" -Force
Write-Host "✅ Rider App built: QuickServe-Rider.apk" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "🎉 All apps built successfully!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📱 APK Files Created:" -ForegroundColor Yellow
Write-Host "   1. QuickServe-Consumer.apk" -ForegroundColor White
Write-Host "   2. QuickServe-Vendor.apk" -ForegroundColor White
Write-Host "   3. QuickServe-Rider.apk" -ForegroundColor White
Write-Host ""
Write-Host "📍 Location: $frontendPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "📲 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Transfer APKs to your phone" -ForegroundColor White
Write-Host "   2. Install all 3 apps" -ForegroundColor White
Write-Host "   3. Follow MOBILE-TESTING-GUIDE.md" -ForegroundColor White
Write-Host ""

# Open folder
Write-Host "Opening folder..." -ForegroundColor Gray
Start-Process explorer.exe -ArgumentList $frontendPath
