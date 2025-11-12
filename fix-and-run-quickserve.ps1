# ===================================================
# QuickServe – Fix HTTPS Cache + Restart Backend
# ===================================================

Write-Host ""
Write-Host "Starting QuickServe cleanup and server launch..." -ForegroundColor Cyan

# -------------------------------
# Kill Chrome (to clear locks)
# -------------------------------
Write-Host ""
Write-Host "Closing Chrome processes..." -ForegroundColor Yellow
try {
    Get-Process "chrome" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    Write-Host "Chrome closed successfully." -ForegroundColor Green
}
catch {
    Write-Host "Chrome was not running." -ForegroundColor Yellow
}

# -------------------------------
# Clear Chrome HTTPS (HSTS) cache
# -------------------------------
$chromeHsts = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\TransportSecurity"
if (Test-Path $chromeHsts) {
    try {
        Remove-Item -Path $chromeHsts -Force
        Write-Host "Cleared Chrome HSTS cache successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Could not delete Chrome HSTS file (try manually): $chromeHsts" -ForegroundColor Yellow
    }
}
else {
    Write-Host "No existing Chrome HSTS cache found." -ForegroundColor Cyan
}

# -------------------------------
# Restart backend server
# -------------------------------
$backendPath = "C:\Users\HP-PC\Desktop\quickserve\backend"
$ip = "192.168.75.104"
$port = 5555

Write-Host ""
Write-Host "Restarting QuickServe backend..." -ForegroundColor Yellow
if (Test-Path $backendPath) {
    Set-Location $backendPath
    Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "npm start"
    Start-Sleep -Seconds 4
    Write-Host "Backend is starting up..." -ForegroundColor Green
}
else {
    Write-Host "Backend folder not found at $backendPath" -ForegroundColor Red
}

# -------------------------------
# Open index.html via HTTP
# -------------------------------
$url = "http://${ip}:${port}/event-frontend/index.html"
Write-Host ""
Write-Host "Opening QuickServe splash screen at:" -ForegroundColor Cyan
Write-Host $url -ForegroundColor Yellow

if (Get-Command "chrome.exe" -ErrorAction SilentlyContinue) {
    Start-Process "chrome.exe" $url
}
elseif (Get-Command "msedge.exe" -ErrorAction SilentlyContinue) {
    Start-Process "msedge.exe" $url
}
else {
    Write-Host "No supported browser found. Please open manually: $url" -ForegroundColor Red
}

Write-Host ""
Write-Host "All done! QuickServe should now redirect to home.html after 3 seconds." -ForegroundColor Green
