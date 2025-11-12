# ===============================================
# QuickServe Reset and Restart Script (Plain ASCII)
# ===============================================

Write-Host ""
Write-Host "Starting QuickServe auto-reset and backend restart..."

# -------------------------------
# Detect or manually set IP + Port
# -------------------------------
$port = 5555
$ip = (Get-NetIPAddress -AddressFamily IPv4 |
       Where-Object { $_.IPAddress -like '192.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
       Select-Object -ExpandProperty IPAddress -First 1)

if (-not $ip) {
    Write-Host "Could not auto-detect local IP. Using fallback 192.168.75.104"
    $ip = "192.168.75.104"
}

Write-Host "Local IP detected: $ip"

# -------------------------------
# Kill any existing process on port 5555
# -------------------------------
Write-Host ""
Write-Host "Killing any process on port $port..."
try {
    npx kill-port $port | Out-Null
    Write-Host "Port $port is now free."
} catch {
    Write-Host "Port $port may already be free."
}

# -------------------------------
# Replace old IPs in frontend files
# -------------------------------
Write-Host ""
Write-Host "Updating IP references in event-frontend..."
$frontendPath = "C:\Users\HP-PC\Desktop\quickserve\event-frontend"

if (Test-Path $frontendPath) {
    Get-ChildItem -Recurse -Include .html,.js,*.css -Path $frontendPath | ForEach-Object {
        (Get-Content $_.FullName) `
            -replace 'https://192\.\d+\.\d+\.\d+:5555', ("http://{0}:{1}" -f $ip, $port) `
            -replace 'http://192\.\d+\.\d+\.\d+:5555', ("http://{0}:{1}" -f $ip, $port) `
            -replace 'http://127\.0\.0\.1:5555', ("http://{0}:{1}" -f $ip, $port) `
            | Set-Content $_.FullName
        Write-Host ("Updated: {0}" -f $_.FullName)
    }
} else {
    Write-Host "Frontend folder not found at $frontendPath"
}

# -------------------------------
# Restart Node backend server
# -------------------------------
Write-Host ""
Write-Host ("Restarting backend on http://{0}:{1} ..." -f $ip, $port)
$backendPath = "C:\Users\HP-PC\Desktop\quickserve\backend"
if (Test-Path $backendPath) {
    Set-Location $backendPath
    Start-Process "powershell" -ArgumentList "-NoExit", "-Command", "npm start"
    Write-Host "Backend restart triggered successfully."
} else {
    Write-Host "Backend folder not found at $backendPath"
}

# -------------------------------
# Optional: Clear browser cache and reopen homepage
# -------------------------------
Write-Host ""
Write-Host "Clearing browser cache and opening homepage..."
try {
    $url = ("http://{0}:{1}/event-frontend/home.html" -f $ip, $port)

    Get-Process "msedge","chrome" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

    $chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    if (Test-Path $chromeCache) {
        Remove-Item -Path $chromeCache -Recurse -Force -ErrorAction SilentlyContinue
    }

    if (Get-Command "chrome.exe" -ErrorAction SilentlyContinue) {
        Start-Process "chrome.exe" $url
    }
    elseif (Get-Command "msedge.exe" -ErrorAction SilentlyContinue) {
        Start-Process "msedge.exe" $url
    }
    else {
        Write-Host "No supported browser found. Please open manually: $url"
    }
} catch {
    Write-Host ("Could not clear cache or open browser: {0}" -f $_.Exception.Message)
}

# -------------------------------
# Final confirmation
# -------------------------------
Write-Host ""
Write-Host "---------------------------------------------"
Write-Host "All done! Your full QuickServe system is live at:"
Write-Host ("http://{0}:{1}" -f $ip, $port)
Write-Host "---------------------------------------------"
Write-Host ""