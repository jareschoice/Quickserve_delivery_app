// ===============================
// FILE: backend/src/models/Review.js
// Customer reviews after delivery
// ===============================
import mongoose from "mongoose";

const ReviewSchema = new mongoose.Schema(
  {
    // 🔹 Order Information
    order: { type: mongoose.Schema.Types.ObjectId, ref: "Order", required: true },
    customer: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    
    // 🔹 Ratings (1-5 stars)
    overallRating: { type: Number, required: true, min: 1, max: 5 },
    foodRating: { type: Number, min: 1, max: 5 },
    deliveryRating: { type: Number, min: 1, max: 5 },
    
    // 🔹 Review Content
    comment: { type: String, maxlength: 1000 },
    
    // 🔹 Related Entities
    vendor: { type: mongoose.Schema.Types.ObjectId, ref: "Vendor" },
    dispatcher: { type: mongoose.Schema.Types.ObjectId, ref: "Dispatcher" },
    
    // 🔹 Admin Management
    readByAdmin: { type: Boolean, default: false },
    respondedByAdmin: { type: Boolean, default: false },
    adminResponse: String,
    
    // 🔹 Moderation
    isPublic: { type: Boolean, default: true },
    isFlagged: { type: Boolean, default: false },
    flagReason: String,
    
    // 🔹 Metadata
    deviceInfo: String,
    ipAddress: String
  },
  { timestamps: true }
);

// Index for admin inbox queries
ReviewSchema.index({ readByAdmin: 1, createdAt: -1 });
ReviewSchema.index({ vendor: 1, createdAt: -1 });
ReviewSchema.index({ dispatcher: 1, createdAt: -1 });

export default mongoose.model("Review", ReviewSchema);
