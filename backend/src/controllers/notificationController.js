// ===============================
// FILE: backend/src/controllers/notificationController.js
// ===============================
import Notification from "../models/Notification.js";
import User from "../models/User.js";
import { sendMail } from "../lib/email.js";

/**
 * ✅ Get logged-in user's notifications
 */
export const getMyNotifications = async (req, res) => {
  try {
    const items = await Notification.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(100);
    res.json({ success: true, items });
  } catch (err) {
    console.error("getMyNotifications error:", err);
    res.status(500).json({ error: "Failed to fetch notifications" });
  }
};

/**
 * ✅ Mark a single notification as read
 */
export const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const notif = await Notification.findOneAndUpdate(
      { _id: id, user: req.user._id },
      { read: true },
      { new: true }
    );
    if (!notif) return res.status(404).json({ error: "Notification not found" });
    res.json({ success: true, notif });
  } catch (err) {
    console.error("markAsRead error:", err);
    res.status(500).json({ error: "Failed to mark as read" });
  }
};

/**
 * ✅ Mark all notifications as read
 */
export const markAllAsRead = async (req, res) => {
  try {
    await Notification.updateMany({ user: req.user._id }, { read: true });
    res.json({ success: true, message: "All notifications marked as read" });
  } catch (err) {
    console.error("markAllAsRead error:", err);
    res.status(500).json({ error: "Failed to mark all as read" });
  }
};

/**
 * ✅ Delete a notification (optional)
 */
export const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    await Notification.deleteOne({ _id: id, user: req.user._id });
    res.json({ success: true, message: "Notification deleted" });
  } catch (err) {
    console.error("deleteNotification error:", err);
    res.status(500).json({ error: "Failed to delete notification" });
  }
};

/**
 * ✅ Admin broadcast message
 */
export const broadcastMessage = async (req, res) => {
  try {
    const { title, message, role } = req.body;
    if (!title || !message)
      return res.status(400).json({ error: "Title and message required" });

    const users = role
      ? await User.find({ role })
      : await User.find({});

    const notifs = [];
    for (const user of users) {
      notifs.push({
        user: user._id,
        title,
        message,
        type: "system",
        meta: { broadcast: true },
      });
    }

    // Insert all at once for performance
    await Notification.insertMany(notifs);

    // Optional: send broadcast email (for admins)
    try {
      await sendMail({
        to: process.env.EMAIL_USER,
        subject: `📢 Broadcast: ${title}`,
        html: `<p>${message}</p><p><small>Sent to ${role || "all"} users.</small></p>`,
      });
    } catch (mailErr) {
      console.warn("Broadcast email failed:", mailErr.message);
    }

    // Optional: socket push if connected
    try {
      const io = req.app.get("io");
      if (io) io.emit("notification:broadcast", { title, message, role });
    } catch (e) {
      console.warn("Socket broadcast failed:", e.message);
    }

    res.json({
      success: true,
      message: `Broadcast sent to ${role || "all"} (${users.length} users)`,
    });
  } catch (err) {
    console.error("broadcastMessage error:", err);
    res.status(500).json({ error: "Broadcast failed" });
  }
};
