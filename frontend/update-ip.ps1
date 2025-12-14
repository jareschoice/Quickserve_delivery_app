# Script to automatically detect local IP and update configuration files
# This ensures the app works even when Wi-Fi network changes

Write-Host " Detecting Local IP Address..." -ForegroundColor Cyan

# Get IPv4 address (excluding localhost)
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress

if (-not $ip) {
    Write-Host " Could not detect local IP address. Defaulting to localhost." -ForegroundColor Red
    $ip = "127.0.0.1"
}

Write-Host " Detected IP: $ip" -ForegroundColor Green

# Define files to update
$configFile = "frontend/lib/config/config.dart"
$socketFile = "event-frontend/js/socket-client.js"

# Update Flutter Config
if (Test-Path $configFile) {
    Write-Host " Updating $configFile..." -ForegroundColor Yellow
    $content = Get-Content $configFile -Raw
    # Regex to replace the URL line
    $newContent = $content -replace "static const String localUrl = 'http://.*:5555';", "static const String localUrl = 'http://$($ip):5555';"
    Set-Content -Path $configFile -Value $newContent
} else {
    Write-Host "  Warning: $configFile not found." -ForegroundColor Red
}

# Update Event Frontend Socket Client
if (Test-Path $socketFile) {
    Write-Host " Updating $socketFile..." -ForegroundColor Yellow
    $content = Get-Content $socketFile -Raw
    # Regex to replace the fallback URL
    $newContent = $content -replace "window.location.origin : 'http://.*:5555';", "window.location.origin : 'http://$($ip):5555';"
    Set-Content -Path $socketFile -Value $newContent
} else {
    Write-Host "  Warning: $socketFile not found." -ForegroundColor Red
}

Write-Host " Configuration updated to use IP: $ip" -ForegroundColor Green
