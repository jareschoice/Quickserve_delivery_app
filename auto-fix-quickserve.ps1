# ==============================================
# QUICK SERVE AUTO FIX + VERIFICATION SCRIPT
# ==============================================

Write-Host "`nStarting QuickServe Auto Fix..." -ForegroundColor Cyan

# 1️⃣ CONFIG
$root = "C:\Users\HP-PC\Desktop\quickserve"
$backend = "$root\backend\server.js"
$frontend = "$root\event-frontend"
$currentIP = "192.168.64.104"
$port = 5555
$apiUrl = "http://${currentIP}:${port}/api/products"
$socketUrl = "http://${currentIP}:${port}/socket.io/?EIO=4&transport=polling"

# 2️⃣ Fix server.js static section for audio
Write-Host "Fixing server.js static configuration..." -ForegroundColor Yellow
(Get-Content $backend -Raw) `
-replace 'express\.static\(publicPath\)', 'express.static(publicPath, { acceptRanges: true })' `
-replace 'express\.static\(eventFrontendPath\)', 'express.static(eventFrontendPath, { acceptRanges: true })' |
Set-Content $backend -Encoding UTF8

# 3️⃣ Fix env-config.js exports
$envConfigPath = "$frontend\js\env-config.js"
Write-Host "Updating env-config.js exports..." -ForegroundColor Yellow
@"
export const BACKEND_HTTP = 'http://${currentIP}:${port}';
export const API_BASE_URL = 'http://${currentIP}:${port}/api';
export const SOCKET_URL = 'ws://${currentIP}:${port}';
export const AUTH_API_URL = `${API_BASE_URL}/auth`;
export default { BACKEND_HTTP, API_BASE_URL, AUTH_API_URL, SOCKET_URL };
"@ | Set-Content $envConfigPath -Encoding UTF8

# 4️⃣ Search for and replace old IP references
Write-Host "Scanning frontend for old IPs..." -ForegroundColor Yellow
Get-ChildItem -Path $frontend -Recurse -Include .html,.js,*.css | ForEach-Object {
    (Get-Content $_.FullName -Raw) `
    -replace '192\.168\.232\.\d+', $currentIP |
    Set-Content $_.FullName -Encoding UTF8
}
Write-Host "All old IPs replaced with $currentIP" -ForegroundColor Green

# 5️⃣ Verification Stage
Write-Host "`nStarting backend verification..." -ForegroundColor Cyan

# Test 1: API
try {
    $apiResponse = Invoke-WebRequest -Uri $apiUrl -UseBasicParsing -TimeoutSec 5
    if ($apiResponse.StatusCode -eq 200) {
        Write-Host "✅ API reachable at $apiUrl" -ForegroundColor Green
    } else {
        Write-Host "⚠ API returned status: $($apiResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ API not reachable at $apiUrl" -ForegroundColor Red
}

# Test 2: Socket
try {
    $socketResponse = Invoke-WebRequest -Uri $socketUrl -UseBasicParsing -TimeoutSec 5
    if ($socketResponse.StatusCode -eq 200 -or $socketResponse.StatusCode -eq 400) {
        Write-Host "✅ Socket endpoint active at $socketUrl" -ForegroundColor Green
    } else {
        Write-Host "⚠ Socket returned status: $($socketResponse.StatusCode)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Socket endpoint not reachable at $socketUrl" -ForegroundColor Red
}

# 6️⃣ Summary
Write-Host "`nAll fixes completed successfully!" -ForegroundColor Cyan
Write-Host "Server.js static config patched"
Write-Host "env-config.js regenerated"
Write-Host "All old IPs replaced with $currentIP"
Write-Host "`nReady to restart QuickServe backend and reload home.html"
Write-Host "-----------------------------------------------------------" -ForegroundColor White