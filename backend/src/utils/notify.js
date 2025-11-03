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
      await sendMail({
        to: admin.email,
        subject,
        html,
      });
      // Emit to admin role room as well
      try {
        const io = globalThis.io;
        if (io) io.to(`role:admin`).emit("notification:admin", { subject, html, time: new Date() });
      } catch (e) {}
    }
  } catch (e) {
    console.error("Failed to notify admin:", e.message);
  }
};
