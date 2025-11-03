# 🚀 Quick Start Guide - Secure Payment Flow

## ✅ What Changed

**BEFORE (Insecure):**
```javascript
// Customer could place order WITHOUT paying
POST /api/orders/
→ Order created immediately ❌
```

**NOW (Secure):**
```javascript
// Customer MUST pay FIRST
POST /api/payments/init-order-payment
→ Paystack payment page
→ Customer pays
→ Webhook confirms payment
→ Order created ✅
```

---

## 🔥 Quick API Reference

### 1. Initialize Order Payment (Customer App)
```http
POST /api/payments/init-order-payment
Authorization: Bearer <customer_token>

{
  "vendorId": "vendor_id_here",
  "items": [
    { "name": "Jollof Rice", "price": 1500, "qty": 2 }
  ],
  "deliveryAddress": "123 Street, Lagos",
  "deliveryFee": 500
}

Response:
{
  "authorization_url": "https://checkout.paystack.com/...",
  "reference": "T_abc123xyz",
  "total": 3550
}
```

### 2. Blocked Endpoint (Security)
```http
POST /api/orders/
❌ Returns 403 Forbidden
Message: "Orders must be created through payment flow"
```

### 3. Webhook (Automatic)
```http
POST /api/payments/webhook
X-Paystack-Signature: <signature>

{
  "event": "charge.success",
  "data": { ... }
}

→ Order created automatically after payment verified
```

---

## 📱 Flutter App Integration

### Step 1: Update Order Creation
Replace old order creation code with payment initialization:

```dart
// OLD (Insecure) - REMOVE THIS
final response = await http.post(
  Uri.parse('$baseUrl/api/orders'),
  body: json.encode({
    'vendorId': vendorId,
    'items': items,
  }),
);

// NEW (Secure) - USE THIS
Future<void> createOrderWithPayment({
  required String vendorId,
  required List<Map<String, dynamic>> items,
  required String deliveryAddress,
  required double deliveryFee,
}) async {
  // 1. Initialize payment
  final response = await http.post(
    Uri.parse('$baseUrl/api/payments/init-order-payment'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'vendorId': vendorId,
      'items': items,
      'deliveryAddress': deliveryAddress,
      'deliveryFee': deliveryFee,
    }),
  );

  final data = json.decode(response.body);
  
  // 2. Open Paystack checkout
  final paystackUrl = data['authorization_url'];
  
  // Option A: Use webview_flutter
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentWebView(url: paystackUrl),
    ),
  );
  
  // Option B: Use flutter_paystack plugin (recommended)
  // See: https://pub.dev/packages/flutter_paystack
}
```

### Step 2: Handle Payment Success
```dart
class PaymentWebView extends StatelessWidget {
  final String url;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complete Payment')),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        onPageFinished: (String url) {
          // Check if payment completed
          if (url.contains('success') || url.contains('payment/verify')) {
            // Webhook will create order automatically
            Navigator.pop(context);
            Navigator.pushNamed(context, '/order-success');
          }
        },
      ),
    );
  }
}
```

---

## 🔧 Backend Setup Checklist

- [x] ✅ PendingOrder model created
- [x] ✅ Payment verification middleware added
- [x] ✅ initOrderPayment endpoint created
- [x] ✅ Webhook handler updated for orders
- [x] ✅ Direct order creation blocked
- [ ] ⏳ Configure Paystack webhook URL in dashboard
- [ ] ⏳ Test with Paystack test cards
- [ ] ⏳ Update Flutter apps to use new endpoint

---

## 🧪 Test the Flow

### Using Postman

1. **Register Customer:**
```
POST http://localhost:5555/api/auth/register
Body: {
  "name": "Test Customer",
  "email": "customer@test.com",
  "password": "Test123!",
  "role": "customer"
}
```

2. **Initialize Payment:**
```
POST http://localhost:5555/api/payments/init-order-payment
Headers: Authorization: Bearer <token>
Body: {
  "vendorId": "...",
  "items": [{"name": "Food", "price": 1000, "qty": 1}],
  "deliveryAddress": "Test Address",
  "deliveryFee": 500
}
```

3. **Open Authorization URL:**
- Copy `authorization_url` from response
- Open in browser
- Use Paystack test card: `4084084084084081`
- Complete payment

4. **Webhook Creates Order:**
- Paystack sends webhook automatically
- Check server logs for: `✅ Order created successfully`

### Using Test Script
```bash
cd backend
node test-payment-flow.js
```

---

## 🌐 Paystack Test Cards

| Card Number          | CVV | Expiry | PIN  | Result  |
|---------------------|-----|--------|------|---------|
| 4084 0840 8408 4081 | 408 | 12/25  | 0000 | Success |
| 5060 6666 6666 6666 | 123 | 12/25  | 1234 | Success |
| 4084 0840 8408 4081 | 408 | 12/25  | 1234 | Fail    |

---

## 🔐 Security Features

✅ **Payment Required First**
- Customers CANNOT place orders without paying
- Payment gateway handles all card processing

✅ **Webhook Signature Verification**
- HMAC-SHA512 validation
- Prevents fake payment notifications

✅ **Amount Verification**
- Backend verifies payment amount matches order total
- Prevents partial payment exploits

✅ **Duplicate Prevention**
- Same payment reference cannot be used twice
- Protects against replay attacks

✅ **Pending Order Expiration**
- Unpaid orders auto-delete after 1 hour
- Keeps database clean

---

## 📊 Money Flow

### Old Flow (INSECURE)
```
1. Customer places order (FREE) ❌
2. Vendor charged ₦50 fee FIRST ❌
3. Customer might never pay ❌
4. Vendor loses money ❌
```

### New Flow (SECURE)
```
1. Customer initiates order ✅
2. Customer PAYS through Paystack ✅
3. Backend verifies payment ✅
4. Order created, vendor charged ₦50 ✅
5. Vendor receives money (minus fee) ✅
```

---

## 🐛 Common Issues

### "Direct order creation blocked"
✅ **Expected behavior!** Use `/api/payments/init-order-payment` instead

### "Pending order not found"
- Payment took > 1 hour (expired)
- Customer needs to restart payment

### "Invalid signature"
- Check PAYSTACK_SECRET_KEY in .env
- Verify webhook URL matches Paystack dashboard

### Webhook not received
- Configure webhook in Paystack dashboard
- Use ngrok for local testing
- Check Paystack webhook logs

---

## 📞 Need Help?

- **Documentation:** `backend/SECURE_PAYMENT_IMPLEMENTATION.md`
- **Test Script:** `backend/test-payment-flow.js`
- **Payment Flow:** `backend/PAYMENT_FLOW_DOCUMENTATION.md`

---

**Ready to go! 🚀**

Your backend now has enterprise-grade payment security. Test thoroughly before deploying to production.
