// ===============================
// FILE: backend/src/routes/notification.routes.js
// ===============================
import express from "express";
import Notification from "../models/Notification.js";
import {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  broadcastMessage,
} from "../controllers/notificationController.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// List my notifications (includes unread count for UI badges)
router.get("/", authRequired(), async (req, res) => {
  const userId = req.user._id || req.user.id;
  const items = await Notification.find({ user: userId })
    .sort({ createdAt: -1 })
    .limit(100);
  const unread = await Notification.countDocuments({ user: userId, read: false });
  res.json({ items, unread });
});

// Mark one as read (POST to match existing frontend usage)
router.post("/:id/read", authRequired(), markAsRead);

// Mark all as read (POST to match existing frontend usage)
router.post("/read-all", authRequired(), markAllAsRead);

// Optional: delete a notification
router.delete("/:id", authRequired(), deleteNotification);

// Optional: admin broadcast
router.post("/broadcast", authRequired("admin"), broadcastMessage);

export default router;
