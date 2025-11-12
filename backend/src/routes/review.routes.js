// ===============================
// FILE: backend/src/routes/review.routes.js
// Customer review system
// ===============================
import express from "express";
import Review from "../models/Review.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// Submit review after delivery
router.post("/", authRequired("customer"), async (req, res) => {
  try {
    const { 
      orderId, 
      overallRating, 
      foodRating, 
      deliveryRating, 
      comment,
      vendorId,
      dispatcherId
    } = req.body;
    
    if (!orderId || !overallRating) {
      return res.status(400).json({ error: "Order ID and overall rating are required" });
    }
    
    // Check if review already exists
    const existing = await Review.findOne({ order: orderId });
    if (existing) {
      return res.status(400).json({ error: "You have already reviewed this order" });
    }
    
    // Create review
    const review = await Review.create({
      order: orderId,
      customer: req.user.id,
      overallRating,
      foodRating,
      deliveryRating,
      comment,
      vendor: vendorId,
      dispatcher: dispatcherId,
      ipAddress: req.ip || req.connection.remoteAddress
    });
    
    // Update vendor and dispatcher ratings
    if (vendorId) {
      const Vendor = require("../models/Vendor.js").default;
      const vendor = await Vendor.findById(vendorId);
      if (vendor) {
        const reviews = await Review.find({ vendor: vendorId });
        const avgRating = reviews.reduce((sum, r) => sum + r.foodRating, 0) / reviews.length;
        vendor.averageRating = avgRating;
        vendor.totalRatings = reviews.length;
        await vendor.save();
      }
    }
    
    if (dispatcherId) {
      const Dispatcher = require("../models/Dispatcher.js").default;
      const dispatcher = await Dispatcher.findById(dispatcherId);
      if (dispatcher) {
        const reviews = await Review.find({ dispatcher: dispatcherId });
        const avgRating = reviews.reduce((sum, r) => sum + r.deliveryRating, 0) / reviews.length;
        dispatcher.averageRating = avgRating;
        dispatcher.totalRatings = reviews.length;
        await dispatcher.save();
      }
    }
    
    // Notify admin via Socket.IO
    const io = req.app.get('io');
    if (io) {
      io.to('admin').emit('new_review', {
        reviewId: review._id,
        rating: overallRating,
        comment: comment?.substring(0, 100)
      });
    }
    
    res.json({ 
      success: true, 
      review,
      message: "Thank you for your feedback!" 
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get reviews for admin inbox
router.get("/admin/inbox", authRequired("admin"), async (req, res) => {
  try {
    const { unreadOnly } = req.query;
    
    const query = unreadOnly === 'true' ? { readByAdmin: false } : {};
    
    const reviews = await Review.find(query)
      .populate('customer', 'name email')
      .populate('vendor', 'storeName')
      .populate('dispatcher', 'name')
      .populate('order', 'orderNumber totalAmount')
      .sort({ createdAt: -1 })
      .limit(100);
    
    const unreadCount = await Review.countDocuments({ readByAdmin: false });
    
    res.json({ reviews, unreadCount });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Mark review as read
router.post("/:id/mark-read", authRequired("admin"), async (req, res) => {
  try {
    const review = await Review.findByIdAndUpdate(
      req.params.id,
      { readByAdmin: true },
      { new: true }
    );
    
    res.json({ success: true, review });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Admin respond to review
router.post("/:id/respond", authRequired("admin"), async (req, res) => {
  try {
    const { response } = req.body;
    
    const review = await Review.findByIdAndUpdate(
      req.params.id,
      { 
        adminResponse: response,
        respondedByAdmin: true,
        readByAdmin: true
      },
      { new: true }
    );
    
    res.json({ success: true, review });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get vendor reviews (public)
router.get("/vendor/:vendorId", async (req, res) => {
  try {
    const reviews = await Review.find({ 
      vendor: req.params.vendorId,
      isPublic: true
    })
    .populate('customer', 'name')
    .select('-ipAddress -readByAdmin')
    .sort({ createdAt: -1 })
    .limit(20);
    
    const avgRating = reviews.length > 0 
      ? reviews.reduce((sum, r) => sum + r.overallRating, 0) / reviews.length 
      : 0;
    
    res.json({ reviews, averageRating: avgRating.toFixed(1), totalReviews: reviews.length });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
