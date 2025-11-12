# 🧪 QuickServe Event Edition - Complete Testing Guide

This guide will walk you through testing every feature of the QuickServe Event Edition system.

## Prerequisites

1. **Backend Server Running** on `http://localhost:5000`
2. **MongoDB Connected** with test data loaded
3. **Frontend Served** from `event-frontend` folder
4. **Multiple Browser Windows** (to simulate different users)

---

## 🚀 Quick Setup

```powershell
# Terminal 1 - Start Backend
cd backend
npm start

# Terminal 2 - Generate Test Data
cd backend
node create-event-test-data.js

# Terminal 3 - Serve Frontend
cd event-frontend
npx http-server -p 8080
```

Then open: http://localhost:8080

---

## Test Scenario 1: Consumer Order Flow 🛒

**Goal**: Place an order as an event attendee

### Steps:

1. **Browse Vendors**
   - Open `http://localhost:8080/index.html`
   - ✅ Verify carousel displays 3 slides with vendor images
   - ✅ Verify "Featured Vendors" section shows 4 vendors
   - ✅ Click each category tab (Nigerian, Fast Food, Drinks, Snacks, Continental)
   - ✅ Verify vendors filter correctly

2. **View Vendor Products**
   - Click any vendor card (e.g., "Mama Put Kitchen")
   - ✅ Verify products display with images, names, prices
   - ✅ Verify "Add to Cart" buttons work
   - ✅ Check cart icon shows item count badge

3. **Add Items to Cart**
   - Add 3 different products from the vendor
   - ✅ Verify cart count increases (should show "3")
   - Click "View Cart" or cart icon

4. **Checkout Process**
   - On checkout page, enter:
     - Phone: `08012345678`
     - Seat Number: `A-101`
   - ✅ Verify subtotal calculation is correct
   - ✅ Verify service charge is ₦100
   - ✅ Verify total = subtotal + ₦100
   - Click "Proceed to Payment"

5. **Paystack Payment**
   - ✅ Paystack popup should appear
   - Use test card: `5060666666666666666`
   - CVV: `123`, Expiry: `12/25`, OTP: `123456`
   - ✅ Payment should succeed
   - ✅ Should redirect to order tracking page

6. **Order Tracking**
   - ✅ Verify order ID is displayed
   - ✅ Verify status shows "Pending" initially
   - ✅ Verify QR code is visible
   - ✅ Verify order details (items, total, seat number) are correct
   - **Save this Order ID for next scenarios!**

---

## Test Scenario 2: Vendor Dashboard 👨‍🍳

**Goal**: Accept and prepare orders

### Steps:

1. **Login as Vendor**
   - Open `http://localhost:8080/login.html` in a **NEW PRIVATE/INCOGNITO WINDOW**
   - Email: `mamput@test.com`
   - Password: `password123`
   - ✅ Login should succeed

