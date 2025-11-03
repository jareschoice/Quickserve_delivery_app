// ===============================
// FILE: backend/src/routes/notification.routes.js
// ===============================
import express from "express";
import {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  broadcastMessage,
} from "../controllers/notificationController.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// 🔹 User notifications
router.get("/", authRequired(), getMyNotifications);
router.patch("/:id/read", authRequired(), markAsRead);
router.post("/mark-all", authRequired(), markAllAsRead);
router.delete("/:id", authRequired(), deleteNotification);

// 🔹 Admin broadcast
router.post("/broadcast", authRequired("admin"), broadcastMessage);

export default router;
