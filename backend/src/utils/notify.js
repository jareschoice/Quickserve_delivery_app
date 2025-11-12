// Utility to send order-related notifications via Socket.IO
// Do not change existing socket rooms or application logic; this helper only emits
// structured notifications to known rooms: consumer (user id), order room, dispatchers_room, admin_room, vendor personal room.

export function sendOrderNotification(io, order, type, message) {
  if (!io || !order) return;

  try {
    const orderId = order._id ? String(order._id) : String(order);

    // Resolve consumer id robustly (could be populated object or id)
    const consumerId = order.consumerId ? (order.consumerId._id ? String(order.consumerId._id) : String(order.consumerId)) : null;
    const vendorUserId = order.vendor && order.vendor.user ? String(order.vendor.user) : (order.vendorId ? String(order.vendorId) : null);

    const payload = {
      orderId,
      type,
      message,
      timestamp: new Date(),
      order: {
        id: orderId,
        status: order.status
      }
    };

    // Primary notification to consumer (emit to multiple room keys used across the app)
    if (consumerId) {
      io.to(consumerId).emit('order:notification', payload);
      io.to(`user:${consumerId}`).emit('order:notification', payload);
    }
    // Emit to known order room conventions used in the project
    io.to(`order_${orderId}`).emit('order:notification', payload);
    io.to(`order:${orderId}`).emit('order:notification', payload);

    // Additional routing based on type
    if (type === 'ready') {
      // Notify dispatchers to pick up
      io.to('dispatchers_room').emit('order:ready', { ...payload, pickup: true });
      // Also notify vendor's personal room if available
      if (vendorUserId) {
        io.to(vendorUserId).emit('order:status', payload);
        io.to(`user:${vendorUserId}`).emit('order:status', payload);
      }
    } else if (type === 'accepted' || type === 'preparing') {
      // Notify consumer and vendor
      if (vendorUserId) io.to(vendorUserId).emit('order:status', payload);
    } else if (type === 'in_transit' || type === 'arrived' || type === 'delivered') {
      // Notify consumer and admin
      io.to('admin_room').emit('order:update', { ...payload });
    } else if (type === 'placed') {
      // Notify admin and dispatchers (if we want dispatchers to know about new orders)
      io.to('admin_room').emit('order:placed', { ...payload });
    }

    // Generic log for server-side visibility
    if (process && process.env && process.env.NODE_ENV !== 'test') {
      console.log(`Notification sent for order ${orderId}: ${type} -> ${message}`);
    }
  } catch (err) {
    console.error('sendOrderNotification error:', err && err.message ? err.message : err);
  }
}
// ===============================
// FILE: backend/src/utils/notify.js
// ===============================
import Notification from "../models/Notification.js";
import { sendMail } from "../lib/email.js";
import User from "../models/User.js";

/**
 * Send a general notification to a specific user
 * - Stores in DB
 * - Emits via socket.io (req.app.get('io') if provided, else globalThis.io)
 * - Sends email (if user.email exists)
 */
export async function sendNotification({
  userId,
  title,
  message,
  type = "system",
  meta = {},
  app, // optional
}) {
  try {
    // 1) Save to DB
    const notif = await Notification.create({
      user: userId,
      title,
      message,
      type,
      meta,
    });

    // 2) Emit via socket.io
    try {
      const io = app?.get?.("io") || app?.locals?.io || globalThis.io;
      if (io) {
        // Emit to several convenient rooms:
        // - personal: user:<id>
        // - plain id (legacy): <id>
        io.to(`user:${String(userId)}`).emit("notification:new", {
          id: notif._id,
          title,
          message,
          type,
          createdAt: notif.createdAt,
          meta,
        });
        io.to(String(userId)).emit("notification:new", {
          id: notif._id,
          title,
          message,
          type,
          createdAt: notif.createdAt,
          meta,
        });
      }
    } catch (socketErr) {
      console.warn("⚠️ Socket notification failed:", socketErr.message);
    }

    // 3) Email (best-effort)
    try {
      const user = await User.findById(userId);
      if (user?.email) {
        await sendMail({
          to: user.email,
          subject: title,
          html: `
            <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:20px;">
              <h3>${title}</h3>
              <p>${message}</p>
              <hr/>
              <small>QuickServe • getquickserves.com</small>
            </div>
          `,
        });
      }
    } catch (emailErr) {
      console.warn("⚠️ Email notify failed:", emailErr.message);
    }

    return notif;
  } catch (err) {
    console.error("❌ sendNotification error:", err);
    throw err;
  }
}

/**
 * Send an email alert to all admins (used for critical events)
 */
export const notifyAdmin = async (subject, html) => {
  try {
    const admins = await User.find({ role: "admin" });

    if (!admins.length && process.env.EMAIL_USER) {
      await sendMail({ to: process.env.EMAIL_USER, subject, html });
      return;
    }

    for (const admin of admins) {
      // Save as in-app notification
      try {
        await Notification.create({
          user: admin._id,
          title: subject,
          message: html?.replace(/<[^>]*>/g, '')?.slice(0, 500) || subject,
          type: 'admin',
          meta: { html },
        })
      } catch {}

      // Email
      try {
        await sendMail({ to: admin.email, subject, html });
      } catch {}

      // Socket emit
      try {
        const io = globalThis.io;
        if (io) {
          io.to(`role:admin`).emit("notification:admin", { subject, html, time: new Date() });
          io.to(`user:${String(admin._id)}`).emit('notification:new', { title: subject, message: subject })
        }
      } catch {}
    }
  } catch (e) {
    console.error("Failed to notify admin:", e.message);
  }
};
