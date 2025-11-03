// ===============================
// FILE: backend/src/models/Notification.js
// ===============================
import mongoose from "mongoose";

const NotificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: {
      type: String,
      enum: ["order", "wallet", "refund", "system", "support", "kyc", "rider", "admin"],
      default: "system",
    },
    read: { type: Boolean, default: false },
    meta: { type: Object },
  },
  { timestamps: true }
);

NotificationSchema.index({ user: 1, createdAt: -1 }); // speed up queries

export default mongoose.model("Notification", NotificationSchema);
