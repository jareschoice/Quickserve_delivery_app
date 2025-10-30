import express from "express";
import Order from "../models/Order.js";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import { adjustUserWallet, adjustVendorWallet } from "../utils/wallet.js";
import { signQrToken, verifyQrToken, generateQrPngBase64 } from "../utils/qr.js";
import { authRequired } from "../middleware/auth.js";
import { calculateDeliveryFee, quickserveFee } from "../utils/fare.js";
import { notifyAdmin } from "../utils/notify.js";

const router = express.Router();

// Create order (customer)
router.post("/", authRequired("customer"), async (req, res) => {
  try {
    const { vendorId, items, distanceKm: distanceKmClient = 0, deliveryAddress, origin, destination } = req.body;
    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(400).json({ error: "Vendor not found" });

    const subtotal = items.reduce((sum, it) => sum + Number(it.price) * Number(it.qty), 0);
    let distanceKm = Number(distanceKmClient) || 0;
    try {
      if (origin && destination) {
        const mod = await import('../utils/fare.js');
        distanceKm = await mod.getDistanceKm(origin, destination);
      }
    } catch {}
    const deliveryFee = calculateDeliveryFee(distanceKm);
    const qsFee = quickserveFee();
    const total = subtotal + deliveryFee + qsFee;

    const order = await Order.create({
      consumerId: req.user.id,
      vendorId: vendor._id,
      items,
      subtotal,
      deliveryFee,
      platformFee: qsFee,
      total,
      distanceKm,
      deliveryAddress,
      status: "placed"
    });

    res.json({ order });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Vendor accept/reject
router.post("/:id/accept", authRequired("vendor"), async (req, res) => {
  const vendorUser = await User.findById(req.user.id)
  if (!vendorUser || vendorUser.kycStatus !== 'approved') {
    return res.status(403).json({ error: 'Vendor KYC not approved' })
  }
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  order.status = "accepted";
  await order.save();
  const admin = await User.findOne({ role: 'admin' });
  if (admin) await adjustUserWallet(admin._id, 50, 'credit', { kind: 'admin_fee', stage: 'vendor_accept', order: order._id });
  // Debit vendor
  await adjustVendorWallet(req.user.id, 50, 'debit', { kind: 'service_charge', stage: 'vendor_accept', order: order._id });
  // Admin fee on vendor accept (₦50)
  await Transaction.create({ user: null, order: order._id, amount: 50, type: 'credit', meta: { kind: 'admin_fee', stage: 'vendor_accept' } });

  // Emit socket event if available
  try { req.app.get('io')?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status }); } catch {}
  res.json({ order });
});

// QR scan endpoint for double verification
router.post("/:id/scan", authRequired(), async (req, res) => {
  const { token } = req.body;
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  const role = req.user.role;
  try {
    if (role === 'customer') {
      verifyQrToken(token, order._id.toString(), 'rider'); // customer scans rider QR
      order.qrConsumerVerifiedAt = new Date();
    } else if (role === 'rider') {
      verifyQrToken(token, order._id.toString(), 'customer'); // rider scans customer QR
      order.qrRiderVerifiedAt = new Date();
    } else {
      return res.status(403).json({ error: 'Forbidden' });
    }

    if (order.qrConsumerVerifiedAt && order.qrRiderVerifiedAt) {
      order.status = 'delivered';
      await order.save();
      const admin = await User.findOne({ role: 'admin' });
      if (admin) await adjustUserWallet(admin._id, 50, 'credit', { kind: 'admin_fee', stage: 'rider_delivery', order: order._id });
      await adjustUserWallet(order.riderId, 50, 'debit', { kind: 'service_charge', stage: 'rider_delivery', order: order._id });
      try { req.app.get('io')?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status }); } catch {}
    } else {
      await order.save();
    }
    res.json({ order });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

router.post("/:id/reject", authRequired("vendor"), async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  order.status = "cancelled";
  await order.save();
  res.json({ order });
});

// Vendor update status (preparing)
router.post("/:id/status", authRequired("vendor"), async (req, res) => {
  const { status } = req.body;
  const valid = ["preparing"];
  if (!valid.includes(status)) return res.status(400).json({ error: "Invalid status" });
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  order.status = status;
  await order.save();
  try { req.app.get('io')?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status }); } catch {}
  res.json({ order });
});

// Vendor packs order and sets packaging choice; moves to waiting_pickup and charges admin fee (₦50)
router.post("/:id/pack", authRequired("vendor"), async (req, res) => {
  const { packagingChoice, packagingNotes } = req.body;
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  order.status = "waiting_pickup";
  if (packagingChoice) order.packagingChoice = packagingChoice;
  await order.save();
  try { req.app.get('io')?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status, packagingChoice }); } catch {}
  res.json({ order });
});

// Rider assignment (simple manual endpoint for now)
router.post("/:id/assign-rider", authRequired("vendor"), async (req, res) => {
  const vendorUser = await User.findById(req.user.id)
  if (!vendorUser || vendorUser.kycStatus !== 'approved') {
    return res.status(403).json({ error: 'Vendor KYC not approved' })
  }
  const { riderId } = req.body;
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  order.riderId = riderId;
  // Create double-scan QR tokens for consumer and rider
  const riderToken = signQrToken(order._id.toString(), 'rider');
  const consumerToken = signQrToken(order._id.toString(), 'customer');
  order.qrRiderToken = riderToken;
  order.qrConsumerToken = consumerToken;
  order.qrTokenExpiresAt = new Date(Date.now() + 1000 * 60 * 60);
  const { token, data } = createQrPayload(order._id.toString());
  const riderQr = await generateQrPngBase64(riderToken);
  const consumerQr = await generateQrPngBase64(consumerToken);

  // Notify all parties
  try {
    const io = req.app.get('io');
    io?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status, riderAssigned: true });
    io?.to(String(order.riderId)).emit('order:assigned', { id: order._id });
  } catch {}

  res.json({ order, riderQrBase64: riderQr, consumerQrBase64: consumerQr });
  const qrBase64 = await generateQrPngBase64(data);

  res.json({ order, qrBase64 }); // Rider app shows this QR
});

// Rider marks in_transit
router.post("/:id/in-transit", authRequired("rider"), async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  order.status = "in_transit";
  await order.save();
  res.json({ order });
});

// Consumer scans QR and confirms delivery
router.post("/:id/confirm-delivery", authRequired("customer"), async (req, res) => {
  const { token } = req.body;
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  if (order.status === "delivered") return res.json({ order }); // idempotent
  if (!order.qrToken || order.qrToken !== String(token)) return res.status(400).json({ error: "Invalid QR token" });
  if (order.qrTokenExpiresAt && order.qrTokenExpiresAt < new Date()) return res.status(400).json({ error: "QR expired" });

  order.status = "delivered";
  await order.save();

  // Notify admin
  await notifyAdmin(
    "Order Delivered ✔️",
    `<p>Order <b>${order._id}</b> has been delivered.</p>
     <p>QuickServe fee: ₦${order.platformFee}.</p>`
  );

  res.json({ order });
});

// Get my orders (for any role)
router.get("/mine", authRequired(), async (req, res) => {
  const role = req.user.role;
  const id = req.user.id;
  let q = {};
  if (role === "customer") q.consumerId = id;
  if (role === "vendor") {
    // Map vendor user -> Vendor document id
    const v = await Vendor.findOne({ user: id });
    if (v) q.vendorId = v._id; else q.vendorId = '__none__';
  }
  if (role === "rider") q.riderId = id;
  const items = await Order.find(q).sort({ createdAt: -1 });
  res.json({ items });
});

export default router;
