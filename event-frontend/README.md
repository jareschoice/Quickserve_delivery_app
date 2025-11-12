# 🌐 QuickServe Event Edition — Frontend

## 📌 Overview
The *QuickServe Event Edition Frontend* is a responsive web platform for a *one-day world record event* featuring *20 vendors* and *20,000+ participants*.  

It allows consumers (event attendees) to:
- Browse vendors and products  
- Place orders easily  
- Checkout using Paystack  
- Track orders in real-time  
- Confirm delivery via QR code  

This frontend works with the *QuickServe Event Backend API* and is designed to run smoothly on any device without requiring users to install an app.

---

## 🎨 Tech Stack
| Component | Technology |
|------------|-------------|
| *UI Framework* | Bootstrap 5 (preferred) |
| *JS Library* | Vanilla JS or jQuery (for simplicity) |
| *State Management* | Local Storage (cart, seat ID) |
| *API* | REST (Axios or Fetch to backend endpoints) |
| *Icons* | Bootstrap Icons / Font Awesome |
| *Payment Integration* | Paystack Inline / Redirect Flow |

---

## 🗂 Folder Structure              ---

## ⚙ Key Pages

### 🏠 1. *Home Page (index.html)*
- Shows all vendors (20 total)
- Each card → opens vendor product list

### 🏪 2. *Vendor Page (vendor.html)*
- Lists vendor’s products (food, drinks, items, etc.)
- “Add to Cart” button for each
- “View Cart” → Checkout

### 💳 3. *Checkout Page (checkout.html)*
- Fields:
  - Phone number
  - Seat/Ticket ID
- Summary of order + ₦100 service fee
- Paystack payment button
- Redirect to confirmation page

### 🚚 4. *Order Tracking (track.html)*
- Shows consumer order status:
  - Pending → Accepted → Preparing → Ready → Out for Delivery → Delivered
- Displays seat number and QR code for dispatcher scanning

### 👷 5. *Dispatcher Dashboard (dispatcher.html)*
- Shows all ready orders (fetched from backend)
- “Claim Order” button → assigns to dispatcher
- “Mark Delivered” → QR code validation + delivery confirmation

### 🧑‍💼 6. *Admin Dashboard (admin.html)*
- View total sales, vendors, and active orders
- View service charge collection summary
- Export summary for vendor payout

---

## 🔗 Backend API Integration
All API calls will connect to the event backend:    to assist yiou further, | Function | Endpoint | Method |
|-----------|-----------|--------|
| List Vendors | /vendors | GET |
| Vendor Products | /vendors/:id/products | GET |
| Create Order | /orders | POST |
| Track Order | /orders/:id | GET |
| Verify Payment | /paystack/verify?reference=... | GET |
| Dispatcher Claim Order | /dispatchers/claim | POST |
| Dispatcher Confirm Delivery | /dispatchers/confirm | POST |

---

## 💳 Paystack Integration (Frontend)
You’ll use *Paystack Inline JS* for payments:
```html
<script src="https://js.paystack.co/v1/inline.js"></script>
<script>
  function payNow() {
    let handler = PaystackPop.setup({
      key: 'pk_test_XXXXXXX', // From .env
      email: document.getElementById('email').value,
      amount: totalAmount * 100,
      metadata: {
        seat: seatNumber,
        phone: phoneNumber,
      },
      callback: function(response) {
        // Verify payment with backend
        verifyPayment(response.reference);
      },
      onClose: function() {
        alert('Payment cancelled');
      }
    });
    handler.openIframe();
  }
</script>
```