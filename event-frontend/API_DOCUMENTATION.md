# 🔌 QuickServe Event Edition - API Documentation

Base URL: `http://localhost:5000/api/event`

---

## 📋 Table of Contents
1. [Authentication](#authentication)
2. [Consumer Endpoints](#consumer-endpoints)
3. [Vendor Endpoints](#vendor-endpoints)
4. [Dispatcher Endpoints](#dispatcher-endpoints)
5. [Admin Endpoints](#admin-endpoints)
6. [Data Models](#data-models)

---

## 🔐 Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "507f1f77bcf86cd799439011",
    "email": "user@example.com",
    "name": "User Name",
    "role": "vendor"
  }
}
```

---

## 🛒 Consumer Endpoints

### Get All Vendors
```http
GET /api/event/vendors
```

**Response:**
```json
{
  "success": true,
  "vendors": [
    {
      "_id": "507f1f77bcf86cd799439011",
      "name": "Vendor Name",
      "email": "vendor@example.com",
      "profile": {
        "businessName": "Business Name",
        "phone": "08012345678"
      }
    }
  ]
}
```

### Get Vendor Products
```http
GET /api/event/vendors/:vendorId/products
```

**Response:**
```json
{
  "success": true,
  "products": [
    {
      "_id": "507f1f77bcf86cd799439012",
      "name": "Product Name",
      "description": "Product description",
      "price": 1000,
      "category": "Food",
      "imageUrl": "https://example.com/image.jpg"
    }
  ]
}
```

### Create Order
```http
POST /api/event/orders
Content-Type: application/json

{
  "phone": "08012345678",
  "seatNumber": "A-123",
  "vendorId": "507f1f77bcf86cd799439011",
  "items": [
    {
      "name": "Product Name",
      "price": 1000,
      "qty": 2
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "_id": "507f1f77bcf86cd799439013",
    "phone": "08012345678",
    "seatNumber": "A-123",
    "total": 2100,
    "status": "pending"
  }
}
```

### Track Order
```http
GET /api/event/orders/:orderId
```

**Response:**
```json
{
  "success": true,
  "order": {
    "_id": "507f1f77bcf86cd799439013",
    "phone": "08012345678",
    "seatNumber": "A-123",
    "vendorId": {
      "name": "Vendor Name",
      "profile": {
        "businessName": "Business Name"
      }
    },
    "items": [
      {
        "name": "Product Name",
        "price": 1000,
        "qty": 2
      }
    ],
    "subtotal": 2000,
    "serviceCharge": 100,
    "total": 2100,
    "status": "preparing",
    "payment": {
      "paid": true,
      "reference": "QS-EVENT-123456"
    },
    "qrCode": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..."
  }
}
```

### Verify Payment
```http
POST /api/event/orders/verify-payment
Content-Type: application/json

{
  "reference": "QS-EVENT-123456",
  "orderId": "507f1f77bcf86cd799439013"
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "_id": "507f1f77bcf86cd799439013",
    "payment": {
      "paid": true,
      "reference": "QS-EVENT-123456",
      "verifiedAt": "2025-11-03T10:30:00.000Z"
    }
  }
}
```

---

## 🏪 Vendor Endpoints

**All vendor endpoints require authentication with vendor role.**

### Get Vendor Orders
```http
GET /api/event/vendor/orders
Authorization: Bearer <vendor_token>
```

**Response:**
```json
{
  "success": true,
  "orders": [
    {
      "_id": "507f1f77bcf86cd799439013",
      "phone": "08012345678",
      "seatNumber": "A-123",
      "items": [
        {
          "name": "Product Name",
          "price": 1000,
          "qty": 2
        }
      ],
      "subtotal": 2000,
      "serviceCharge": 100,
      "total": 2100,
      "status": "pending",
      "payment": {
        "paid": true
      },
      "createdAt": "2025-11-03T10:00:00.000Z"
    }
  ]
}
```

### Update Order Status
```http
PATCH /api/event/vendor/orders/:orderId/status
Authorization: Bearer <vendor_token>
Content-Type: application/json

{
  "status": "accepted"
}
```

**Valid statuses:** `accepted`, `preparing`, `ready`, `cancelled`

**Response:**
```json
{
  "success": true,
  "order": {
    "_id": "507f1f77bcf86cd799439013",
    "status": "accepted"
  }
}
```

### Get Vendor Earnings
```http
GET /api/event/vendor/earnings
Authorization: Bearer <vendor_token>
```

**Response:**
```json
{
  "success": true,
  "earnings": {
    "totalEarnings": 50000,
    "totalOrders": 25,
    "orders": [
      {
        "_id": "507f1f77bcf86cd799439013",
        "subtotal": 2000,
        "payment": {
          "paid": true
        }
      }
    ]
  }
}
```

---

## 🚴 Dispatcher Endpoints

**All dispatcher endpoints require authentication with dispatcher role.**

### Get Ready Orders
```http
GET /api/event/dispatcher/ready-orders
Authorization: Bearer <dispatcher_token>
```

**Response:**
```json
{
  "success": true,
  "orders": [
    {
      "_id": "507f1f77bcf86cd799439013",
      "phone": "08012345678",
      "seatNumber": "A-123",
      "vendorId": {
        "name": "Vendor Name",
        "profile": {
          "businessName": "Business Name"
        }
      },
      "items": [
        {
          "name": "Product Name",
          "price": 1000,
          "qty": 2
        }
      ],
      "total": 2100,
      "status": "ready"
    }
  ]
}
```

### Claim Order
```http
POST /api/event/dispatcher/claim
Authorization: Bearer <dispatcher_token>
Content-Type: application/json

{
  "orderId": "507f1f77bcf86cd799439013"
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "_id": "507f1f77bcf86cd799439013",
    "dispatcherId": "507f1f77bcf86cd799439014",
    "status": "out_for_delivery"
  }
}
```

### Confirm Delivery
```http
POST /api/event/dispatcher/confirm
Authorization: Bearer <dispatcher_token>
Content-Type: application/json

{
  "orderId": "507f1f77bcf86cd799439013",
  "qrToken": "a1b2c3d4e5f6..."
}
```

**Response:**
```json
{
  "success": true,
  "order": {
    "_id": "507f1f77bcf86cd799439013",
    "status": "delivered",
    "deliveryConfirmedAt": "2025-11-03T11:00:00.000Z"
  }
}
```

### Get Dispatcher Stats
```http
GET /api/event/dispatcher/stats
Authorization: Bearer <dispatcher_token>
```

**Response:**
```json
{
  "success": true,
  "stats": {
    "totalDeliveries": 15,
    "activeDeliveries": 2,
    "activeOrders": [
      {
        "_id": "507f1f77bcf86cd799439013",
        "seatNumber": "A-123",
        "vendorId": {
          "name": "Vendor Name"
        },
        "status": "out_for_delivery"
      }
    ]
  }
}
```

---

## 🧑‍💼 Admin Endpoints

**All admin endpoints require authentication with admin role.**

### Get All Orders
```http
GET /api/event/admin/orders
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "orders": [
    {
      "_id": "507f1f77bcf86cd799439013",
      "phone": "08012345678",
      "seatNumber": "A-123",
      "vendorId": {
        "name": "Vendor Name"
      },
      "dispatcherId": {
        "name": "Dispatcher Name"
      },
      "items": [...],
      "subtotal": 2000,
      "serviceCharge": 100,
      "total": 2100,
      "status": "delivered",
      "payment": {
        "paid": true,
        "reference": "QS-EVENT-123456"
      },
      "createdAt": "2025-11-03T10:00:00.000Z"
    }
  ]
}
```

### Get Event Summary
```http
GET /api/event/admin/summary
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "success": true,
  "summary": {
    "totalOrders": 500,
    "paidOrders": 480,
    "totalRevenue": 1050000,
    "totalServiceCharges": 48000,
    "totalVendorEarnings": 1002000,
    "vendorBreakdown": [
      {
        "vendorId": "507f1f77bcf86cd799439011",
        "vendorName": "Vendor Name",
        "totalOrders": 25,
        "totalEarnings": 50000
      }
    ]
  }
}
```

---

## 📊 Data Models

### EventOrder
```javascript
{
  _id: ObjectId,
  phone: String,
  seatNumber: String,
  vendorId: ObjectId (ref: User),
  dispatcherId: ObjectId (ref: User),
  items: [
    {
      name: String,
      price: Number,
      qty: Number
    }
  ],
  subtotal: Number,
  serviceCharge: Number (default: 100),
  total: Number,
  status: String (enum: ['pending', 'accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled']),
  deliveryConfirmationToken: String,
  deliveryConfirmedAt: Date,
  payment: {
    reference: String,
    paid: Boolean,
    channel: String,
    verifiedAt: Date
  },
  createdAt: Date,
  updatedAt: Date
}
```

### User (Vendor/Dispatcher/Admin)
```javascript
{
  _id: ObjectId,
  role: String (enum: ['customer', 'vendor', 'rider', 'admin', 'dispatcher']),
  email: String,
  password: String (hashed),
  name: String,
  isVerified: Boolean,
  profile: {
    phone: String,
    businessName: String (for vendors),
    businessAddress: String
  },
  wallet: Number,
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🔄 Order Status Flow

```
pending
  ↓ (vendor accepts)
accepted
  ↓ (vendor starts preparing)
preparing
  ↓ (vendor marks ready)
ready
  ↓ (dispatcher claims)
out_for_delivery
  ↓ (dispatcher confirms with QR)
delivered
```

Orders can be `cancelled` at `pending` or `accepted` stages.

---

## 🚨 Error Responses

All errors follow this format:

```json
{
  "success": false,
  "message": "Error description"
}
```

**Common HTTP Status Codes:**
- `200` - Success
- `400` - Bad Request (validation error)
- `401` - Unauthorized (missing or invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

---

## 🔔 Real-Time Events (Socket.IO)

The backend emits the following events via Socket.IO:

- `orderStatusUpdate` - When order status changes
- `orderClaimed` - When dispatcher claims an order
- `orderDelivered` - When order is delivered
- `paymentVerified` - When payment is confirmed

**Client-side connection:**
```javascript
const socket = io('http://localhost:5000');

socket.on('orderStatusUpdate', (data) => {
  console.log('Order status updated:', data);
});
```

---

## 📝 Notes

1. All timestamps are in ISO 8601 format (UTC)
2. Currency amounts are in Naira (₦)
3. Service charge is fixed at ₦100 per order
4. QR codes are returned as base64-encoded data URLs
5. Phone numbers should be in Nigerian format (08xxxxxxxxx)

---

For more information, see [SETUP_GUIDE.md](SETUP_GUIDE.md)
