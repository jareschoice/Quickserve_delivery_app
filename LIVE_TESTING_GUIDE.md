# 🧪 LIVE TESTING GUIDE - Multi-Vendor Order System

## 🎯 Test Scenario
**Customer orders from 3 vendors simultaneously to test complete multi-vendor flow**

---

## 👥 YOUR ROLES

### You will play:
1. **Vendor #1**: Mama's Kitchen (Email: `mamas.kitchen@quickserve.test`)
2. **Vendor #2**: Campus Bites (Email: `campus.bites@quickserve.test`)
3. **Vendor #3**: Quick Snacks Hub (Email: `quick.snacks@quickserve.test`)
4. **Dispatcher**: Chidi Okeke DSP-001 (Email: `dispatcher1@quickserve.test`)

### I will play:
- **Customer**: I'll place the multi-vendor order

---

## 📋 STEP-BY-STEP TEST FLOW

### STEP 1: Setup (You do this first)
Open 4 browser windows/tabs:

**Tab 1: Vendor Dashboard - Mama's Kitchen**
- URL: `http://localhost:5555/event-frontend/vendor-dashboard.html`
- Login: `mamas.kitchen@quickserve.test`
- Password: `password123`
- Keep this tab open and visible

**Tab 2: Vendor Dashboard - Campus Bites**
- URL: `http://localhost:5555/event-frontend/vendor-dashboard.html`
- Login: `campus.bites@quickserve.test`
- Password: `password123`
- Keep this tab open and visible

**Tab 3: Vendor Dashboard - Quick Snacks Hub**
- URL: `http://localhost:5555/event-frontend/vendor-dashboard.html`
- Login: `quick.snacks@quickserve.test`
- Password: `password123`
- Keep this tab open and visible

**Tab 4: Dispatcher Dashboard**
- URL: `http://localhost:5555/event-frontend/dispatcher.html`
- Login: `dispatcher1@quickserve.test`
- Password: `dispatcher123`
- Keep this tab open and visible

---

### STEP 2: Customer Orders (I do this)
I will:
1. Browse to `http://localhost:5555/event-frontend/home.html`
2. Add products from all 3 vendors:
   - **Mama's Kitchen**: Jollof Rice + Chicken (₦2,500)
   - **Campus Bites**: Shawarma + Pepsi (₦1,800)
   - **Quick Snacks Hub**: Meat Pie + Water (₦500)
3. Go to checkout
4. See multi-vendor confirmation dialog showing 3 vendors
5. Complete payment (demo mode)

**Expected Total**: ₦4,800 + ₦70 service = **₦4,870**

---

### STEP 3: Vendor #1 - Mama's Kitchen (You do this)

**What you should see:**
- 🔔 New order notification pops up
- Order card with 🛒 **"Multi-Vendor"** blue badge
- Panel showing: `🔗 Group Order: OG-[timestamp]`
- Status: `"⏳ 0/3 vendors ready"`

**Actions:**
1. Click **"Accept"** button
2. Click **"Start Preparing"** button  
3. **WAIT** - Don't mark ready yet!

