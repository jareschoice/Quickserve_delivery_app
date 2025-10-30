import express from "express";
import http from "http";
import { Server as SocketIOServer } from "socket.io";
import dotenv from "dotenv";
import cors from "cors";
import morgan from "morgan";
import bodyParser from "body-parser";
import { connectDB } from "./lib/db.js";
import authRoutes from "./routes/auth.routes.js";
import productRoutes from "./routes/product.routes.js";
import orderRoutes from "./routes/order.routes.js";
import paymentRoutes from "./routes/payment.routes.js";
import webhookRoutes from "./routes/webhook.routes.js";
import subscriptionRoutes from "./routes/subscription.routes.js";
import kycRoutes from "./routes/kyc.routes.js";
import vendorRoutes from "./routes/vendor.routes.js";
import riderRoutes from "./routes/rider.routes.js";
import adminRoutes from "./routes/admin.routes.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(morgan("dev"));
app.use(bodyParser.json({ limit: "5mb" }));
app.use(bodyParser.urlencoded({ extended: true }));

// Health
app.get("/", (req, res) => {
  res.json({ ok: true, service: "quickserve-backend", time: new Date().toISOString() });
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/products", productRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/payments", paymentRoutes);
app.use("/api/paystack", webhookRoutes); // /webhook inside
app.use("/api/vendors", vendorRoutes);
app.use("/api/riders", riderRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/subscriptions", subscriptionRoutes);
app.use("/api/kyc", kycRoutes);

// Start
const PORT = process.env.PORT || 5000;
connectDB().then(() => {
  const server = http.createServer(app);
  const io = new SocketIOServer(server, { cors: { origin: '*'} });
  app.set('io', io);

  io.on('connection', (socket) => {
    // Clients can join a room equal to their userId to receive events
    socket.on('identify', (userId) => {
      if (userId) socket.join(String(userId));
    });
  });

  // Simple scheduler to check active subscriptions once per minute and emit notifications
  setInterval(async () => {
    try {
      const now = new Date()
      const Subscription = (await import('./models/Subscription.js')).default
      const subs = await Subscription.find({ status: 'active' })
      for (const s of subs) {
        // if within the minute of scheduled time, notify user
        const [hh, mm] = (s.deliveryTimeDaily||'12:00').split(':').map(n=>parseInt(n,10))
        const shouldNotify = now.getHours() === hh && now.getMinutes() === mm
        if (shouldNotify) {
          io.to(String(s.user)).emit('subscription:delivery', { subscriptionId: s._id, plan: s.plan })
        }
      }
    } catch (e) {
      console.warn('Subscription scheduler error:', e.message)
    }
  }, 60 * 1000)

  server.listen(PORT, () => {
    console.log(`🚀 QuickServe API running on http://localhost:${PORT}`);
  });
}).catch((err) => {
  console.error("❌ DB connection failed:", err.message);
});
