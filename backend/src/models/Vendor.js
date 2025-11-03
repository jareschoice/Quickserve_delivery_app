// ===============================
// FILE: backend/src/models/Vendor.js
// ===============================
import mongoose from "mongoose";

const VendorSchema = new mongoose.Schema(
  {
    // 🔹 Linked User
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

    // 🔹 Basic business info
    storeName: { type: String, required: false },
    description: String,
    category: String,
    businessAddress: String,
    logoUrl: String,
    bannerUrl: String,
    phone: String,

    // 🔹 Wallet and transactions
    wallet: { type: Number, default: 0 },
    lastWithdrawAt: Date,

    // 🔹 KYC fields
    kycStatus: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },
    idUrl: String,
    utilityBillUrl: String,

    // 🔹 Bank and Paystack details
    bankName: String,
    bankCode: String,
    accountNumber: String,
    accountName: String,
    paystackRecipientCode: String, // ✅ Added for Paystack transfer recipient
    kycVerified: { type: Boolean, default: false }, // ✅ Quick flag to confirm verification

    // 🔹 System control
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// ✅ Export properly
export default mongoose.model("Vendor", VendorSchema);
