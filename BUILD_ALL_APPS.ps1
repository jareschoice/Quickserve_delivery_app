# QuickServe Apps Builder
# Builds all 3 apps with proper branding

Write-Host "🚀 QuickServe Multi-App Builder" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

$frontendPath = "C:\Users\HP-PC\Desktop\quickserve\frontend"
Set-Location $frontendPath

# Clean build
Write-Host "🧹 Cleaning previous builds..." -ForegroundColor Yellow
flutter clean
Write-Host "✅ Clean complete!" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
flutter pub get
Write-Host "✅ Dependencies ready!" -ForegroundColor Green
Write-Host ""

# Build Consumer App
Write-Host "📱 Building CONSUMER APP (QuickServe)..." -ForegroundColor Cyan
Write-Host "   Icon: Q | Color: Orange and Gold" -ForegroundColor Gray
flutter build apk --release --target=lib/consumer_main.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Consumer App built successfully!" -ForegroundColor Green
    # Rename the APK
    Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\QuickServe-Consumer.apk" -Force
    Write-Host "   📦 Saved as: QuickServe-Consumer.apk" -ForegroundColor Green
} else {
    Write-Host "❌ Consumer App build failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build Vendor App
Write-Host "🏪 Building VENDOR APP (QuickServe Vendor)..." -ForegroundColor Cyan
Write-Host "   Icon: QV | Color: Orange and Gold" -ForegroundColor Gray
flutter build apk --release --target=lib/vendor_main.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Vendor App built successfully!" -ForegroundColor Green
    # Rename the APK
    Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\QuickServe-Vendor.apk" -Force
    Write-Host "   📦 Saved as: QuickServe-Vendor.apk" -ForegroundColor Green
} else {
    Write-Host "❌ Vendor App build failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Build Rider App
Write-Host "🚴 Building RIDER APP (QuickServe Rider)..." -ForegroundColor Cyan
Write-Host "   Icon: QR | Color: Orange and Gold" -ForegroundColor Gray
flutter build apk --release --target=lib/rider_main.dart
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Rider App built successfully!" -ForegroundColor Green
    # Rename the APK
    Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "build\app\outputs\flutter-apk\QuickServe-Rider.apk" -Force
    Write-Host "   📦 Saved as: QuickServe-Rider.apk" -ForegroundColor Green
} else {
    Write-Host "❌ Rider App build failed!" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "================================" -ForegroundColor Green
Write-Host "🎉 ALL 3 APPS BUILT SUCCESSFULLY!" -ForegroundColor Green
Write-Host ""
Write-Host "📂 APK Files Location:" -ForegroundColor Yellow
Write-Host "   $frontendPath\build\app\outputs\flutter-apk\" -ForegroundColor Gray
Write-Host ""
Write-Host "📱 Apps Ready:" -ForegroundColor Yellow
Write-Host "   ✅ QuickServe-Consumer.apk" -ForegroundColor Green
Write-Host "   ✅ QuickServe-Vendor.apk" -ForegroundColor Green
Write-Host "   ✅ QuickServe-Rider.apk" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Copy these APK files to your phone" -ForegroundColor White
Write-Host "   2. Install all 3 apps" -ForegroundColor White
Write-Host "   3. Test the complete flow!" -ForegroundColor White
Write-Host ""

# Open the folder
Write-Host "📂 Opening APK folder..." -ForegroundColor Yellow
Start-Process explorer.exe -ArgumentList "$frontendPath\build\app\outputs\flutter-apk\"
