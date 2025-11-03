# 📱 QuickServe - Complete Mobile Testing Guide

## 🎯 What We're Testing

You'll test the complete food delivery flow on your phone:
1. **Customer orders food** (Consumer App)
2. **Vendor receives & prepares order** (Vendor App)
3. **Rider delivers order** (Rider App)
4. **Admin monitors everything** (Admin Panel - web browser)

---

## 📦 Step 1: Get the APK Files

### Build All 3 Apps (Run on PC)

Open PowerShell in `C:\Users\HP-PC\Desktop\quickserve\frontend` and run:

```powershell
# Build Consumer App (Orange Q icon)
flutter build apk --release --target=lib/consumer_main.dart
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "QuickServe-Consumer.apk"

# Build Vendor App (Orange QV icon)
flutter build apk --release --target=lib/vendor_main.dart
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "QuickServe-Vendor.apk"

# Build Rider App (Orange QR icon)
flutter build apk --release --target=lib/rider_main.dart
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "QuickServe-Rider.apk"
```

**⏱️ Time:** ~25 minutes total (8-10 mins per app)

---

## 📲 Step 2: Install Apps on Phone

### Option A: USB Cable (Recommended)
1. Connect phone to PC via USB
2. Enable **USB Debugging** on phone:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable USB Debugging
3. Copy APK files to phone's Downloads folder
4. On phone, use File Manager to install each APK

### Option B: WiFi Transfer
1. Upload APKs to Google Drive or send via WhatsApp to yourself
2. Download on phone
3. Install each APK (may need to enable "Install from Unknown Sources")

### Option C: Direct Install via ADB
```powershell
# If Flutter is installed, adb is available
cd C:\Users\HP-PC\Desktop\quickserve\frontend

adb install QuickServe-Consumer.apk
adb install QuickServe-Vendor.apk
adb install QuickServe-Rider.apk
```

---

## 🌐 Step 3: Make Backend Accessible to Phone

Your phone needs to connect to the backend running on your PC.

### Get Your PC's IP Address
```powershell
ipconfig
```
Look for **IPv4 Address** under your WiFi/Ethernet adapter (e.g., `192.168.1.100`)

### Start Backend Server
```powershell
cd C:\Users\HP-PC\Desktop\quickserve\backend
node server.js
```

✅ **Backend should show:** `Server running on http://192.168.100.104:5555`

### ⚠️ Important: Same WiFi Network
- Your PC and phone MUST be on the same WiFi network
- Turn off mobile data on phone
- Connect phone to same WiFi as PC

---

## 🧪 Step 4: Complete Test Scenario

### 🛒 PART 1: Customer Orders Food

**Use: QuickServe Consumer App**

1. **Open Consumer App** (Orange Q icon)
2. **Register as Customer**
   - Name: "Test Customer"
   - Email: "customer@test.com"
   - Password: "Test123!"
3. **Browse Restaurants**
   - Should see "QuickServe Test Restaurant"
4. **View Menu**
   - Should see 5 products:
     - Jollof Rice - ₦2,500
     - Fried Rice - ₦2,800
     - Amala & Ewedu - ₦2,000
     - Suya - ₦1,500
     - Pounded Yam - ₦2,200
5. **Add to Cart**
   - Add Jollof Rice (quantity: 2)
   - Add Suya (quantity: 1)
   - **Cart Total:** ₦6,500
6. **Checkout**
   - Enter delivery address
   - Enter phone number
7. **Make Payment**
   - Opens Paystack payment page
   - Use test card:
     - Card: `4084084084084081`
     - Expiry: `12/30`
     - CVV: `408`
     - PIN: `0000`
     - OTP: `123456`
8. **Payment Success**
   - Should see "Order Placed Successfully"
   - Order ID displayed
   - Status: "Pending"

---

### 🏪 PART 2: Vendor Manages Order

**Use: QuickServe Vendor App**

1. **Open Vendor App** (Orange QV icon)
2. **Login as Vendor**
   - Email: `padionton@meruado.uk`
   - Password: (your password)
3. **View Orders**
   - Should see new order from Test Customer
   - Status: "Pending"
   - Items: Jollof Rice x2, Suya x1
   - Total: ₦6,500
4. **Accept Order**
   - Tap "Accept Order"
   - Status changes to "Accepted"
5. **Prepare Food**
   - (Wait 2-3 minutes to simulate cooking)
6. **Mark as Ready**
   - Tap "Order Ready for Pickup"
   - Status changes to "Ready"
7. **Assign Rider** (if available)
   - Select rider from list
   - OR scan rider's QR code

---

### 🏍️ PART 3: Rider Delivers Order

**Use: QuickServe Rider App**

1. **Open Rider App** (Orange QR icon)
2. **Register as Rider**
   - Name: "Test Rider"
   - Email: "rider@test.com"
   - Password: "Test123!"
