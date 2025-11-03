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

  // ✅ Enhanced scheduler: Check active subscriptions every minute for breakfast, lunch, dinner deliveries
  setInterval(async () => {
    try {
      const now = new Date()
      const currentHour = now.getHours()
      const currentMinute = now.getMinutes()
      const todayDate = now.toDateString() // To avoid duplicate notifications on same day
      
      const Subscription = (await import('./models/Subscription.js')).default
      const User = (await import('./models/User.js')).default
      
      const activeSubs = await Subscription.find({ status: 'active' }).populate('user')
      
      // Get all admin users for notifications
      const admins = await User.find({ role: 'admin' })
      
      for (const sub of activeSubs) {
        const { mealSchedule, lastDeliveryDate } = sub
        
        // Skip if already notified today
        if (lastDeliveryDate && new Date(lastDeliveryDate).toDateString() === todayDate) {
          continue
        }
        
        // Check breakfast schedule
        if (mealSchedule?.breakfast?.enabled) {
          const [hh, mm] = mealSchedule.breakfast.time.split(':').map(n => parseInt(n, 10))
          if (currentHour === hh && currentMinute === mm) {
            // Notify consumer
            io.to(String(sub.user._id)).emit('subscription:delivery', { 
              subscriptionId: sub._id, 
              plan: sub.plan,
              mealType: 'breakfast',
              scheduledTime: mealSchedule.breakfast.time,
              deliveryAddress: sub.deliveryAddress
            })
            
            // ✅ Notify ALL admins
            admins.forEach(admin => {
              io.to(String(admin._id)).emit('admin:subscription-delivery', {
                subscriptionId: sub._id,
                customer: sub.user.name,
                customerPhone: sub.user.phone,
                plan: sub.plan,
                mealType: 'breakfast',
                scheduledTime: mealSchedule.breakfast.time,
                deliveryAddress: sub.deliveryAddress,
                timestamp: new Date()
              })
            })
            
            console.log(`🍳 [SUBSCRIPTION] Breakfast delivery scheduled for ${sub.user.name} (${sub.plan})`)
          }
        }
        
        // Check lunch schedule
        if (mealSchedule?.lunch?.enabled) {
          const [hh, mm] = mealSchedule.lunch.time.split(':').map(n => parseInt(n, 10))
          if (currentHour === hh && currentMinute === mm) {
            io.to(String(sub.user._id)).emit('subscription:delivery', { 
              subscriptionId: sub._id, 
              plan: sub.plan,
              mealType: 'lunch',
              scheduledTime: mealSchedule.lunch.time,
              deliveryAddress: sub.deliveryAddress
            })
            
            admins.forEach(admin => {
              io.to(String(admin._id)).emit('admin:subscription-delivery', {
                subscriptionId: sub._id,
                customer: sub.user.name,
                customerPhone: sub.user.phone,
                plan: sub.plan,
                mealType: 'lunch',
                scheduledTime: mealSchedule.lunch.time,
                deliveryAddress: sub.deliveryAddress,
                timestamp: new Date()
              })
            })
            
            console.log(`🍱 [SUBSCRIPTION] Lunch delivery scheduled for ${sub.user.name} (${sub.plan})`)
          }
        }
        
        // Check dinner schedule
        if (mealSchedule?.dinner?.enabled) {
          const [hh, mm] = mealSchedule.dinner.time.split(':').map(n => parseInt(n, 10))
          if (currentHour === hh && currentMinute === mm) {
            io.to(String(sub.user._id)).emit('subscription:delivery', { 
              subscriptionId: sub._id, 
              plan: sub.plan,
              mealType: 'dinner',
              scheduledTime: mealSchedule.dinner.time,
              deliveryAddress: sub.deliveryAddress
            })
            
            admins.forEach(admin => {
              io.to(String(admin._id)).emit('admin:subscription-delivery', {
                subscriptionId: sub._id,
                customer: sub.user.name,
                customerPhone: sub.user.phone,
                plan: sub.plan,
                mealType: 'dinner',
                scheduledTime: mealSchedule.dinner.time,
                deliveryAddress: sub.deliveryAddress,
                timestamp: new Date()
              })
            })
            
            console.log(`🍽️ [SUBSCRIPTION] Dinner delivery scheduled for ${sub.user.name} (${sub.plan})`)
          }
        }
      }
    } catch (e) {
      console.warn('⚠️ Subscription scheduler error:', e.message)
    }
  }, 60 * 1000) // Run every minute

  server.listen(PORT, () => {
    console.log(`🚀 QuickServe API running on http://localhost:${PORT}`);
  });
}).catch((err) => {
  console.error("❌ DB connection failed:", err.message);
});
