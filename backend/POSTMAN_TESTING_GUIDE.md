# 🧪 QuickServe API - Postman Testing Guide

## 🚀 Server Information
- **Base URL:** `http://localhost:5555`
- **API Version 2 Prefix:** `/api`
- **Status:** Running on port 5555

---

## 📋 **Testing the KYC Routes (FIXED)**

### ✅ **1. Register a Vendor Account**
**Endpoint:** `POST http://localhost:5555/api/auth/register`

**Headers:**
```
Content-Type: application/json
```

**Body (JSON):**
```json
{
  "name": "Test Vendor",
  "email": "vendor@test.com",
  "password": "password123",
  "role": "vendor"
}
```

**Expected Response:**
```json
{
  "user": {
    "id": "673...",
    "name": "Test Vendor",
    "email": "vendor@test.com",
    "role": "vendor"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**💡 Action:** Copy the `token` value - you'll need it for authenticated requests!

---

### ✅ **2. Submit KYC Information**
**Endpoint:** `POST http://localhost:5555/api/kyc/submit`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer YOUR_TOKEN_HERE
```

**Body (JSON):**
```json
{
  "idUrl": "https://example.com/id-card.jpg",
  "utilityBillUrl": "https://example.com/utility-bill.pdf",
  "bankName": "GTBank",
  "accountNumber": "0123456789"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "KYC submitted successfully",
  "kyc": {
    "_id": "673...",
    "user": "673...",
    "idUrl": "https://example.com/id-card.jpg",
    "utilityBillUrl": "https://example.com/utility-bill.pdf",
    "bankName": "GTBank",
    "accountNumber": "0123456789",
    "status": "pending",
    "createdAt": "2025-11-02T...",
    "updatedAt": "2025-11-02T..."
  }
}
```

---

### ✅ **3. Get KYC Status**
**Endpoint:** `GET http://localhost:5555/api/kyc/status`

**Headers:**
```
Authorization: Bearer YOUR_TOKEN_HERE
```

**Expected Response:**
```json
{
  "success": true,
  "kyc": {
    "_id": "673...",
    "user": "673...",
    "idUrl": "https://example.com/id-card.jpg",
    "utilityBillUrl": "https://example.com/utility-bill.pdf",
    "bankName": "GTBank",
    "accountNumber": "0123456789",
    "status": "pending",
    "createdAt": "2025-11-02T...",
    "updatedAt": "2025-11-02T..."
  }
}
```

---

### ✅ **4. Admin Verify Vendor KYC (Admin Only)**
**Endpoint:** `POST http://localhost:5555/api/kyc/verify`

**Headers:**
```
Content-Type: application/json
Authorization: Bearer ADMIN_TOKEN_HERE
```

**Body (JSON):**
```json
{
  "vendorId": "673...",
  "accountName": "Test Vendor",
  "accountNumber": "0123456789",
  "bankCode": "058",
  "bankName": "GTBank"
}
```

**Expected Response:**
```json
{
  "success": true,
  "message": "KYC verified and Paystack recipient created successfully",
  "vendor": {
    "_id": "673...",
    "storeName": "Test Store",
    "accountName": "Test Vendor",
    "accountNumber": "0123456789",
    "bankCode": "058",
    "bankName": "GTBank",
    "paystackRecipientCode": "RCP_...",
    "kycVerified": true,
    "kycStatus": "approved"
  }
}
```

---

## 📦 **Other Essential API Endpoints**

### 🔐 **Authentication Routes**

#### Login
**Endpoint:** `POST http://localhost:5555/api/auth/login`
```json
{
  "email": "vendor@test.com",
  "password": "password123"
}
```

#### Register Customer
**Endpoint:** `POST http://localhost:5555/api/auth/register/customer`
```json
{
  "name": "John Customer",
  "email": "customer@test.com",
  "password": "password123"
}
```

#### Register Rider
**Endpoint:** `POST http://localhost:5555/api/auth/register/rider`
```json
{
  "name": "Speedy Rider",
  "email": "rider@test.com",
  "password": "password123"
}
```

#### Dev Verify Email (Testing Only)
**Endpoint:** `POST http://localhost:5555/api/auth/dev-verify`
```json
{
  "email": "vendor@test.com"
}
```

---

### 🏪 **Vendor Routes**

#### Create Vendor Profile
**Endpoint:** `POST http://localhost:5555/api/vendors/profile`
**Headers:** `Authorization: Bearer VENDOR_TOKEN`
```json
{
  "storeName": "My Awesome Store"
}
```

#### Get My Vendor Profile
**Endpoint:** `GET http://localhost:5555/api/vendors/me`
**Headers:** `Authorization: Bearer VENDOR_TOKEN`

#### Get Vendor Wallet
**Endpoint:** `GET http://localhost:5555/api/vendors/wallet`
**Headers:** `Authorization: Bearer VENDOR_TOKEN`

---

### 📦 **Product Routes**

