# 🔄 QuickServe Payment & Data Flow Documentation

## 📊 **CURRENT DATA FLOW STATUS**

### ✅ **What's Working:**

#### 1. **Vendor → Consumer Product Flow** ✅
```
VENDOR UPLOADS PRODUCT
  ↓
Backend stores in MongoDB (Product collection)
  ↓
Consumer fetches via GET /api/products
  ↓
CONSUMER SEES PRODUCT in app
```

**✅ Products uploaded by vendors ARE visible to all consumers!**

---

#### 2. **Order Creation** ✅
- Customers can create orders
- Orders link to vendor products
- Total is calculated (subtotal + delivery + platform fee)

---

### ⚠️ **CRITICAL ISSUES:**

#### 1. **NO PAYMENT COLLECTION BEFORE ORDER CREATION** 🚨

**Current Problem:**
```javascript
// backend/src/routes/order.routes.js Line 33
const order = await Order.create({
  consumerId: req.user.id,
  vendorId: vendor._id,
  items,
  total,        // ❌ Calculated but NOT collected!
  status: "placed"  // ❌ Order created without payment!
});
```

**Result:** Customers can place orders without paying!

---

#### 2. **Vendor Wallet Credit Happens on Delivery** ✅ (Correct)

```javascript
// When order status = "delivered"
if (status === 'delivered') {
  vendor.wallet += order.subtotal  // ✅ Vendor gets paid
  await vendor.save()
}
```

**This is correct** - vendors should only get paid after delivery.

---

## 🔧 **RECOMMENDED FIXES:**

### **Fix 1: Implement Pre-Order Payment**

#### **Step 1: Customer Initiates Payment**

**Endpoint:** `POST /api/payments/init-order-payment`

**Request:**
```json
{
  "vendorId": "vendor_id",
  "items": [
    {"productId": "prod_123", "quantity": 2, "price": 1500}
  ],
  "deliveryAddress": "123 Main St",
  "distanceKm": 5
}
```

**Backend Logic:**
1. Calculate total (subtotal + delivery + platform fee)
2. Create PENDING order in database
3. Initialize Paystack payment
4. Return payment URL to customer

**Response:**
```json
{
  "orderId": "order_123",
  "total": 3550,
  "authorization_url": "https://paystack.com/pay/...",
  "reference": "QS_12345"
}
```

---

#### **Step 2: Customer Completes Payment**

Customer is redirected to Paystack → Pays → Redirected back

---

#### **Step 3: Backend Verifies Payment**

**Webhook:** `POST /api/payments/webhook` (Paystack calls this)

**Logic:**
1. Verify payment signature
2. Check payment status = "success"
3. Update order status: "pending" → "placed"
4. Credit platform wallet (platform fee)
5. Hold vendor portion until delivery

**Order Status After Payment:**
```json
{
  "orderId": "order_123",
  "status": "placed",  // ✅ Now truly placed
  "payment": {
    "paid": true,
    "amount": 3550,
    "reference": "QS_12345",
    "paidAt": "2025-11-02T..."
  }
}
```

---

### **Fix 2: Protect Order Creation**

**Update Order Creation Endpoint:**

```javascript
// Only allow creating orders through payment flow
router.post("/", authRequired("customer"), async (req, res) => {
  // ❌ Remove direct order creation
  return res.status(400).json({
    error: "Please use /api/payments/init-order-payment to create orders"
  });
});

// Or require payment reference
router.post("/", authRequired("customer"), async (req, res) => {
  const { paymentReference } = req.body;
  
  // Verify payment was made
  const payment = await verifyPaystackPayment(paymentReference);
  if (!payment.success) {
    return res.status(400).json({ error: "Payment not verified" });
  }
  
  // Now create order...
});
```

---

## 💰 **PROPER MONEY FLOW:**

### **Current vs. Recommended:**

#### ❌ **Current (WRONG):**
```
Customer places order (FREE!)
  ↓
Vendor accepts (charges vendor ₦50)  // ❌ Vendor pays before getting paid!
  ↓
Vendor prepares
  ↓
Rider delivers
  ↓
Vendor wallet credited (finally gets money)
```