3. **View Available Orders**
   - Should see order assigned to you
   - Customer: Test Customer
   - Restaurant: QuickServe Test Restaurant
   - Delivery Address: (customer's address)
4. **Accept Delivery**
   - Tap "Accept Delivery"
   - View route to restaurant
5. **Pickup Order**
   - Arrive at restaurant (in real scenario)
   - Scan vendor's QR code OR enter pickup code
   - Status changes to "In Transit"
6. **Navigate to Customer**
   - View delivery address
   - (In real test, you'd actually move around)
7. **Complete Delivery**
   - Tap "Mark as Delivered"
   - Customer gets notification

---

### 👤 PART 4: Customer Confirms Delivery

**Back to Consumer App**

1. **Notification Received**
   - "Your order has been delivered"
2. **Confirm Receipt**
   - Tap "Confirm Delivery"
   - Rate the experience (1-5 stars)
   - Leave review (optional)
3. **Payment Released**
   - Vendor receives payment in wallet
   - Rider receives delivery fee
   - Platform takes commission

---

## 💻 PART 5: Admin Monitors Everything

**Use: Web Browser on PC or Phone**

1. **Open Browser**
   - PC: `http://localhost:3000`
   - Phone: `http://192.168.100.104:3000`
2. **Login as Admin**
   - Email: `admin@quickserve.com`
   - Password: `Admin123!`
3. **View Dashboard**
   - Total Users: Should increase
   - Total Orders: Should show new order
   - Total Revenue: Should show ₦6,500
   - Platform Earnings: ₦50 (commission)
4. **Check Order Details**
   - Navigate to "Orders" page
   - See complete order flow
   - Customer → Vendor → Rider → Delivered
5. **View Transactions**
   - Navigate to "Payments" page
   - See Paystack payment record
   - Payment status: "Success"

---

## 🎨 Visual Checks

### All 3 Apps Should Have:
- ✅ Orange (#FF8C00) primary color
- ✅ Gold (#FFD700) accent text
- ✅ Orange splash screen with gold "Q" / "QV" / "QR"
- ✅ Smooth animations
- ✅ Material Design 3 styling

---

## 🐛 Troubleshooting

### Problem 1: "Cannot connect to server"
**Solution:**
- Check PC and phone on same WiFi
- Verify backend is running (`node server.js`)
- Ping PC from phone: `http://192.168.100.104:5555/health`

### Problem 2: "Email not verified"
**Solution:**
Run on PC:
```powershell
cd C:\Users\HP-PC\Desktop\quickserve\backend
node -e "require('./manual-verify.js')"
```
Or use Postman: `POST /api/auth/dev-verify` with email

### Problem 3: No restaurants showing
**Solution:**
- Vendor must complete KYC first
- Check vendor account in admin panel
- Ensure products are uploaded

### Problem 4: Payment fails
**Solution:**
- Use Paystack test card: `4084084084084081`
- Check Paystack dashboard for errors
- Verify test keys in backend `.env` file

### Problem 5: QR code scanner not working
**Solution:**
- We removed the scanner package due to build issue
- Use manual code entry instead
- Alternative: Generate QR with `qr_flutter` (still works)

---

## 📊 Success Criteria

After complete test, you should have:

✅ **Consumer App:**
- User registered and verified
- Products browsed
- Order placed with payment
- Delivery confirmed

✅ **Vendor App:**
- Business profile created
- Products visible
- Order received and accepted
- Order marked ready

✅ **Rider App:**
- Rider registered
- Delivery accepted
- Pickup confirmed
- Delivery completed

✅ **Admin Panel:**
- All transactions visible
- Order flow tracked
- Platform earnings calculated (₦50)
- User accounts visible

✅ **Backend:**
- All API calls logged
- Payment verified via Paystack
- Order status updated correctly
- Wallet balances updated

---

## 🎯 Advanced Tests (Optional)

### Test 1: Multiple Orders
- Place 3 orders from different customers
- Assign to different riders
- Track all simultaneously

### Test 2: Order Rejection
- Vendor rejects an order
- Customer gets refund
- Payment reversed

### Test 3: Rider Unavailable
- No riders online
- Order stays "Ready" status
- Vendor can manually assign later

### Test 4: Wallet Withdrawal
- Vendor requests withdrawal
- Admin approves in panel
- Transaction recorded

---

## 📸 Screenshots to Take

Document your testing with screenshots:

1. **Consumer App:**
   - Splash screen
   - Restaurant list
   - Product menu
   - Cart with items
   - Payment screen
   - Order confirmation

2. **Vendor App:**
   - Dashboard
   - Incoming order
   - Order details
   - Products list

3. **Rider App:**
   - Available deliveries
   - Delivery details
   - Navigation view

4. **Admin Panel:**
   - Dashboard with stats
   - Orders list
   - Users list
   - Platform earnings

---

## 🕐 Estimated Testing Time

| Task | Time |
|------|------|
| Build APKs | 25 mins |
| Install apps | 5 mins |
| Complete test scenario | 15 mins |
| Admin verification | 5 mins |
| **TOTAL** | **~50 minutes** |

---

## ✅ Final Checklist

Before you start:
- [ ] Backend server running
- [ ] Admin panel running (optional)
- [ ] Phone and PC on same WiFi
- [ ] USB debugging enabled (if using cable)
- [ ] Old QuickServe apps uninstalled from phone

During testing:
- [ ] All 3 apps installed
- [ ] Customer can register and login
- [ ] Products are visible
- [ ] Payment completes successfully
- [ ] Vendor receives order
- [ ] Rider can accept delivery
- [ ] Order status updates work
- [ ] Admin panel shows all data

After testing:
- [ ] Take screenshots of success
- [ ] Note any bugs or issues
- [ ] Check backend logs for errors
- [ ] Verify wallet balances updated

---

## 🎉 You're Ready!

Start with building the APKs. I'll monitor the builds and help you through each step.

**Let's begin! 🚀**