2. **View Orders**
   - ✅ Should see the order from Scenario 1 with status "Pending"
   - ✅ Should ONLY see orders for "Mama Put Kitchen" (not other vendors' orders)

3. **Accept Order**
   - Click "Accept Order" button
   - ✅ Status should change to "Accepted"
   - ✅ Button should change to "Mark as Preparing"

4. **Mark as Preparing**
   - Click "Mark as Preparing"
   - ✅ Status should change to "Preparing"
   - ✅ Button should change to "Mark as Ready"

5. **Mark as Ready**
   - Click "Mark as Ready"
   - ✅ Status should change to "Ready"
   - ✅ Order should now be available for dispatchers

6. **Check Earnings**
   - Scroll to earnings section
   - ✅ Verify total earnings reflect completed orders
   - ✅ Verify order count is accurate

---

## Test Scenario 3: Dispatcher Dashboard (Single) 🏃

**Goal**: Claim and deliver an order

### Steps:

1. **Login as Dispatcher**
   - Open `http://localhost:8080/login.html` in a **THIRD PRIVATE WINDOW**
   - Email: `dispatcher1@event.test`
   - Password: `password123`
   - ✅ Login should succeed
   - Navigate to `http://localhost:8080/dispatcher.html`

2. **View Ready Orders**
   - ✅ Should see the order marked "Ready" by vendor
   - ✅ Order should show seat number, vendor name, total amount
   - ✅ "Claim Order" button should be visible

3. **Claim Order**
   - Click "Claim Order"
   - ✅ Button should disable immediately
   - ✅ Order status should change to "Out for Delivery"
   - ✅ Order should move to "My Active Orders" section
   - ✅ Order should disappear from "Ready Orders" list

4. **View Order Tracking (Consumer Side)**
   - Switch back to the consumer's tracking window
   - ✅ Status should update to "Out for Delivery" (may need refresh)

5. **Confirm Delivery**
   - In dispatcher window, click "Confirm Delivery"
   - Enter the QR token shown on consumer's tracking page
   - ✅ Should accept correct token
   - ✅ Order status should change to "Delivered"
   - ✅ Order should move to completed section

---

## Test Scenario 4: Dispatcher Race Condition 🏁

**Goal**: Verify only ONE dispatcher can claim an order

### Setup:
- **Window A**: Dispatcher 1 logged in
- **Window B**: Dispatcher 2 logged in (use `dispatcher2@event.test`)
- **Order**: Create a new ready order (repeat Scenario 1 & 2)

### Steps:

1. **Both Dispatchers See Same Order**
   - ✅ Both windows should show the same ready order
   - ✅ Both should see "Claim Order" button

2. **Simultaneous Claim Attempt**
   - In **Window A**, click "Claim Order"
   - **IMMEDIATELY** in **Window B**, click "Claim Order"
   
3. **Expected Result**
   - ✅ **ONE dispatcher succeeds** (order moves to their "Active Orders")
   - ✅ **OTHER dispatcher gets error**: "Order already claimed by another dispatcher"
   - ✅ Order disappears from "Ready Orders" in BOTH windows
   - ✅ Only the successful dispatcher sees the order in "Active Orders"

4. **Real-Time Update (Socket.IO)**
   - When Dispatcher A claims, **Window B should update automatically** within 1-2 seconds
   - ✅ Order should vanish from Window B's list without needing to refresh
   - ✅ Check browser console for: `"Order claimed by another dispatcher: {...}"`

---

## Test Scenario 5: Admin Dashboard 👑

**Goal**: Monitor system-wide activity

### Steps:

1. **Login as Admin**
   - Email: `admin@event.test`
   - Password: `admin123`
   - Navigate to `http://localhost:8080/admin.html`

2. **View Overview**
   - ✅ Total orders count should be accurate
   - ✅ Total revenue should match sum of all completed orders
   - ✅ Vendor count should be 20
   - ✅ Dispatcher count should be 10

3. **Monitor Real-Time**
   - Keep admin dashboard open
   - Create a new order in another window (Scenario 1)
   - ✅ Dashboard should update (may need Socket.IO enhancement)

---

## Test Scenario 6: Multiple Vendors Isolation 🔒

**Goal**: Ensure vendors only see their own orders

### Steps:

1. **Place Orders from Multiple Vendors**
   - As consumer, order from "Mama Put Kitchen"
   - As consumer, order from "Burger Hub"
   - As consumer, order from "Smoothie Bar"

2. **Login as Each Vendor**
   - Login to Mama Put: `mamput@test.com`
   - ✅ Should ONLY see Mama Put's orders

   - Login to Burger Hub: `burgerhub@test.com`
   - ✅ Should ONLY see Burger Hub's orders

   - Login to Smoothie Bar: `smoothiebar@test.com`
   - ✅ Should ONLY see Smoothie Bar's orders

3. **Verify No Cross-Contamination**
   - ✅ Each vendor dashboard shows different orders
   - ✅ Earnings calculations are separate
   - ✅ No vendor can see other vendors' data

---

## Test Scenario 7: Service Charge Calculation 💰

**Goal**: Verify ₦100 service charge is always applied

### Test Cases:

| Items Total | Service Charge | Final Total | Expected |
|------------|---------------|-------------|----------|
| ₦500       | ₦100          | ₦600        | ✅       |
| ₦1,000     | ₦100          | ₦1,100      | ✅       |
| ₦50        | ₦100          | ₦150        | ✅       |
| ₦5,000     | ₦100          | ₦5,100      | ✅       |

**Steps:**
1. Add items totaling each amount above
2. Check checkout page calculations
3. ✅ Verify service charge is always exactly ₦100
4. ✅ Verify total = subtotal + 100

---

## Test Scenario 8: QR Code Verification 🔍

**Goal**: Ensure delivery confirmation security

### Steps:

1. **Valid QR Code**
   - Complete order flow to delivery stage
   - Copy correct QR token from tracking page
   - Dispatcher enters correct token
   - ✅ Should confirm delivery successfully

2. **Invalid QR Code**
   - Dispatcher enters random token: `WRONG123`
   - ✅ Should reject with error message
   - ✅ Order status should NOT change

3. **Reused QR Code**
   - After successful delivery, try using same QR again
   - ✅ Should reject (order already delivered)

---

## Test Scenario 9: Order Status Workflow ⚙️

**Goal**: Verify complete status progression

### Expected Flow:
```
pending → accepted → preparing → ready → out_for_delivery → delivered
```

### Steps:

1. Create new order (consumer)
   - ✅ Status: `pending`

2. Vendor accepts
   - ✅ Status: `accepted`

3. Vendor marks preparing
   - ✅ Status: `preparing`

4. Vendor marks ready
   - ✅ Status: `ready`

5. Dispatcher claims
   - ✅ Status: `out_for_delivery`

6. Dispatcher confirms delivery
   - ✅ Status: `delivered`

**Test Invalid Transitions:**
- ❌ Cannot go from `pending` to `ready` (must go through `accepted` and `preparing`)
- ❌ Consumer cannot modify status
- ❌ Dispatcher cannot claim order unless status is `ready`

---

## Performance Tests 🚀

### Test 1: Concurrent Orders
1. Open 10 browser tabs
2. Create 10 orders simultaneously
3. ✅ All should process successfully
4. ✅ No duplicate order IDs
5. ✅ All orders appear in vendor dashboard

### Test 2: Dispatcher Load
1. Create 20 ready orders
2. Login 5 dispatchers simultaneously
3. All dispatchers claim orders rapidly
4. ✅ No order is claimed twice
5. ✅ Each dispatcher gets unique orders

---

## Mobile Responsive Tests 📱

### Test on:
- iPhone (Safari Mobile)
- Android (Chrome Mobile)
- Tablet (iPad)

### Verify:
- ✅ Carousel swipes smoothly
- ✅ Category tabs are scrollable
- ✅ Vendor cards stack properly
- ✅ Checkout form fits screen
- ✅ Paystack popup works on mobile
- ✅ QR code displays clearly

---

## Common Issues & Solutions 🛠️

### Issue: "Network Error" on API calls
**Solution**: 
- Check backend is running on port 5000
- Verify MongoDB is connected
- Check `event-frontend/js/config.js` has correct `API_BASE_URL`

### Issue: Paystack popup doesn't appear
**Solution**:
- Check `PAYSTACK_PUBLIC_KEY` in `config.js`
- Ensure using test key: `pk_test_...`
- Check browser console for errors

### Issue: Dispatcher doesn't see ready orders
**Solution**:
- Ensure vendor marked order as "Ready"
- Check order status in database: `db.eventorders.find({status: 'ready'})`
- Verify JWT token is valid (check localStorage)

### Issue: Socket.IO not updating
**Solution**:
- Check browser console for Socket.IO connection errors
- Verify `socket.io-client` CDN is loaded
- Check backend Socket.IO is initialized in `index.js`

---

## Final Checklist Before Going Live ✅

- [ ] All test scenarios pass
- [ ] Race condition test passes (only one dispatcher claims)
- [ ] Vendor isolation verified (no cross-data)
- [ ] Service charge always ₦100
- [ ] QR codes work correctly
- [ ] Mobile responsive on all devices
- [ ] Payment flow works end-to-end
- [ ] Socket.IO real-time updates working
- [ ] Admin dashboard shows accurate data
- [ ] No console errors in any page

---

## Production Testing Steps 🌐

**Before the event:**

1. **Load Testing**
   - Use tool like Artillery or k6
   - Simulate 1,000+ concurrent users
   - Target: < 2 second response times

2. **Database Backup**
   - Setup MongoDB Atlas backups
   - Test restore procedure

3. **Payment Verification**
   - Switch to Paystack live keys
   - Test with real ₦100 transaction
   - Verify webhook callbacks work

4. **Monitoring Setup**
   - Setup error logging (Sentry)
   - Setup uptime monitoring (UptimeRobot)
   - Configure alerts for downtime

---

## Support During Event 📞

**Quick Commands:**

```powershell
# Check active orders
mongo quickserve
db.eventorders.find({status: {$ne: 'delivered'}}).count()

# Check stuck orders (older than 30 mins in "ready")
db.eventorders.find({
  status: 'ready',
  updatedAt: {$lt: new Date(Date.now() - 30*60*1000)}
})

# Reset a stuck order
db.eventorders.updateOne(
  {_id: ObjectId('ORDER_ID')},
  {$set: {status: 'pending', dispatcherId: null}}
)
```

---

## Test Data Reference 📋

### Test Vendors (created by `create-event-test-data.js`):
- mamput@test.com (Mama Put Kitchen)
- burgerhub@test.com (Burger Hub)
- smoothiebar@test.com (Smoothie Bar)
- ... (17 more vendors)

### Test Dispatchers:
- dispatcher1@event.test through dispatcher10@event.test
- All passwords: `password123`

### Test Admin:
- Email: `admin@event.test`
- Password: `admin123`

---

## Success Metrics 🎯

After testing, you should achieve:
- ✅ **100% order accuracy** (no lost or duplicate orders)
- ✅ **< 3 seconds** average page load time
- ✅ **Zero race conditions** in dispatcher claiming
- ✅ **Complete vendor isolation** (no data leaks)
- ✅ **100% payment success rate** (with test cards)
- ✅ **Real-time updates** working (< 2 second delay)

---

**Ready to test? Start with Scenario 1 and work through each one! 🚀**

For issues, check the browser console and backend logs for detailed error messages.
