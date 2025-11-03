# 🧪 Manual Testing Guide - Secure Payment Flow

## Prerequisites
- Backend server running on http://localhost:5555
- MongoDB Atlas connected
- Paystack test keys configured in `.env`

## Step-by-Step Test Instructions

### Step 1: Start the Server
Open a terminal and run:
```powershell
cd C:\Users\HP-PC\Desktop\quickserve\backend
node server.js
```

Leave this terminal open. The server should show:
```
✅ MongoDB Atlas connected successfully!
🚀 QuickServe API running on http://0.0.0.0:5555
```

### Step 2: Test in a NEW Terminal

Open a **NEW PowerShell terminal** (don't close the server!) and run:

```powershell
cd C:\Users\HP-PC\Desktop\quickserve\backend
node test-payment-flow.js
```

### Expected Output

```
🧪 Testing Secure Payment-First Order Flow
============================================================

1️⃣ Register & Login Customer
------------------------------------------------------------
✅ Customer registered and logged in
   Email: customer_1234567890@test.com

2️⃣ Get Available Vendor
------------------------------------------------------------
✅ Test vendor created
   Vendor ID: 60d5f484f1b2c8a7e8c9d1e2

3️⃣ Attempt Direct Order Creation (Security Test)
------------------------------------------------------------
✅ Direct order creation blocked (correct behavior)
   Error message: "Direct order creation blocked"
   Correct endpoint: /api/payments/init-order-payment

4️⃣ Initialize Order Payment (Payment-First Flow)
------------------------------------------------------------
✅ Order payment initialized
   Payment Reference: T_abc123xyz789
   Pending Order ID: 60d5f484f1b2c8a7e8c9d1e5
   Total Amount: ₦3850
   Authorization URL: https://checkout.paystack.com/...

🌐 In production, customer would be redirected to Paystack:
   https://checkout.paystack.com/...

💳 Customer pays using Paystack checkout page
📡 Paystack sends webhook to /api/payments/webhook
✨ Backend creates actual order after payment verification

✅ All tests completed successfully!
```

## Alternative: Test with cURL

If the test script doesn't work, test manually with cURL:

### 1. Register Customer
```powershell
$response = Invoke-WebRequest -Uri "http://localhost:5555/api/auth/register" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"name":"Test Customer","email":"customer@test.com","password":"Test123!","role":"customer","phone":"08012345678"}' `
  -UseBasicParsing

$data = $response.Content | ConvertFrom-Json
$token = $data.token
Write-Host "Token: $token"
```

### 2. Try Direct Order (Should Fail)
```powershell
Invoke-WebRequest -Uri "http://localhost:5555/api/orders" `
  -Method POST `
  -Headers @{"Authorization"="Bearer $token"} `
  -ContentType "application/json" `
  -Body '{"vendorId":"60d5f484f1b2c8a7e8c9d1e2","items":[]}' `
  -UseBasicParsing
```

Expected: **403 Forbidden** with message "Direct order creation blocked"

### 3. Initialize Payment (Should Work)
```powershell
Invoke-WebRequest -Uri "http://localhost:5555/api/payments/init-order-payment" `
  -Method POST `
  -Headers @{"Authorization"="Bearer $token"} `
  -ContentType "application/json" `
  -Body '{"vendorId":"VENDOR_ID_HERE","items":[{"name":"Food","price":1000,"qty":1}],"deliveryAddress":"Test Address","deliveryFee":500}' `
  -UseBasicParsing
```

Expected: **200 OK** with Paystack authorization_url

## Troubleshooting

### "Cannot connect to server"
- Make sure server is running in a separate terminal
- Check `http://localhost:5555/health` in your browser

### "404 Not Found" on /api/payments/init-order-payment
- Server needs to be restarted to load new routes
- Stop server (Ctrl+C) and start again

### "Vendor ID undefined"
- Create a vendor first or use an existing vendor ID from database

## Quick Verification

Just want to verify the security fix works? Run this single test:

```powershell
# This should return 403 Forbidden
Invoke-WebRequest -Uri "http://localhost:5555/api/orders" `
  -Method POST `
  -Headers @{"Authorization"="Bearer YOUR_TOKEN"} `
  -ContentType "application/json" `
  -Body '{}' `
  -UseBasicParsing
```

If you get **403 Forbidden**, the security fix is working! ✅