#### Create Product
**Endpoint:** `POST http://localhost:5555/api/products`
**Headers:** `Authorization: Bearer VENDOR_TOKEN`
```json
{
  "name": "Jollof Rice",
  "description": "Delicious Nigerian Jollof Rice",
  "price": 1500,
  "category": "food",
  "quantity": 50,
  "prepDurationMins": 30,
  "imageUrl": "https://example.com/jollof.jpg"
}
```

#### List All Products
**Endpoint:** `GET http://localhost:5555/api/products`

#### Get My Products (Vendor)
**Endpoint:** `GET http://localhost:5555/api/products/mine`
**Headers:** `Authorization: Bearer VENDOR_TOKEN`

---

### 📦 **Order Routes**

#### Create Order (Customer)
**Endpoint:** `POST http://localhost:5555/api/orders`
**Headers:** `Authorization: Bearer CUSTOMER_TOKEN`
```json
{
  "vendorId": "673...",
  "items": [
    {
      "productId": "673...",
      "quantity": 2,
      "price": 1500
    }
  ],
  "distanceKm": 5,
  "deliveryAddress": "123 Main Street, Lagos",
  "origin": { "lat": 6.5244, "lng": 3.3792 },
  "destination": { "lat": 6.4541, "lng": 3.3947 }
}
```

#### Get Vendor Orders
**Endpoint:** `GET http://localhost:5555/api/orders/vendor`
**Headers:** `Authorization: Bearer VENDOR_TOKEN`

#### Get Customer Orders
**Endpoint:** `GET http://localhost:5555/api/orders/customer`
**Headers:** `Authorization: Bearer CUSTOMER_TOKEN`

---

### 🚴 **Rider Routes**

#### Get Assigned Orders
**Endpoint:** `GET http://localhost:5555/api/riders/assigned`
**Headers:** `Authorization: Bearer RIDER_TOKEN`

---

### 👑 **Admin Routes**

#### Get Dashboard Stats
**Endpoint:** `GET http://localhost:5555/api/admin/stats`
**Headers:** `Authorization: Bearer ADMIN_TOKEN`

#### Get All Orders
**Endpoint:** `GET http://localhost:5555/api/admin/orders`
**Headers:** `Authorization: Bearer ADMIN_TOKEN`

#### Approve KYC
**Endpoint:** `POST http://localhost:5555/api/admin/kyc/:userId/approve`
**Headers:** `Authorization: Bearer ADMIN_TOKEN`

#### Reject KYC
**Endpoint:** `POST http://localhost:5555/api/admin/kyc/:userId/reject`
**Headers:** `Authorization: Bearer ADMIN_TOKEN`

---

### ✅ **Health Check**

#### Server Status
**Endpoint:** `GET http://localhost:5555/`

**Expected Response:**
```json
{
  "ok": true,
  "service": "QuickServe API",
  "mongo": "connected",
  "uptime": 123.456,
  "time": "2025-11-02T12:34:56.789Z"
}
```

---

## 🔧 **Postman Environment Variables**

Create a Postman Environment with these variables:

| Variable | Value |
|----------|-------|
| `base_url` | `http://localhost:5555` |
| `vendor_token` | `<paste token after vendor registration>` |
| `customer_token` | `<paste token after customer registration>` |
| `rider_token` | `<paste token after rider registration>` |
| `admin_token` | `<paste admin token>` |

Then use `{{base_url}}` and `{{vendor_token}}` in your requests!

---

## 🎯 **Quick Test Flow**

1. ✅ **Check Server:** `GET http://localhost:5555/`
2. ✅ **Register Vendor:** `POST /api/auth/register` (role: vendor)
3. ✅ **Copy Token** from response
4. ✅ **Submit KYC:** `POST /api/kyc/submit` with Bearer token
5. ✅ **Check KYC Status:** `GET /api/kyc/status` with Bearer token
6. ✅ **Create Vendor Profile:** `POST /api/vendors/profile`
7. ✅ **Add Product:** `POST /api/products`

---

## 🐛 **Common Issues & Solutions**

### ❌ "Authorization header missing or invalid"
- **Solution:** Add `Authorization: Bearer YOUR_TOKEN` to headers

### ❌ "Forbidden: insufficient permissions"
- **Solution:** Use correct role token (vendor token for vendor routes, etc.)

### ❌ "Invalid or expired token"
- **Solution:** Re-login and get a new token

### ❌ "User not found"
- **Solution:** Ensure you're using the correct userId or are logged in

---

## 📝 **Notes**

- All timestamps are in ISO 8601 format
- Passwords are hashed with bcryptjs
- JWT tokens expire in 7 days (configurable in .env)
- MongoDB connection is required for all operations
- Paystack integration requires valid API keys in .env

---

## 🎉 **Your KYC Issue is Fixed!**

The naming mismatch has been corrected:
- ✅ `submitKyc` (not `submitKYC`)
- ✅ `getKycStatus` (not `getKYCStatus`)
- ✅ `verifyVendorKYC` (correct)

Happy Testing! 🚀
