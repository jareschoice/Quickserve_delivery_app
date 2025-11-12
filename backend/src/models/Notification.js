// ===============================
// FILE: backend/src/models/Notification.js
// ===============================
import mongoose from "mongoose";

const NotificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true },
    message: { type: String, required: true },
    type: {
      type: String,
      enum: [
        "order",
        "wallet",
        "refund",
        "system",
        "support",
        "kyc",
        "rider",
        "admin",
      ],
      default: "system",
    },
    read: { type: Boolean, default: false },
    readAt: { type: Date },
    meta: { type: Object, default: {} },
  },
  { timestamps: true }
);

NotificationSchema.index({ user: 1, createdAt: -1 }); // speed up queries

export default mongoose.model("Notification", NotificationSchema);
