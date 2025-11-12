# 🥇 QuickServe Event Edition - Setup Guide

## 📋 Prerequisites
- Node.js (v16 or higher)
- MongoDB Atlas account
- Paystack account (Test or Live)

---

## 🚀 Backend Setup

### 1. Navigate to Backend Directory
```bash
cd backend
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Configure Environment Variables
Create a `.env` file in the `backend` directory with the following:

```env
# Server Configuration
PORT=5000
NODE_ENV=development

# Database
MONGODB_URI=your_mongodb_atlas_connection_string

# JWT Secret
JWT_SECRET=your_super_secret_jwt_key_here

# Paystack API Keys
PAYSTACK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxx
PAYSTACK_PUBLIC_KEY=pk_test_xxxxxxxxxxxxxxxxxx

# Email Configuration (optional for event)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
EMAIL_FROM=QuickServe Event <noreply@quickserve.com>
```

### 4. Start the Backend Server
```bash
npm run dev
```

The backend API will be available at `http://localhost:5000`

---

## 🌐 Frontend Setup

### 1. Update API Configuration
Edit the `API_BASE_URL` in all JavaScript files (located in `event-frontend/js/`):

```javascript
const API_BASE_URL = 'http://localhost:5000/api/event';
```

For production, update to your deployed backend URL:
```javascript
const API_BASE_URL = 'https://your-backend-domain.com/api/event';
```

### 2. Update Paystack Public Key
Edit `event-frontend/js/checkout.js` and replace the placeholder with your actual Paystack public key:

```javascript
const PAYSTACK_PUBLIC_KEY = 'pk_test_xxxxxxxxx'; // Replace with your key
```

### 3. Serve the Frontend
You can use any static file server. Options include:

#### Option A: Using Python (if installed)
```bash
cd event-frontend
python -m http.server 8080
```

#### Option B: Using Node.js http-server
```bash
npm install -g http-server
cd event-frontend
http-server -p 8080
```

#### Option C: Using Live Server (VS Code Extension)
- Install the "Live Server" extension in VS Code
- Right-click on `index.html` and select "Open with Live Server"

The frontend will be available at `http://localhost:8080`

---

## 👥 User Account Setup

### 1. Create Admin Account
Use the existing `backend/create-admin.js` script or create via API:

```bash
cd backend
node create-admin.js
```

### 2. Create Vendor Accounts (20 vendors)
Create a script or use API endpoint to register vendors:

```javascript
POST /api/auth/register
{
  "email": "vendor1@event.com",
  "password": "SecurePass123",
  "name": "Vendor Name",
  "role": "vendor",
  "profile": {
    "businessName": "Business Name",
    "phone": "08012345678"
  }
}
```

### 3. Create Dispatcher Accounts
Register dispatchers using the API:

```javascript
POST /api/auth/register
{
  "email": "dispatcher1@event.com",
  "password": "SecurePass123",
  "name": "Dispatcher Name",
  "role": "dispatcher",
  "profile": {
    "phone": "08012345678"
  }
}
```

### 4. Add Products for Each Vendor
Vendors can add products via API or admin panel:

```javascript
POST /api/products
Authorization: Bearer <vendor_token>
{
  "name": "Product Name",
  "description": "Product description",
  "price": 1000,
  "category": "Food",
  "available": true
}
```

---

## 🎯 Event Day Flow

### For Consumers (Event Attendees)
1. Visit the event website: `http://your-domain.com`
2. Browse vendors and products
3. Add items to cart
4. Checkout with phone number and seat/ticket ID
5. Pay via Paystack
6. Receive order confirmation with QR code
7. Track order status in real-time

### For Vendors
1. Login at vendor dashboard: `http://your-domain.com/vendor-dashboard.html`
2. View incoming orders
3. Accept orders
4. Update status: Preparing → Ready
5. Monitor earnings in real-time

### For Dispatchers
1. Login at dispatcher dashboard: `http://your-domain.com/dispatcher.html`
2. View ready orders
3. Claim an order
4. Deliver to customer's seat
5. Scan QR code to confirm delivery

