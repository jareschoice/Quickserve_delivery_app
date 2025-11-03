// ===============================
// FILE: backend/src/models/WithdrawRequest.js
// ===============================
import mongoose from "mongoose";

const withdrawRequestSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  amount: { type: Number, required: true },
  role: { type: String, enum: ["vendor", "rider"], required: true },
  method: { type: String, enum: ["bank", "wallet", "manual"], default: "bank" },

  bankDetails: {
    accountName: String,
    accountNumber: String,
    bankName: String,
  },

  status: {
    type: String,
    enum: ["pending", "approved", "rejected", "paid"],
    default: "pending",
  },

  approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
  approvedAt: { type: Date },
  paidAt: { type: Date },
  notes: String,

}, { timestamps: true });

export default mongoose.model("WithdrawRequest", withdrawRequestSchema);
