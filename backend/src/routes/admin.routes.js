import express from "express";
import { authRequired } from "../middleware/auth.js";
import Order from "../models/Order.js";
import Vendor from "../models/Vendor.js";
import User from "../models/User.js";
import Transaction from "../models/Transaction.js";
import Product from "../models/Product.js";

const router = express.Router();

// Get all users
router.get("/users", authRequired("admin"), async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    res.json({ users });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all vendors with populated user data
router.get("/vendors", authRequired("admin"), async (req, res) => {
  try {
    const vendors = await Vendor.find().populate('user', '-password');
    res.json({ vendors });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all orders with populated data
router.get("/orders", authRequired("admin"), async (req, res) => {
  try {
    const orders = await Order.find()
      .populate('customer', 'name email')
      .populate('vendor', 'storeName')
      .populate('riderId', 'name email')
      .sort({ createdAt: -1 });
    res.json({ orders });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all products
router.get("/products", authRequired("admin"), async (req, res) => {
  try {
    const products = await Product.find().populate({
      path: 'vendorId',
      populate: { path: 'user', select: 'name email' }
    });
    res.json({ products });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get("/stats", authRequired("admin"), async (req, res) => {
  const [orders, vendors, riders, customers, adminFees] = await Promise.all([
    Order.countDocuments({}),
    Vendor.countDocuments({}),
    User.countDocuments({ role: "rider" }),
    User.countDocuments({ role: "customer" }),
    Transaction.aggregate([
      { $match: { type: 'credit', 'meta.kind': 'admin_fee' } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ])
  ]);
  res.json({ orders, vendors, riders, customers, adminFees: adminFees?.[0]?.total || 0 });
});

// KYC review endpoints
router.post('/kyc/:userId/approve', authRequired('admin'), async (req, res) => {
  const u = await User.findById(req.params.userId)
  if (!u) return res.status(404).json({ error: 'User not found' })
  u.kycStatus = 'approved'
  u.kycReviewedAt = new Date()
  await u.save()
  res.json({ user: u })
})

router.post('/kyc/:userId/reject', authRequired('admin'), async (req, res) => {
  const u = await User.findById(req.params.userId)
  if (!u) return res.status(404).json({ error: 'User not found' })
  u.kycStatus = 'rejected'
  u.kycReviewedAt = new Date()
  await u.save()
  res.json({ user: u })
})

export default router;
