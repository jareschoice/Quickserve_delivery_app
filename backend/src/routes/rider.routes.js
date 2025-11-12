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
 
// Rider earnings summary (service charge per delivered order)
router.get('/earnings', authRequired('rider'), async (req, res) => {
  try {
    const fee = Number(process.env.DISPATCH_SERVICE_FEE || 50)
    const riderId = req.user.id
    const deliveredCount = await Order.countDocuments({ riderId, status: 'delivered' })
    const assignedCount = await Order.countDocuments({ riderId, status: { $in: ['assigned','in_transit'] } })
    const earnings = deliveredCount * fee
    res.json({ fee, deliveredCount, assignedCount, earnings })
  } catch (e) {
    res.status(500).json({ error: e.message })
  }
})

// Rider profile: get
router.get('/profile', authRequired('rider'), async (req, res) => {
  try {
    const u = await User.findById(req.user.id).select('-password');
    if (!u) return res.status(404).json({ error: 'User not found' });
    res.json({ user: u });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Rider profile: update (phone, vehicleType, plateNumber)
router.put('/profile', authRequired('rider'), async (req, res) => {
  try {
    const { phone, vehicleType, plateNumber, address } = req.body || {};
    const u = await User.findById(req.user.id).select('-password');
    if (!u) return res.status(404).json({ error: 'User not found' });
    u.profile = u.profile || {};
    if (phone !== undefined) u.profile.phone = phone;
    if (address !== undefined) u.profile.address = address;
    if (vehicleType !== undefined) u.profile.vehicleType = vehicleType;
    if (plateNumber !== undefined) u.profile.plateNumber = plateNumber;
    await u.save();
    res.json({ user: u });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Alias for convenience
router.get('/me', authRequired('rider'), async (req, res) => {
  const u = await User.findById(req.user.id).select('-password');
  if (!u) return res.status(404).json({ error: 'User not found' });
  res.json({ user: u });
});
