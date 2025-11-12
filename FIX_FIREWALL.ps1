# Fix QuickServe Firewall Rule
# Run this script as Administrator

Write-Host "🔥 Fixing QuickServe Firewall Rule..." -ForegroundColor Cyan

# Remove existing rule
Remove-NetFirewallRule -DisplayName "Quickserve Backend 5555" -ErrorAction SilentlyContinue

# Create new rule that works on all network profiles
New-NetFirewallRule `
    -DisplayName "Quickserve Backend 5555" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5555 `
    -Action Allow `
    -Profile Any `
    -Enabled True

Write-Host "✅ Firewall rule updated to work on all network profiles (Private, Public, Domain)" -ForegroundColor Green
Write-Host ""
Write-Host "Testing connection..." -ForegroundColor Cyan

# Test the connection
$response = curl.exe http://192.168.29.104:5555/health 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Server is now accessible on LAN: http://192.168.29.104:5555" -ForegroundColor Green
    Write-Host "Response: $response" -ForegroundColor White
} else {
    Write-Host "❌ Still cannot connect. Response: $response" -ForegroundColor Red
    Write-Host ""
    Write-Host "Additional steps to try:" -ForegroundColor Yellow
    Write-Host "1. Check which network profile is active: Get-NetConnectionProfile" -ForegroundColor White
    Write-Host "2. Temporarily disable Windows Firewall to test" -ForegroundColor White
    Write-Host "3. Check if antivirus is blocking the connection" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
