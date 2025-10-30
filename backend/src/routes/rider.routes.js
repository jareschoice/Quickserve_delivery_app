import express from "express";
import { authRequired } from "../middleware/auth.js";
import Order from "../models/Order.js";
import User from "../models/User.js";

const router = express.Router();

// Rider fetch assigned orders
router.get("/assigned", authRequired("rider"), async (req, res) => {
  const rider = await User.findById(req.user.id)
  if (!rider || rider.kycStatus !== 'approved') return res.status(403).json({ error: 'Rider KYC not approved' })
  const items = await Order.find({ riderId: req.user.id, status: { $in: ["assigned", "in_transit"] } }).sort({ createdAt: -1 });
  res.json({ items });
});

export default router;
