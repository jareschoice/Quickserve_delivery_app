// ===============================
// FILE: backend/src/models/Vendor.js
// ===============================
import mongoose from "mongoose";

const VendorSchema = new mongoose.Schema(
  {
    // 🔹 Linked User
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },

    // 🔹 Unique Vendor ID (e.g., VEN-001, VEN-002)
    vendorId: { type: String, unique: true, sparse: true }, // Generated on creation
    
    // 🔹 Owner Information
    ownerName: String, // Real name of the vendor owner

    // 🔹 Basic business info
    storeName: { type: String, required: false },
    businessName: String, // Alias for storeName (backward compatibility)
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
    isApproved: { type: Boolean, default: false }, // Admin approval
    availabilityStatus: { 
      type: String, 
      enum: ['open', 'closed', 'busy'], 
      default: 'open' 
    },
    businessPhone: String, // Additional phone field
  },
  { timestamps: true }
);

// Pre-save hook to generate unique vendorId
VendorSchema.pre('save', async function(next) {
  if (!this.vendorId) {
    // Get the last vendor ID to ensure proper incrementing
    const lastVendor = await mongoose.model('Vendor').findOne().sort({ vendorId: -1 });
    let nextNumber = 1;
    if (lastVendor && lastVendor.vendorId) {
      const lastNumber = parseInt(lastVendor.vendorId.split('-')[1]);
      nextNumber = lastNumber + 1;
    }
    this.vendorId = `VEN-${String(nextNumber).padStart(4, '0')}`; // VEN-0001, VEN-0002, etc.
  }
  // Sync businessName with storeName
  if (this.storeName && !this.businessName) {
    this.businessName = this.storeName;
  }
  next();
});

// ✅ Export properly
export default mongoose.model("Vendor", VendorSchema);
