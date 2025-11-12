# ==============================================
# ⚡ QUICK SERVE FINAL FIX (Auto Audio + Env + Socket + Auto Restart)
# ==============================================

Write-Host "`n🚀 Running QuickServe Final Fix..." -ForegroundColor Cyan

$root = "C:\Users\HP-PC\Desktop\quickserve"
$backend = "$root\backend\server.js"
$frontend = "$root\event-frontend"
$envConfig = "$frontend\js\env-config.js"
$socketJs = "$frontend\js\socket.js"
$port = 5555

# 🔍 Auto-detect active local IP
try {
    $ip = (Get-NetIPAddress | Where-Object {
        $_.AddressFamily -eq "IPv4" -and
        $_.IPAddress -notmatch "127\." -and
        $_.PrefixOrigin -ne "WellKnown"
    }).IPAddress | Select-Object -First 1
    if (-not $ip) { throw "No IP found" }
    Write-Host "✅ Detected local IP: $ip" -ForegroundColor Green
} catch {
    $ip = "192.168.64.104"
    Write-Host "⚠ Could not detect IP, using fallback $ip" -ForegroundColor Yellow
}

# 1️⃣ AUDIO FIX IN SERVER.JS
Write-Host "`n🛠 Checking for audio fix in server.js..." -ForegroundColor Yellow
$content = Get-Content $backend -Raw
if ($content -notmatch "req.url.endsWith\('.mp3'\)") {
    $audioBlock = @"
app.use((req, res, next) => {
  if (req.url.endsWith('.mp3')) {
    res.setHeader('Accept-Ranges', 'bytes');
    res.setHeader('Cache-Control', 'public, max-age=31536000');
  }
  next();
});
"@
    $content = $content -replace '(?ms)(app\.use\(helmet\(.+?\)\);)', "`$1`n$audioBlock"
    Set-Content $backend $content -Encoding UTF8
    Write-Host "✅ Added missing audio 416 fix." -ForegroundColor Green
} else {
    Write-Host "ℹ Audio fix already present." -ForegroundColor Yellow
}

# 2️⃣ UPDATE env-config.js (safe export syntax)
Write-Host "`n🧩 Rebuilding env-config.js..." -ForegroundColor Yellow
@"
export const BACKEND_HTTP = 'http://${ip}:${port}';
export const API_BASE_URL = BACKEND_HTTP + '/api';
export const AUTH_API_URL = API_BASE_URL + '/auth';
export const SOCKET_URL = 'ws://${ip}:${port}';
const CONFIG = { BACKEND_HTTP, API_BASE_URL, AUTH_API_URL, SOCKET_URL };
export default CONFIG;
"@ | Set-Content $envConfig -Encoding UTF8
Write-Host "✅ env-config.js updated successfully." -ForegroundColor Green

# 3️⃣ UPDATE socket.js
Write-Host "`n🔌 Updating socket.js for global socket usage..." -ForegroundColor Yellow
@"
window.socket = window.socket || io('http://${ip}:${port}');
export default window.socket;
"@ | Set-Content $socketJs -Encoding UTF8
Write-Host "✅ socket.js updated with global instance." -ForegroundColor Green

# 4️⃣ AUTO-RESTART BACKEND
Write-Host "`n♻ Restarting backend automatically..." -ForegroundColor Cyan
$backendPath = "$root\backend"
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 2
    Set-Location $using:backendPath
    Start-Process "node" -ArgumentList "server.js"
}
Write-Host "✅ Backend restarting on http://${ip}:${port} ..." -ForegroundColor Green

# 5️⃣ AUTO-OPEN HOMEPAGE
Start-Sleep -Seconds 4
$homeUrl = "http://${ip}:${port}/event-frontend/home.html"
Start-Process $homeUrl
Write-Host "🌍 Opening homepage: $homeUrl" -ForegroundColor Cyan

# 6️⃣ CACHE CLEAR NOTICE
Write-Host "`n⚙ Tip: Run this in browser console if you see old data:" -ForegroundColor Yellow
Write-Host "localStorage.clear(); sessionStorage.clear();" -ForegroundColor Gray
Write-Host "caches.keys().then(keys => keys.forEach(k => caches.delete(k)));" -ForegroundColor Gray

Write-Host "`n✨ All fixes applied successfully!" -ForegroundColor Green
Write-Host "-----------------------------------------------------------"