# ===============================================================
# QuickServe Frontend Path Auto-Fixer (HTML + JS)
# Safely updates URLs from HTTPS to HTTP and replaces old IPs.
# Works in all Windows PowerShell versions.
# ===============================================================

# --- Detect local IPv4 (192.* or 10.*) ---
$ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
       Where-Object { $.IPAddress -match '^(192|10)\.' -and $.PrefixOrigin -ne 'WellKnown' } |
       Select-Object -ExpandProperty IPAddress -First 1)

if (-not $ip) {
    Write-Host "Could not auto-detect local IP. Using fallback 192.168.232.104"
    $ip = "192.168.232.104"
}

$port = 5555
$frontendPath = "C:\Users\HP-PC\Desktop\quickserve\event-frontend"
$absBase = "http://{0}:{1}" -f $ip, $port

Write-Host ""
Write-Host ("Starting QuickServe frontend path fix for {0}:{1} ..." -f $ip, $port)

if (-not (Test-Path $frontendPath)) {
    Write-Host "Folder not found: $frontendPath"
    exit
}

function Fix-FileContent {
    param($filePath)

    $content = Get-Content -Raw -LiteralPath $filePath

    # --- Replace IPs and protocols ---
    $content = $content -replace "https://\d+\.\d+\.\d+\.\d+:5555", $absBase
    $content = $content -replace "http://\d+\.\d+\.\d+\.\d+:5555", $absBase
    $content = $content -replace "http://127\.0\.0\.1:5555", $absBase
    $content = $content -replace "http://localhost:5555", $absBase

    # --- Replace relative asset paths ---
    $content = $content -replace 'src="/event-frontend/', ('src="{0}/event-frontend/' -f $absBase)
    $content = $content -replace "src='/event-frontend/", ("src='{0}/event-frontend/" -f $absBase)
    $content = $content -replace 'href="/event-frontend/', ('href="{0}/event-frontend/' -f $absBase)
    $content = $content -replace "href='/event-frontend/", ("href='{0}/event-frontend/" -f $absBase)

    # --- Replace socket.io path ---
    $content = $content -replace 'src="/socket.io/socket.io.js"', ('src="{0}/socket.io/socket.io.js"' -f $absBase)
    $content = $content -replace "src='/socket.io/socket.io.js'", ("src='{0}/socket.io/socket.io.js'" -f $absBase)

    # --- Replace fetch paths ---
    $content = $content -replace "fetch\('/api/", ("fetch('{0}/api/" -f $absBase)
    $content = $content -replace 'fetch\("/api/', ('fetch("{0}/api/' -f $absBase)
    $content = $content -replace "fetch\('/event-frontend/", ("fetch('{0}/event-frontend/" -f $absBase)
    $content = $content -replace 'fetch\("/event-frontend/', ('fetch("{0}/event-frontend/' -f $absBase)

    # --- Save ---
    Set-Content -LiteralPath $filePath -Value $content -Encoding UTF8
    Write-Host ("Fixed: {0}" -f $filePath)
}

Get-ChildItem -Recurse -Include .html,.js,*.css -Path $frontendPath | ForEach-Object {
    Fix-FileContent $_.FullName
}

Write-Host ""
Write-Host "All frontend files updated successfully!"
Write-Host ("Open in browser: {0}/event-frontend/home.html" -f $absBase)
Write-Host "----------------------------------------------------------"