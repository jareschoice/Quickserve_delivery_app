// ===============================
// FILE: backend/src/models/Transaction.js
// ===============================
import mongoose from "mongoose";

const transactionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User" }, // who owns the wallet
  order: { type: mongoose.Schema.Types.ObjectId, ref: "Order" },
  amount: { type: Number, required: true },
  type: { type: String, enum: ["credit", "debit"], required: true },
  balanceAfter: { type: Number, default: 0 },

  // Metadata for context
  meta: {
    reason: { type: String },       // e.g. "order_delivery", "withdrawal", etc.
    stage: { type: String },        // e.g. "vendor_accept", "rider_delivery"
    via: { type: String, default: "system" }, // system, admin, user
  },

  reference: { type: String },
  status: { type: String, enum: ["success", "pending", "failed"], default: "success" },

}, { timestamps: true });

export default mongoose.model("Transaction", transactionSchema);