### For Admin
1. Login at admin dashboard: `http://your-domain.com/admin.html`
2. Monitor all orders in real-time
3. Track vendor earnings
4. View service charge collection
5. Generate payout reports

---

## 🔧 API Endpoints Reference

### Public Endpoints (No Auth Required)
- `GET /api/event/vendors` - List all vendors
- `GET /api/event/vendors/:vendorId/products` - Get vendor products
- `POST /api/event/orders` - Create order
- `GET /api/event/orders/:orderId` - Track order
- `POST /api/event/orders/verify-payment` - Verify payment

### Vendor Endpoints (Require Vendor Auth)
- `GET /api/event/vendor/orders` - Get vendor's orders
- `PATCH /api/event/vendor/orders/:orderId/status` - Update order status
- `GET /api/event/vendor/earnings` - Get earnings summary

### Dispatcher Endpoints (Require Dispatcher Auth)
- `GET /api/event/dispatcher/ready-orders` - Get ready orders
- `POST /api/event/dispatcher/claim` - Claim an order
- `POST /api/event/dispatcher/confirm` - Confirm delivery
- `GET /api/event/dispatcher/stats` - Get dispatcher stats

### Admin Endpoints (Require Admin Auth)
- `GET /api/event/admin/orders` - Get all orders
- `GET /api/event/admin/summary` - Get event summary

---

## 📱 Testing the System

### 1. Test Order Flow
- Create a test order as a consumer
- Accept it as a vendor
- Mark it as ready
- Claim it as a dispatcher
- Confirm delivery

### 2. Test Payment Integration
- Use Paystack test cards:
  - Success: `4084084084084081`
  - Declined: `4084084084084084`

### 3. Test Real-Time Updates
- Open multiple browser windows
- Perform actions in one window
- Verify updates appear in other windows

---

## 🔒 Security Checklist

- [ ] Change default JWT_SECRET
- [ ] Use strong passwords for all accounts
- [ ] Enable HTTPS in production
- [ ] Set up CORS properly
- [ ] Use environment variables for sensitive data
- [ ] Test Paystack webhook security
- [ ] Implement rate limiting for API endpoints
- [ ] Set up database backups

---

## 🚨 Troubleshooting

### Backend won't start
- Check MongoDB connection string
- Verify all environment variables are set
- Check if port 5000 is already in use

### Frontend can't connect to backend
- Verify API_BASE_URL is correct
- Check CORS settings in backend
- Ensure backend is running

### Paystack payment not working
- Verify public key is correct
- Check if using test key in development
- Ensure backend webhook URL is configured

### Real-time updates not working
- Check Socket.IO connection
- Verify CORS settings for Socket.IO
- Check browser console for errors

---

## 📞 Support

For issues during the event:
- Backend logs: Check terminal running the server
- Frontend errors: Check browser console (F12)
- Database issues: Check MongoDB Atlas dashboard

---

## 🎉 Event Day Checklist

### Pre-Event (1 day before)
- [ ] All 20 vendors registered and verified
- [ ] All vendor products uploaded
- [ ] All dispatchers registered
- [ ] Admin account working
- [ ] Test complete order flow
- [ ] Verify Paystack live keys
- [ ] Set up production database
- [ ] Deploy backend to production server
- [ ] Deploy frontend to hosting service
- [ ] Test on multiple devices
- [ ] Backup database

### Event Day
- [ ] Monitor server performance
- [ ] Track order volume
- [ ] Support vendors and dispatchers
- [ ] Monitor payment success rate
- [ ] Keep admin dashboard open
- [ ] Have backup internet connection

### Post-Event
- [ ] Export all order data
- [ ] Calculate vendor payouts
- [ ] Generate financial reports
- [ ] Backup event database
- [ ] Send thank you to vendors and dispatchers

---

## 📊 Expected Performance

- **Orders per minute**: Up to 100
- **Concurrent users**: 5,000+
- **Database**: MongoDB Atlas (M10+ recommended)
- **Backend**: 2GB RAM minimum
- **Response time**: < 500ms for API calls

Good luck with your world record event! 🎯🥇
