# auto-sync-frontend.ps1
# Safe PowerShell script to normalize frontend JS files:
# - replace LAN IP references to current IP
# - remove duplicate socket imports/declarations
# - ensure single import socket from "/event-frontend/js/socket-client.js"
# - create .bak backups

# -------------- CONFIG ----------
$port = 5555

# try to auto-detect IPv4 LAN address (192.* or 10.*). Fallback below if not found.
$ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
      Where-Object { $.IPAddress -match '^(192|10)\.' -and $.PrefixOrigin -ne 'WellKnown' } |
      Select-Object -ExpandProperty IPAddress -First 1)

if (-not $ip) {
    Write-Host "⚠ Could not auto-detect local IP. Set manual fallback 192.168.64.104" -ForegroundColor Yellow
    $ip = "192.168.64.104"
}

Write-Host "`n🔧 QuickServe frontend sync starting for http://${ip}:${port}`n" -ForegroundColor Cyan

# -------------- PATHS ----------
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$frontendPath = Join-Path $scriptRoot "event-frontend"
# $jsDir = Join-Path $frontendPath "js"  # Removed unused variable

if (-not (Test-Path $frontendPath)) {
    Write-Host "❌ event-frontend folder not found at: $frontendPath" -ForegroundColor Red
    exit 1
}

# -------------- Helpers ----------
function Backup-File($path) {
    $bak = "$path.bak"
    if (-not (Test-Path $bak)) {
        Copy-Item -LiteralPath $path -Destination $bak -ErrorAction SilentlyContinue
    }
}

# -------------- Walk JS files ----------
Get-ChildItem -Path $frontendPath -Recurse -Include .js,.html,*.css -File | ForEach-Object {
    $path = $_.FullName
    try {
        $original = Get-Content -Raw -LiteralPath $path -ErrorAction Stop
    } catch {
        Write-Host "⚠ Could not read $path: $(${_.Exception.Message})" -ForegroundColor Yellow
        return
    }

    # create a backup (only first time)
    Backup-File $path

    $content = $original

    # 1) Replace https://<any-ip>:5555 and http://<any-ip>:5555 with http://$ip:5555
    $content = $content -replace 'https?://\d+\.\d+\.\d+\.\d+:5555', "http://$ip`:$port"

    # 2) Replace explicit localhost/127 references to http://$ip:5555
    $content = $content -replace 'http://127\.0\.0\.1:5555', "http://$ip`:$port"
    $content = $content -replace 'http://localhost:5555', "http://$ip`:$port"

    # 3) Remove lines that redeclare socket clients or directly import socket.io client script
    # We'll remove lines containing:
    #   import socket from '...socket-client.js'
    #   import io from 'socket.io-client'   (variations)
    #   <script src="/socket.io/socket.io.js"> (if inside HTML file)
    #   const socket = io(...);
    #   let socket = io(...);
    # Use line-based processing for reliability
    $lines = $content -split "(`r`n|`n|`r)" | ForEach-Object { $_ }  # preserves as array

    $filtered = @()
    foreach ($line in $lines) {
        if ($line -match '\/socket\.io\/socket\.io\.js' -or
            $line -match 'import\s+io\s+from' -or
            $line -match 'import\s+socket\s+from' -or
            $line -match 'const\s+socket\s*=' -or
            $line -match 'let\s+socket\s*=' -or
            $line -match 'var\s+socket\s*=' -or
            $line -match 'io\(') {
            # skip - we'll add a canonical import later
            continue
        } else {
            $filtered += $line
        }
    }

    # Rebuild content
    $newContent = ($filtered -join "`n").TrimStart()

    # 4) Prepend canonical socket-client import for JS & HTML module scripts
    # Only add if file looks like module JS or HTML referencing modules.
    $needsSocketImport = $false
    if ($path.ToLower().EndsWith(".js")) {
        $needsSocketImport = $true
    } elseif ($path.ToLower().EndsWith(".html")) {
        # if HTML contains <script type="module" ...> we may still want to ensure the module imports it.
        if ($newContent -match '<script[^>]type=["'']module["''][^>]>') { $needsSocketImport = $true }
    }

    if ($needsSocketImport) {
        $importLine = 'import socket from "/event-frontend/js/socket-client.js";'
        if ($newContent -notmatch [regex]::Escape($importLine)) {
            # Prepend import only for JS files or for HTML module scripts (we add at top of file for simplicity)
            $newContent = $importLine + "`n" + $newContent
        }
    }

    # 5) Save file only if changed
    if ($newContent -ne $original) {
        try {
            Set-Content -LiteralPath $path -Value $newContent -Encoding UTF8
            Write-Host "✅ Updated: $path" -ForegroundColor Green
        } catch {
            Write-Host "❌ Failed to write $path: $(${_.Exception.Message})" -ForegroundColor Red
        }
    } else {
        Write-Host "ℹ No changes needed: $path" -ForegroundColor DarkCyan
    }
}

Write-Host "`n✨ Frontend auto-sync completed for http://$($ip):$($port)" -ForegroundColor Cyan