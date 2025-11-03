# 🔒 Secure Payment-First Order Flow - Implementation Guide

## ✅ What Was Fixed

### Critical Security Issue (BEFORE)
- ❌ Customers could place orders WITHOUT paying
- ❌ Vendor charged ₦50 fee BEFORE customer payment
- ❌ No payment verification before order creation
- ❌ Money flow was backwards (vendor loses money if customer doesn't pay)

### Secure Implementation (NOW)
- ✅ Payment required BEFORE order creation
- ✅ Paystack payment gateway integration
- ✅ Vendor charged only AFTER customer pays
- ✅ Automatic webhook verification
- ✅ Duplicate payment prevention
- ✅ Email confirmations
- ✅ Pending orders expire after 1 hour

---

## 🔄 New Payment Flow (Step-by-Step)

### Step 1: Customer Initiates Order Payment
```http
POST /api/payments/init-order-payment
Authorization: Bearer <customer_jwt_token>
Content-Type: application/json

{
  "vendorId": "60d5f484f1b2c8a7e8c9d1e2",
  "items": [
    {
      "productId": "60d5f484f1b2c8a7e8c9d1e3",
      "name": "Jollof Rice",
      "price": 1500,
      "qty": 2
    },
    {
      "productId": "60d5f484f1b2c8a7e8c9d1e4",
      "name": "Chicken",
      "price": 800,
      "qty": 1
    }
  ],
  "deliveryAddress": "123 Main Street, Lagos",
  "deliveryFee": 500,
  "distanceKm": 3.5,
  "notes": "Please add extra spice",
  "packagingChoice": "eco-friendly",
  "packagingNotes": "Use biodegradable containers"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order payment session created. Complete payment to place order.",
  "authorization_url": "https://checkout.paystack.com/abc123xyz",
  "reference": "T_abc123xyz789",
  "pendingOrderId": "60d5f484f1b2c8a7e8c9d1e5",
  "total": 3850
}
```

**What Happens:**
1. Backend calculates totals:
   - Subtotal: ₦1500×2 + ₦800 = ₦3,800
   - Delivery Fee: ₦500
   - Platform Fee: ₦50 (charged to vendor later)
   - **Total: ₦4,300**

2. Backend creates **PendingOrder** in database (not a real order yet)

3. Paystack payment initialized with reference

4. Customer redirected to Paystack checkout page

---

### Step 2: Customer Completes Payment
- Customer enters card details on Paystack secure page
- Paystack processes payment
- On success, Paystack sends webhook to your backend

---

### Step 3: Webhook Receives Payment Confirmation
```http
POST /api/payments/webhook
X-Paystack-Signature: <signature_hash>
Content-Type: application/json

{
  "event": "charge.success",
  "data": {
    "reference": "T_abc123xyz789",
    "amount": 430000,
    "channel": "card",
    "metadata": {
      "userId": "60d5f484f1b2c8a7e8c9d1e1",
      "vendorId": "60d5f484f1b2c8a7e8c9d1e2",
      "reason": "order_payment"
    }
  }
}
```

**What Happens:**
1. Backend verifies Paystack signature (security check)
2. Finds PendingOrder by payment reference
3. Verifies payment amount matches order total
4. **Creates actual Order** in database with `status: "placed"`
5. Marks order as `payment.paid: true`
6. Charges vendor ₦50 platform fee (NOW that customer paid)
7. Sends confirmation email to customer
8. Updates transaction records

---

### Step 4: Order Created Successfully
**Customer receives:**
- Email confirmation with order ID
- Order shows in their app with status "placed"
- Payment receipt with reference number

**Vendor receives:**
- New order notification
- Order details in their app
- ₦50 platform fee deducted from wallet

**Backend creates:**
```javascript
Order {
  _id: "60d5f484f1b2c8a7e8c9d1e6",
  consumerId: "60d5f484f1b2c8a7e8c9d1e1",
  vendorId: "60d5f484f1b2c8a7e8c9d1e2",
  items: [...],
  total: 4300,
  status: "placed",
  payment: {
    reference: "T_abc123xyz789",
    paid: true,
    channel: "card",
    verifiedAt: "2025-11-02T10:30:00Z"
  }
}
```

---

## 📁 Files Created/Modified

### New Files Created
1. **`backend/src/models/PendingOrder.js`**
   - Schema for storing order details during payment
   - Auto-expires after 1 hour (TTL index)
   - Fields: items, totals, delivery info, payment reference

2. **`backend/src/middleware/paymentVerification.js`**
   - `requirePaidOrder`: Verifies order payment before operations
   - `blockUnpaidOrderCreation`: Blocks direct unpaid order creation

### Modified Files
3. **`backend/src/controllers/paymentController.js`**
   - Added `initOrderPayment()` function
   - Updated `handlePaystackWebhook()` to handle order payments
   - Separated wallet funding vs order payment logic

4. **`backend/src/routes/paymentRoutes.js`**
   - Added `POST /init-order-payment` endpoint
   - Updated webhook route documentation

5. **`backend/src/routes/order.routes.js`**
   - **BLOCKED** `POST /api/orders/` direct creation
   - Added payment verification middleware import
   - Orders now MUST go through payment flow

---

## 🔐 Security Features

### 1. Payment Verification
- Paystack webhook signature validation
- HMAC-SHA512 cryptographic verification
- Prevents fake payment notifications

### 2. Amount Verification
```javascript
if (Math.abs(amount - pendingOrder.total) > 0.01) {
  return res.status(400).json({ error: 'Payment amount mismatch' })
}
```
- Ensures customer paid exact amount
- Prevents partial or overpayment exploits

### 3. Duplicate Prevention
```javascript
const alreadyProcessed = await Transaction.findOne({
  'meta.reference': reference,
  status: 'success',
})
if (alreadyProcessed) {
  console.log(`⚠️ Duplicate webhook ignored: ${reference}`)
  return res.sendStatus(200)
}
```
- Prevents double-crediting
- Protects against webhook replay attacks

### 4. Direct Order Creation Blocked
```javascript
router.post("/", authRequired("customer"), blockUnpaidOrderCreation)
```
- Customers CANNOT bypass payment
- Returns 403 Forbidden with correct endpoint
- Forces payment-first flow

### 5. Pending Order Expiration
```javascript
expiresAt: { 
  type: Date, 
  default: () => new Date(Date.now() + 60 * 60 * 1000),
  index: { expires: 0 } // MongoDB TTL index
}
```
- Pending orders auto-delete after 1 hour
- Prevents database bloat
- Cleans up abandoned payments

---

## 🧪 Testing the Flow

### Test Script (Node.js)
```javascript
const axios = require('axios');

const API_URL = 'http://localhost:5555';
let authToken = '';
let paymentReference = '';

async function testPaymentFlow() {
  console.log('🧪 Testing Secure Payment Flow...\n');

  // 1. Login as customer
  console.log('1️⃣ Logging in as customer...');
  const loginRes = await axios.post(`${API_URL}/api/auth/login`, {
    email: 'customer@test.com',
    password: 'Test123!'
  });
  authToken = loginRes.data.token;
  console.log('✅ Logged in\n');

  // 2. Initialize order payment
  console.log('2️⃣ Initializing order payment...');
  const paymentRes = await axios.post(
    `${API_URL}/api/payments/init-order-payment`,
    {
      vendorId: '60d5f484f1b2c8a7e8c9d1e2',
      items: [
        { name: 'Jollof Rice', price: 1500, qty: 2 },
        { name: 'Chicken', price: 800, qty: 1 }
      ],
      deliveryAddress: '123 Test Street, Lagos',
      deliveryFee: 500,
      distanceKm: 3.5
    },
    { headers: { Authorization: `Bearer ${authToken}` } }
  );
  console.log('✅ Payment initialized');
  console.log(`   Authorization URL: ${paymentRes.data.authorization_url}`);
  console.log(`   Reference: ${paymentRes.data.reference}`);
  console.log(`   Total: ₦${paymentRes.data.total}\n`);
  paymentReference = paymentRes.data.reference;

  // 3. Try to create order directly (should fail)
  console.log('3️⃣ Attempting direct order creation (should fail)...');
  try {
    await axios.post(
      `${API_URL}/api/orders`,
      { vendorId: '60d5f484f1b2c8a7e8c9d1e2', items: [] },
      { headers: { Authorization: `Bearer ${authToken}` } }
    );
    console.log('❌ SECURITY ISSUE: Direct order creation succeeded!\n');
  } catch (err) {
    console.log('✅ Direct order creation blocked (as expected)');
    console.log(`   Error: ${err.response.data.error}\n`);
  }

  // 4. Simulate Paystack webhook (in production, Paystack sends this)
  console.log('4️⃣ Simulating Paystack webhook...');
  console.log('   NOTE: In production, Paystack sends this automatically');
  console.log('   For testing, you need to manually trigger webhook or use Paystack test mode\n');
}

testPaymentFlow().catch(console.error);
```

### Test with Postman
1. **Initialize Order Payment**
   ```
   POST http://localhost:5555/api/payments/init-order-payment
   Headers:
     Authorization: Bearer <customer_token>
     Content-Type: application/json
   Body:
     {
       "vendorId": "...",
       "items": [...],
       "deliveryAddress": "...",
       "deliveryFee": 500
     }
   ```

2. **Visit Authorization URL**
   - Copy `authorization_url` from response
   - Paste in browser
   - Use Paystack test card: `4084084084084081`
   - CVV: `408`, Expiry: `12/25`, PIN: `0000`

3. **Verify Webhook Received**
   - Check server logs for webhook confirmation
   - Check database for created Order

---

## 🌐 Webhook Setup (Production)

### Configure Paystack Dashboard
1. Go to https://dashboard.paystack.com/
2. Navigate to **Settings** → **Webhooks**
3. Add webhook URL: `https://yourdomain.com/api/payments/webhook`
4. Select events: `charge.success`
5. Save webhook

### Test Webhook Locally (Development)
Use **ngrok** to expose local server:
```bash
# Install ngrok
npm install -g ngrok

# Expose port 5555
ngrok http 5555

# Copy HTTPS URL (e.g., https://abc123.ngrok.io)
# Update Paystack webhook URL: https://abc123.ngrok.io/api/payments/webhook
```

---

## 📊 Database Schema Changes

### New Collection: `pendingorders`
```javascript
{
  _id: ObjectId,
  consumerId: ObjectId (ref: User),
  vendorId: ObjectId (ref: User),
  items: [{
    productId: ObjectId,
    name: String,
    price: Number,
    qty: Number
  }],
  subtotal: Number,
  deliveryFee: Number,
  platformFee: Number,
  total: Number,
  deliveryAddress: String,
  notes: String,
  paymentReference: String (unique),
  paymentStatus: "pending" | "paid" | "failed" | "cancelled",
  expiresAt: Date (TTL index),
  createdAt: Date,
  updatedAt: Date
}
```

### Updated: `orders` Collection
```javascript
payment: {
  reference: String,        // Paystack payment reference
  paid: Boolean,           // true only after webhook confirmation
  channel: String,         // "card", "bank", "ussd", etc.
  verifiedAt: Date        // Timestamp of webhook verification
}
```

---

## 🔧 Environment Variables Required

Add to `.env`:
```env
PAYSTACK_SECRET_KEY=sk_test_xxxxx...
PAYSTACK_PUBLIC_KEY=pk_test_xxxxx...
PAYSTACK_CURRENCY=NGN
APP_BASE_URL=http://localhost:5555
```

---

## 🚀 Migration Guide (Existing Orders)

If you have existing orders without payment verification:

```javascript
// Run this script once to mark old orders
const Order = require('./src/models/Order');

async function migrateOrders() {
  const result = await Order.updateMany(
    { 'payment.paid': { $exists: false } },
    { 
      $set: { 
        'payment.paid': false,
        'payment.reference': 'LEGACY_ORDER'
      } 
    }
  );
  console.log(`Migrated ${result.modifiedCount} orders`);
}

migrateOrders();
```

---

## 📈 Monitoring & Logs

### Success Logs
```
✅ Order created successfully: 60d5f484f1b2c8a7e8c9d1e6 → Payment: ₦4300
✅ Wallet funded successfully: ₦1000 → User: 60d5f484f1b2c8a7e8c9d1e1
```

### Error Logs
```
⚠️ Invalid Paystack webhook signature
❌ Pending order not found for reference: T_abc123xyz789
❌ Payment amount mismatch. Expected: 4300, Got: 3500
⚠️ Duplicate webhook ignored: T_abc123xyz789
```

---

## 🎯 Next Steps

### Immediate
1. ✅ Update Flutter app to use `/api/payments/init-order-payment`
2. ✅ Integrate Paystack checkout in mobile app
3. ✅ Configure webhook in Paystack dashboard

### Future Enhancements
- [ ] Add wallet-based payments (alternative to Paystack)
- [ ] Implement refund system
- [ ] Add payment installments for large orders
- [ ] Support multiple payment providers
- [ ] Add payment analytics dashboard

---

## 🐛 Troubleshooting

### Issue: "Pending order not found"
**Cause:** Webhook received but PendingOrder expired (> 1 hour old)
**Solution:** Customer needs to re-initiate payment

### Issue: "Payment amount mismatch"
**Cause:** Items/prices changed between payment init and webhook
**Solution:** Ensure prices are locked in PendingOrder

### Issue: "Invalid signature"
**Cause:** Wrong PAYSTACK_SECRET_KEY or body modified
**Solution:** Verify environment variable, check middleware order

### Issue: Webhook not received
**Cause:** Network issues, wrong URL, or Paystack not configured
**Solution:** 
- Check Paystack dashboard webhook logs
- Verify webhook URL is publicly accessible
- Test with ngrok for local development

---

## 📞 Support

- **Backend Issues:** Check `backend/server.js` logs
- **Payment Issues:** Check Paystack dashboard → Transactions
- **Webhook Issues:** Check Paystack dashboard → Webhooks → Logs
- **Database Issues:** Check MongoDB Atlas logs

---

**✅ Implementation Complete!**

Your QuickServe backend now has enterprise-grade payment security. Customers MUST pay before orders are created, protecting both vendors and the platform from fraud.
