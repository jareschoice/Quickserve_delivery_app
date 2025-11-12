# 🥇 QuickServe Event Edition - Backend

This is the backend API for the QuickServe Event Edition, a one-day ordering and logistics platform for a world record event with 20,000+ participants and 20 vendors.

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Create a `.env` file:
```env
PORT=5000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxx
```

### 3. Create Test Data
```bash
node create-event-test-data.js
```

This will create:
- 20 test vendors (vendor1@event.test to vendor20@event.test)
- Products for each vendor
- 10 test dispatchers (dispatcher1@event.test to dispatcher10@event.test)

**Default password for all test accounts:** `password123`

### 4. Start the Server
```bash
npm run dev
```

The API will be available at `http://localhost:5000`

## 📋 API Endpoints

### Public (No Auth)
- `GET /api/event/vendors` - List all vendors
- `GET /api/event/vendors/:id/products` - Get vendor products
- `POST /api/event/orders` - Create order
- `GET /api/event/orders/:id` - Track order
- `POST /api/event/orders/verify-payment` - Verify payment

### Vendor (Requires Auth)
- `GET /api/event/vendor/orders` - Get vendor orders
- `PATCH /api/event/vendor/orders/:id/status` - Update order status
- `GET /api/event/vendor/earnings` - Get earnings summary

### Dispatcher (Requires Auth)
- `GET /api/event/dispatcher/ready-orders` - Get orders ready for pickup
- `POST /api/event/dispatcher/claim` - Claim an order
- `POST /api/event/dispatcher/confirm` - Confirm delivery with QR
- `GET /api/event/dispatcher/stats` - Get delivery stats

### Admin (Requires Auth)
- `GET /api/event/admin/orders` - Get all orders
- `GET /api/event/admin/summary` - Get event summary

## 🔐 Authentication

Login to get JWT token:
```bash
POST /api/auth/login
{
  "email": "vendor1@event.test",
  "password": "password123"
}
```

Use the token in subsequent requests:
```
Authorization: Bearer <your_token>
```

## 🧪 Testing

### Test with cURL
```bash
# Get vendors
curl http://localhost:5000/api/event/vendors

# Create order
curl -X POST http://localhost:5000/api/event/orders \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "08012345678",
    "seatNumber": "A-123",
    "vendorId": "YOUR_VENDOR_ID",
    "items": [
      {"name": "Jollof Rice", "price": 1500, "qty": 2}
    ]
  }'
```

### Test with the Frontend
1. Open the `event-frontend` in a browser
2. Browse vendors and products
3. Place a test order
4. Login as vendor to manage orders
5. Login as dispatcher to claim and deliver

## 📊 Database Models

### EventOrder
- Stores all event orders with seat numbers
- Includes QR token for delivery verification
- Tracks payment status via Paystack

### User (Extended)
- Added `dispatcher` role for event staff
- Vendor wallet tracks earnings

### Product
- Links to vendor
- Standard product information

## 🔄 Order Flow

```
pending → accepted → preparing → ready → out_for_delivery → delivered
```

## 💳 Payment Integration

- All payments via Paystack
- ₦100 service charge per order
- Vendor earnings tracked in wallet
- Admin receives all payments

## 🎯 Event Day Usage

1. **Pre-event:** Create vendors and products using the test data script
2. **During event:** Consumers order via website
3. **Vendors:** Accept and prepare orders
4. **Dispatchers:** Claim and deliver ready orders
5. **Admin:** Monitor all activity in real-time

## 📁 File Structure

```
backend/
├── src/
│   ├── models/
│   │   └── EventOrder.js          # Event-specific order model
│   ├── controllers/
│   │   └── eventController.js     # All event endpoints
│   ├── routes/
│   │   └── event.routes.js        # Event API routes
│   └── middleware/
│       └── auth.js                # Auth with dispatcher role
├── create-event-test-data.js      # Test data generator
└── server.js                      # Main entry point
```

## 🛠 Development Tips

- Use MongoDB Compass to view data
- Check logs for Socket.IO events
- Use Postman for API testing
- Monitor Paystack dashboard for payments

## 🚨 Troubleshooting

**Port already in use:**
```bash
# Kill process on port 5000
npx kill-port 5000
```

**MongoDB connection error:**
- Check your MongoDB URI
- Ensure IP is whitelisted in MongoDB Atlas

**Socket.IO not working:**
- Check CORS settings
- Verify frontend URL in CORS config

## 📚 Documentation

- [Full API Documentation](../event-frontend/API_DOCUMENTATION.md)
- [Setup Guide](../event-frontend/SETUP_GUIDE.md)
- [Frontend README](../event-frontend/README.md)

## 🎉 Ready for Production?

1. Update `.env` with production values
2. Use Paystack live keys
3. Set up MongoDB Atlas production cluster
4. Deploy to a cloud service (Heroku, Railway, etc.)
5. Configure domain and SSL
6. Test the complete flow
7. Monitor performance on event day

Good luck with your world record event! 🥇