#### ✅ **Recommended (CORRECT):**
```
Customer pays ₦3,550 upfront via Paystack
  ↓
Platform holds money:
  - Subtotal: ₦3,000 (for vendor, held)
  - Delivery: ₦500 (for rider, held)
  - Platform fee: ₦50 (platform keeps immediately)
  ↓
Vendor accepts (NO charge - already paid by customer!)
  ↓
Vendor prepares
  ↓
Rider delivers
  ↓
Release held funds:
  - Vendor gets ₦3,000
  - Rider gets ₦500
```

---

## 🔐 **SECURITY CONSIDERATIONS:**

### **1. Prevent Unpaid Orders**
```javascript
// Before creating order, ALWAYS verify payment
const paymentVerified = await verifyPaystackPayment(reference);
if (!paymentVerified) {
  throw new Error("Payment required before order creation");
}
```

### **2. Prevent Double-Spending**
```javascript
// Check if payment reference already used
const existingOrder = await Order.findOne({ 
  'payment.reference': paymentReference 
});
if (existingOrder) {
  throw new Error("Payment already used for another order");
}
```

### **3. Validate Payment Amount**
```javascript
// Ensure paid amount matches order total
if (payment.amount !== order.total * 100) {  // Convert to kobo
  throw new Error("Payment amount mismatch");
}
```

---

## 📱 **FRONTEND INTEGRATION:**

### **Flutter Consumer App:**

```dart
// 1. Customer adds items to cart
CartProvider.addItem(product);

// 2. Customer clicks "Checkout"
Future<void> checkout() async {
  // Calculate total
  final total = cart.total + deliveryFee + platformFee;
  
  // Initialize payment
  final response = await ApiClient().post('/api/payments/init-order-payment', {
    'vendorId': vendorId,
    'items': cart.items,
    'deliveryAddress': address,
    'distanceKm': distance,
  });
  
  // Get payment URL
  final paymentUrl = response['authorization_url'];
  final orderId = response['orderId'];
  
  // Open Paystack in webview
  await launchUrl(paymentUrl);
  
  // After payment, verify
  final order = await ApiClient().get('/api/orders/$orderId');
  if (order['payment']['paid']) {
    // Success! Show order confirmation
    Navigator.push(context, OrderSuccessScreen(order));
  }
}
```

---

## 🎯 **ACTION ITEMS:**

### **High Priority:**
1. ✅ **Create payment initialization endpoint**
2. ✅ **Implement Paystack webhook handler**
3. ✅ **Update order creation to require payment**
4. ✅ **Add payment verification middleware**

### **Medium Priority:**
5. ⬜ **Add refund logic** (if order cancelled before delivery)
6. ⬜ **Implement escrow system** (hold funds until delivery)
7. ⬜ **Add payment retry logic** (if payment fails)

### **Low Priority:**
8. ⬜ **Add payment receipts** (email customers after payment)
9. ⬜ **Payment history dashboard**
10. ⬜ **Analytics for payment success rates**

---

## 🧪 **TESTING CHECKLIST:**

- [ ] Customer can browse products from any vendor
- [ ] Customer cannot create order without payment
- [ ] Payment initialization returns valid Paystack URL
- [ ] Webhook updates order status after successful payment
- [ ] Failed payments don't create orders
- [ ] Vendor sees only PAID orders
- [ ] Vendor wallet credited on delivery
- [ ] Rider wallet credited on delivery
- [ ] Platform fee collected immediately

---

## 📞 **NEED HELP IMPLEMENTING?**

I can help you:
1. Create the payment initialization endpoint
2. Set up Paystack webhook handler
3. Update order creation logic
4. Add payment verification
5. Update Flutter apps to use new flow

Just let me know which part you want to tackle first!

---

**Current Status:** 🔴 **CRITICAL** - Orders can be placed without payment  
**Recommended Action:** Implement payment-first order flow immediately
