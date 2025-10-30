import express from "express";
import { authRequired } from "../middleware/auth.js";
import Order from "../models/Order.js";
import Vendor from "../models/Vendor.js";
import User from "../models/User.js";
import Transaction from "../models/Transaction.js";

const router = express.Router();

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

router.get("/orders", authRequired("admin"), async (req, res) => {
  const items = await Order.find({}).sort({ createdAt: -1 }).limit(200);
  res.json({ items });
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
