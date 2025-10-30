// ===============================
// 🌍 Load environment variables
// ===============================
import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import bodyParser from 'body-parser';
import mongoose from 'mongoose';
import './src/config/db.js'; // Mongo connection

import { createServer } from 'http';
import { Server as IOServer } from 'socket.io';

// ===============================
// 🧭 Route Imports
// ===============================
import authRoutes from './src/routes/authRoutes.js';
import vendorRoutes from './src/routes/vendorRoutes.js';
import riderRoutes from './src/routes/riderRoutes.js';
import orderRoutes from './src/routes/orderRoutes.js';
import paymentRoutes from './src/routes/paymentRoutes.js';
import emailRoutes from './src/routes/emailRoutes.js';

// New consolidated API (v2) under /api/*
import authV2 from './src/routes/auth.routes.js';
import productV2 from './src/routes/product.routes.js';
import orderV2 from './src/routes/order.routes.js';
import paymentV2 from './src/routes/payment.routes.js';
import webhookV2 from './src/routes/webhook.routes.js';
import vendorV2 from './src/routes/vendor.routes.js';
import riderV2 from './src/routes/rider.routes.js';
import adminV2 from './src/routes/admin.routes.js';
import subscriptionV2 from './src/routes/subscription.routes.js';
import kycV2 from './src/routes/kyc.routes.js';

// ===============================
// ⚙️ App Setup
// ===============================
const app = express();
const httpServer = createServer(app);

// ===============================
// 🔒 Middleware
// ===============================
app.use(helmet());
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  })
);
app.use(bodyParser.json({ limit: '5mb' }));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(morgan('dev')); // logs all requests

// ===============================
// 🧱 Static Files
// ===============================
app.use(express.static('public'));

// ===============================
// 🚀 Root + Health Check
// ===============================
app.get('/', (req, res) => {
  const mongoStatus =
    mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
  res.json({
    ok: true,
    service: 'QuickServe API',
    mongo: mongoStatus,
    uptime: process.uptime(),
    time: new Date().toISOString(),
  });
});

// ===============================
// 📦 API Routes
// ===============================
app.use('/auth', authRoutes);
app.use('/vendors', vendorRoutes);
app.use('/riders', riderRoutes);
app.use('/orders', orderRoutes);
app.use('/payments', paymentRoutes);
app.use('/api/email', emailRoutes);

// New API namespace
app.use('/api/auth', authV2);
app.use('/api/products', productV2);
app.use('/api/orders', orderV2);
app.use('/api/payments', paymentV2);
app.use('/api/paystack', webhookV2);
app.use('/api/vendors', vendorV2);
app.use('/api/riders', riderV2);
app.use('/api/admin', adminV2);
app.use('/api/subscriptions', subscriptionV2);
app.use('/api/kyc', kycV2);

// ===============================
// ❌ Error Handlers
// ===============================
app.use((req, res) => res.status(404).json({ error: 'Not found' }));
app.use((err, req, res, next) => {
  console.error('❌ Server Error:', err);
  res
    .status(500)
    .json({ error: 'Internal server error', detail: err.message });
});

// ===============================
// ⚡ Socket.IO Setup
// ===============================
const io = new IOServer(httpServer, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
  transports: ['websocket', 'polling'],
});

app.locals.io = io;
app.set('io', io);

// Log all socket events
io.on('connection', (socket) => {
  console.log(`🟢 Socket connected: ${socket.id}`);

  socket.emit('welcome', { message: 'Connected to QuickServe socket!' });

  socket.on('ping', () => {
    console.log('📡 Received ping from client');
    socket.emit('pong', { time: new Date().toISOString() });
  });

  socket.on('identify', (userId) => {
    if (userId) {
      socket.join(String(userId));
    }
  });

  socket.on('disconnect', () => {
    console.log(`🔴 Socket disconnected: ${socket.id}`);
  });
});

// ===============================
// 🚀 Start Server
// ===============================
const PORT = process.env.PORT || 5555;
const LOCAL_IP = process.env.LOCAL_IP || '192.168.174.104';

httpServer.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 QuickServe API running on http://0.0.0.0:${PORT}`);
  console.log(`📱 Access from phone: http://${LOCAL_IP}:${PORT}`);
  console.log('🧭 Waiting for connections...');
});
