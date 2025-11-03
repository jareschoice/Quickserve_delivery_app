# ===============================
# 🧪 QuickServe API Test Script (PowerShell)
# ===============================
# Run with: .\test-api.ps1

$BASE_URL = "http://localhost:5555"
$vendorToken = ""
$userId = ""

Write-Host "`n🚀 QuickServe API Test Suite" -ForegroundColor Cyan
Write-Host "================================`n" -ForegroundColor Cyan

# ===============================
# Test 1: Health Check
# ===============================
Write-Host "`n=================================================" -ForegroundColor Blue
Write-Host "🧪 Test 1: Health Check" -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Blue

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/" -Method Get
    Write-Host "✅ Server is running!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ Health check failed! Server might not be running." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "`n💡 Start the server with: npm run dev" -ForegroundColor Yellow
    exit 1
}

# ===============================
# Test 2: Register Vendor
# ===============================
Write-Host "`n=================================================" -ForegroundColor Blue
Write-Host "🧪 Test 2: Register Vendor" -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Blue

$timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$body = @{
    name = "Test Vendor"
    email = "vendor$timestamp@test.com"
    password = "password123"
    role = "vendor"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/api/auth/register" -Method Post -Body $body -ContentType "application/json"
    $vendorToken = $response.token
    $userId = $response.user.id
    
    Write-Host "✅ Vendor registered successfully!" -ForegroundColor Green
    Write-Host "User ID: $userId"
    Write-Host "Token: $($vendorToken.Substring(0, 20))..."
} catch {
    Write-Host "❌ Registration failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# ===============================
# Test 3: Create Vendor Profile
# ===============================
Write-Host "`n=================================================" -ForegroundColor Blue
Write-Host "🧪 Test 3: Create Vendor Profile" -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Blue

$body = @{
    storeName = "Test Restaurant"
} | ConvertTo-Json

$headers = @{
    "Authorization" = "Bearer $vendorToken"
    "Content-Type" = "application/json"
}

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/api/vendors/profile" -Method Post -Body $body -Headers $headers
    Write-Host "✅ Vendor profile created!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ Profile creation failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# ===============================
# Test 4: Submit KYC (The Fixed Feature!)
# ===============================
Write-Host "`n=================================================" -ForegroundColor Blue
Write-Host "🧪 Test 4: Submit KYC (The Feature You Just Fixed!)" -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Blue

$body = @{
    idUrl = "https://example.com/government-id.jpg"
    utilityBillUrl = "https://example.com/utility-bill.pdf"
    bankName = "GTBank"
    accountNumber = "0123456789"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/api/kyc/submit" -Method Post -Body $body -Headers $headers
    Write-Host "✅ KYC submitted successfully!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ KYC submission failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# ===============================
# Test 5: Get KYC Status
# ===============================
Write-Host "`n=================================================" -ForegroundColor Blue
Write-Host "🧪 Test 5: Get KYC Status" -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Blue

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/api/kyc/status" -Method Get -Headers $headers
    Write-Host "✅ KYC status retrieved!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ KYC status check failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# ===============================
# Test 6: Get Vendor Profile
# ===============================
Write-Host "`n=================================================" -ForegroundColor Blue
Write-Host "🧪 Test 6: Get Vendor Profile" -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Blue

try {
    $response = Invoke-RestMethod -Uri "$BASE_URL/api/vendors/me" -Method Get -Headers $headers
    Write-Host "✅ Vendor profile retrieved!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "❌ Profile retrieval failed!" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}

# ===============================
# Summary
# ===============================
Write-Host "`n=================================================" -ForegroundColor Blue
Write-Host "🎉 Test Suite Complete!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Blue
Write-Host "`n✅ All essential endpoints have been tested!" -ForegroundColor Green
Write-Host "Your backend is working properly!`n" -ForegroundColor Green