**What happens:**
- Status changes to "Preparing"
- Group status still shows "0/3 ready" (because you haven't marked ready)

---

### STEP 4: Vendor #2 - Campus Bites (You do this)

**What you should see:**
- Order with same orderGroupId as Vendor #1
- Multi-vendor badge
- Status: "0/3 vendors ready"

**Actions:**
1. Click **"Accept"**
2. Click **"Start Preparing"**
3. Click **"Mark Ready"** ✅

**What happens:**
- Your order status → "Ready"
- **All vendors' dashboards update**: "1/3 vendors ready" 
- Customer gets notification: "Campus Bites ready! 1/3 vendors ready"
- Dispatcher dashboard: NO broadcast yet (waiting for all 3)

---

### STEP 5: Vendor #1 - Mama's Kitchen (You do this again)

**What you should see:**
- Status automatically updated to: "1/3 vendors ready" (Campus Bites is done)

**Actions:**
1. Click **"Mark Ready"** ✅

**What happens:**
- Your status → "Ready"
- **All dashboards update**: "2/3 vendors ready"
- Customer notification: "Mama's Kitchen ready! 2/3 vendors ready"
- Dispatcher: STILL NO broadcast (waiting for vendor #3)

---

### STEP 6: Vendor #3 - Quick Snacks Hub (You do this)

**What you should see:**
- Status showing: "2/3 vendors ready"

**Actions:**
1. Accept → Preparing → Click **"Mark Ready"** ✅

**What happens:**
- 🎉 **MAGIC MOMENT** - All 3 vendors ready!
- **All vendor dashboards**: "✅ All 3 vendors ready! Waiting for dispatcher..."
- **Customer notification**: "All vendors ready! Dispatcher incoming..."
- **🚨 DISPATCHER BROADCAST**: System emits to all 10 dispatchers!

---

### STEP 7: Dispatcher (You do this)

**What you should see on Dispatcher Dashboard:**
- 🔔 Notification: "New delivery available!"
- Order card showing:
  ```
  Multi-Vendor Delivery
  3 Pickups Required:
  
  📍 Pickup 1: Mama's Kitchen
     Items: Jollof Rice, Chicken
     
  📍 Pickup 2: Campus Bites
     Items: Shawarma, Pepsi
     
  📍 Pickup 3: Quick Snacks Hub
     Items: Meat Pie, Water
     
  🏠 Final Destination: Seat A12
  
  Earnings: ₦70
  ```

**Actions:**
1. Click **"Accept Delivery"**

**What happens:**
- All 3 vendors get notification: 
  - Mama's Kitchen: "Dispatcher assigned! You are pickup #1 of 3"
  - Campus Bites: "Dispatcher assigned! You are pickup #2 of 3"
  - Quick Snacks Hub: "Dispatcher assigned! You are pickup #3 of 3"
- Customer gets notification showing full route
- Dispatcher sees pickup checklist

---

### STEP 8: What We're Testing For

**✅ PASS if you see:**
1. All 3 vendor dashboards show multi-vendor badge
2. Group status updates in real-time (0/3 → 1/3 → 2/3 → 3/3)
3. Dispatcher broadcast ONLY happens when all 3 are ready
4. ONE dispatcher accepts entire order (not 3 separate dispatchers)
5. Each vendor sees their pickup position (1st, 2nd, 3rd)

**❌ FAIL if you see:**
- Dispatcher broadcast before all vendors ready
- Multiple dispatchers trying to accept same order
- Vendors don't see group status updates
- Missing multi-vendor badge
- Order group ID not matching across vendors

---

## 🐛 TROUBLESHOOTING

### If vendor dashboard doesn't update group status:
- Check browser console for errors
- Verify Socket.IO connection (should see in console)
- Refresh page and check if badge appears

### If dispatcher doesn't get broadcast:
- Check all 3 vendors actually marked "ready"
- Verify dispatcher is logged in and Socket.IO connected
- Check backend logs for "Broadcast to dispatchers_room"

### If orderGroupId doesn't match:
- Check checkout.js generated the ID
- Verify all orders have same orderGroupId in database
- Check payment webhook processed correctly

---

## 📱 URLS FOR QUICK ACCESS

**Vendor Dashboards:**
- http://localhost:5555/event-frontend/vendor-dashboard.html

**Dispatcher Dashboard:**
- http://localhost:5555/event-frontend/dispatcher.html

**Customer Shopping:**
- http://localhost:5555/event-frontend/home.html

**Backend API:**
- http://localhost:5555

---

## 📊 WHAT TO WATCH IN BACKEND LOGS

When testing, the terminal running `node server.js` should show:

```
POST /api/payments/init-multi-vendor-payment 200 (multi-vendor payment initialized)
✅ Webhook: charge.success (3 orders created with orderGroupId)
POST /api/orders/{id}/ready 200 (vendor 1 marks ready → 1/3)
POST /api/orders/{id}/ready 200 (vendor 2 marks ready → 2/3)
POST /api/orders/{id}/ready 200 (vendor 3 marks ready → 3/3)
🚨 Broadcasting to dispatchers_room (all ready!)
POST /api/dispatchers/accept/{orderGroupId} 200 (dispatcher accepts)
✅ Assigned dispatcher to 3 orders
```

---

## 💬 WHAT TO TELL ME DURING TEST

As you test, please report:

1. **When accepting each vendor order:**
   - "Vendor 1 (Mama's) - Order accepted, shows multi-vendor badge ✅"
   
2. **When marking ready:**
   - "Vendor 2 (Campus) marked ready - All dashboards updated to 1/3 ✅"
   
3. **When all ready:**
   - "Vendor 3 marked ready - Dispatcher broadcast received ✅"
   
4. **When dispatcher accepts:**
   - "Dispatcher accepted - All 3 vendors notified with positions ✅"

5. **Any errors:**
   - Screenshot + description
   - Check browser console for JavaScript errors

---

## 🎯 SUCCESS CRITERIA

**Test PASSES if:**
- ✅ Multi-vendor badge appears on all 3 vendor orders
- ✅ Group status counts accurately (0/3, 1/3, 2/3, 3/3)
- ✅ Updates happen in real-time without refresh
- ✅ Dispatcher broadcast ONLY at 3/3
- ✅ Single dispatcher assigned to all 3 orders
- ✅ Each vendor sees pickup position
- ✅ Customer sees complete progress

**Test FAILS if:**
- ❌ Any vendor doesn't see multi-vendor indicator
- ❌ Group status doesn't update
- ❌ Dispatcher broadcast too early
- ❌ Multiple dispatchers assigned
- ❌ JavaScript errors in console

---

## 🚀 READY TO START?

**Your checklist:**
- [ ] Server running on port 5555
- [ ] 4 browser tabs open (3 vendors + 1 dispatcher)
- [ ] All logged in successfully
- [ ] Dashboards loaded and showing "Active Orders" section
- [ ] Socket.IO connected (check console for connection message)

**Tell me when ready and I'll place the order!** 🛒

---

## 📞 QUICK REFERENCE

**All Passwords:**
- Vendors: `password123`
- Dispatchers: `dispatcher123`

**Test Vendor Emails:**
- mamas.kitchen@quickserve.test
- campus.bites@quickserve.test
- quick.snacks@quickserve.test

**Test Dispatcher Email:**
- dispatcher1@quickserve.test

**OrderGroupId Format:**
- `OG-{timestamp}-{random}` (e.g., OG-1730822400-x7k2p)
