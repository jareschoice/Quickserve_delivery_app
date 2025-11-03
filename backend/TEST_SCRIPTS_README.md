# 🧪 QuickServe API Test Scripts

## Quick Test Scripts to Verify Your Backend

I've created two test scripts for you - choose the one you prefer!

---

## 🎯 **Option 1: Node.js Test Script (Recommended)**

### Run the test:
```bash
cd backend
node test-api.js
```

### What it tests:
1. ✅ Health Check - Server is running
2. ✅ Register Vendor - Creates a test user
3. ✅ Create Vendor Profile - Sets up vendor data
4. ✅ Submit KYC - Tests the feature you just fixed!
5. ✅ Get KYC Status - Retrieves KYC information
6. ✅ Get Vendor Profile - Confirms profile was created

### Expected Output:
```
🚀 QuickServe API Test Suite
================================

==================================================
🧪 Testing: Health Check
==================================================
✅ Server is running!
{
  "ok": true,
  "service": "QuickServe API",
  "mongo": "connected"
}

... (more tests)

📊 Test Summary
==================================================
✅ Passed: 6
Total: 6
==================================================

🎉 All tests passed! Your backend is working perfectly!
```

---

## 🎯 **Option 2: PowerShell Test Script**

### Run the test:
```powershell
cd backend
.\test-api.ps1
```

Same tests as above, but uses PowerShell natively!

---

## ⚠️ **Before Running Tests**

### 1. Make sure your server is running:
```bash
npm run dev
```

You should see:
```
🚀 QuickServe API running on http://0.0.0.0:5555
📱 Access from phone: http://192.168.100.104:5555
✅ MongoDB Atlas connected successfully!
```

### 2. Make sure axios is installed (for Node.js script):
```bash
npm install axios
```

---

## 🐛 **Troubleshooting**

### Error: "Cannot connect to server"
**Solution:** Start the server with `npm run dev`

### Error: "Email already in use"
**Solution:** The script creates unique emails each time, this shouldn't happen

### Error: "Invalid token"
**Solution:** The token is automatically generated during the test

### Error: "axios is not installed"
**Solution:** Run `npm install axios` in the backend folder

---

## 📝 **What Each Test Does**

### Test 1: Health Check
- **Endpoint:** `GET /`
- **Purpose:** Verify server is running and MongoDB is connected

### Test 2: Register Vendor
- **Endpoint:** `POST /api/auth/register`
- **Purpose:** Create a test vendor account
- **Gets:** Authentication token for subsequent requests

### Test 3: Create Vendor Profile
- **Endpoint:** `POST /api/vendors/profile`
- **Purpose:** Set up vendor business information
- **Uses:** Token from Test 2

### Test 4: Submit KYC
- **Endpoint:** `POST /api/kyc/submit`
- **Purpose:** Test the KYC feature you just fixed!
- **Submits:** ID, utility bill, bank info

### Test 5: Get KYC Status
- **Endpoint:** `GET /api/kyc/status`
- **Purpose:** Verify KYC data was stored correctly
- **Shows:** Status: "pending"

### Test 6: Get Vendor Profile
- **Endpoint:** `GET /api/vendors/me`
- **Purpose:** Confirm profile was created
- **Shows:** Store name and vendor details

---

## 🎉 **Success Indicators**

If all tests pass, you'll see:
- ✅ 6/6 tests passed
- 🎉 "All tests passed! Your backend is working perfectly!"

This means:
- ✅ Server is running correctly
- ✅ MongoDB connection works
- ✅ Authentication system works
- ✅ KYC routes are fixed and working
- ✅ Vendor endpoints are operational

---

## 🚀 **Next Steps After Tests Pass**

1. **Test with Postman** - Import `QuickServe_Postman_Collection.json`
2. **Connect Flutter Apps** - Update API base URLs in your apps
3. **Test Other Roles** - Register customer and rider accounts
4. **Add More Features** - Your backend foundation is solid!

---

## 💡 **Tips**

- Run tests after making changes to verify nothing broke
- Tests create new users each time (unique emails)
- Check the terminal where `npm run dev` is running to see server logs
- Use the Postman collection for manual testing

---

Happy Testing! 🎊
