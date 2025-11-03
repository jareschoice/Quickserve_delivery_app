# 🚀 QuickServe API - Postman Testing Guide

## Why Browser Doesn't Work

**Your endpoint `/api/vendors/register-business` requires:**
- ❌ POST request (browsers only do GET when you type URL)
- ❌ JSON body with data
- ❌ Authorization Bearer token in headers

**This is WHY you get "Not Found" in browser!** Browsers can only test GET requests.

---

## 📥 Import Collection to Postman

1. **Open Postman**
2. Click **Import** (top left)
3. Select the file: `QuickServe-API-Postman-Collection.json`
4. Collection will appear in your sidebar

---

## 🧪 Quick Testing Flow

### Step 1: Test Server is Running

**Endpoint:** `Health Check`  
**Method:** GET  
**URL:** `http://localhost:5555/health`  
**Expected Response:** `200 OK` with `{ "status": "ok", "timestamp": "..." }`

✅ **This one DOES work in browser!** Try it: http://localhost:5555/health

---

### Step 2: Login as Admin

**Endpoint:** `Login` (under 🔐 Authentication)  
**Method:** POST  
**Body:**
```json
{
  "email": "admin@quickserve.com",
  "password": "Admin123!"
}
```

**Expected Response:**
```json
{
  "user": {
    "id": "...",
    "name": "Admin",
    "email": "admin@quickserve.com",
    "role": "admin"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

✅ **The token is automatically saved!** The collection has a script that stores it.

---

### Step 3: Test Vendor Registration (The One You Tried!)

**Endpoint:** `Register Business Profile` (under 🏪 Vendor Operations)  
**Method:** POST  
**Headers:** `Authorization: Bearer {{token}}` (auto-added)  
**Body:**
```json
{
  "businessName": "QuickServe Test Restaurant",
  "businessAddress": "123 Main St, Lagos, Nigeria",
  "businessPhone": "08012345678",
  "businessCategory": "Fast Food"
}
```

⚠️ **Note:** You must login as a VENDOR first (not admin) for this to work!

---

## 📋 Common Test Scenarios

### Scenario A: Register New Vendor & Create Products

1. **Register Vendor** → `POST /api/auth/register/vendor`
2. **Verify Email** → `POST /api/auth/dev-verify` (development only)
3. **Login** → `POST /api/auth/login` (saves token)
4. **Register Business** → `POST /api/vendors/register-business`
5. **Create Product** → `POST /api/vendors/create-product` (with image upload)
6. **View Products** → `GET /api/vendors/products`

---

### Scenario B: Customer Places Order

1. **Register Customer** → `POST /api/auth/register/customer`
2. **Login** → `POST /api/auth/login`
3. **Browse Products** → (You'll need to browse vendor products via app)
4. **Initialize Payment** → `POST /api/payments/init-order-payment`
5. **Verify Payment** → `GET /api/payments/verify?reference=xxx`
6. **View My Orders** → `GET /api/orders/mine`

---

### Scenario C: Admin Dashboard

1. **Login as Admin** → `POST /api/auth/login` (admin@quickserve.com)
2. **Get Stats** → `GET /api/admin/stats`
3. **View All Users** → `GET /api/admin/users`
4. **View All Vendors** → `GET /api/admin/vendors`
5. **View All Orders** → `GET /api/admin/orders`

---

## 🔑 Available Test Accounts

| Email | Password | Role |
|-------|----------|------|
| admin@quickserve.com | Admin123! | Admin |
| padionton@meruado.uk | (your password) | Vendor |

---

## ⚠️ Common Issues

### Issue 1: "Authorization required"
**Solution:** Make sure you logged in first and the token is saved.

### Issue 2: "Invalid token"
**Solution:** Login again to get a fresh token (they expire after 7 days).

### Issue 3: "Email not verified"
**Solution:** Use the `Dev Verify Email` endpoint to manually verify.

### Issue 4: "Vendor profile not found"
**Solution:** You must register business profile first using `/vendors/register-business`.

---

## 🌐 URLs That Work in Browser

Only **GET requests without authentication** work in browser:

✅ `http://localhost:5555/health` - Server health check  
❌ `http://localhost:5555/api/vendors/register-business` - Needs POST + Auth  
❌ `http://localhost:5555/api/auth/login` - Needs POST + Body  

**For everything else, use Postman!**

---

## 📱 Testing Payment Flow

1. Initialize payment with `POST /api/payments/init-order-payment`
2. Response will contain `authorization_url` from Paystack
3. Open that URL in browser to complete test payment
4. Copy the `reference` from the callback URL
5. Verify payment with `GET /api/payments/verify?reference=xxx`

---

## 🛠️ Environment Variables

The collection uses these variables (set automatically):

- `{{base_url}}` = `http://localhost:5555/api`
- `{{token}}` = Auto-saved after login

You can change `base_url` if your server runs on a different port.

---

## 💡 Pro Tips

1. **Save frequently used requests** - Click ⭐ to add to favorites
2. **Use Console** - View > Show Postman Console to see request details
3. **Copy as cURL** - Right-click request → Copy → Copy as cURL
4. **Test scripts** - The Login request auto-saves your token!
5. **Environment switching** - Create different environments for dev/prod

---

## 📞 Need Help?

- Backend running? Check `http://localhost:5555/health`
- See server logs in the terminal where you ran `node server.js`
- Check MongoDB connection in backend console

---

**Happy Testing! 🎉**
