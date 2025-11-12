# ===============================================
# QuickServe IP Auto Updater (Stable Safe Version)
# ===============================================

# Step 1: Define IP, port, and frontend folder
$ip = "192.168.64.104"
$port = 5555
$frontendPath = "C:\Users\HP-PC\Desktop\quickserve\event-frontend"

Write-Host ""
Write-Host "Updating all QuickServe frontend files to use: http://${ip}:${port}" -ForegroundColor Cyan

# Step 2: Verify frontend folder exists
if (-Not (Test-Path $frontendPath)) {
    Write-Host "ERROR: Frontend folder not found at $frontendPath" -ForegroundColor Red
    exit
}

# Step 3: Replace old IP/localhost references
Get-ChildItem -Recurse -Include .html,.js,*.css -Path $frontendPath | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw

    $content = $content `
        -replace 'https://192\.\d+\.\d+\.\d+:5555', ("http://{0}:{1}" -f $ip, $port) `
        -replace 'http://192\.\d+\.\d+\.\d+:5555', ("http://{0}:{1}" -f $ip, $port) `
        -replace 'http://127\.0\.0\.1:5555', ("http://{0}:{1}" -f $ip, $port) `
        -replace 'http://localhost:5555', ("http://{0}:{1}" -f $ip, $port)

    Set-Content $file $content -Encoding UTF8
    Write-Host "Updated:" $file -ForegroundColor Green
}

# Step 4: Final message
Write-Host ""
Write-Host "All done! Frontend paths now point to: http://${ip}:${port}" -ForegroundColor Yellow
Write-Host "You can open your app here: http://${ip}:${port}/event-frontend/home.html" -ForegroundColor Cyan