import express from "express";
import Order from "../models/Order.js";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import { adjustUserWallet, adjustVendorWallet } from "../utils/wallet.js";
import { signQrToken, verifyQrToken, generateQrPngBase64 } from "../utils/qr.js";
import { authRequired } from "../middleware/auth.js";
import { blockUnpaidOrderCreation, requirePaidOrder } from "../middleware/paymentVerification.js";
import { calculateDeliveryFee, quickserveFee } from "../utils/fare.js";
import { notifyAdmin, sendNotification } from "../utils/notify.js";

const router = express.Router();

// ⚠️ BLOCK DIRECT ORDER CREATION - Orders must go through payment flow
// Use POST /api/payments/init-order-payment instead
router.post("/", authRequired("customer"), blockUnpaidOrderCreation);

// Vendor accept/reject
router.post("/:id/accept", authRequired("vendor"), async (req, res) => {
  // JWT token contains _id field, not id
  const userId = req.user._id || req.user.id;
  
  // TODO: Re-enable KYC check for production
  // const vendorUser = await User.findById(userId)
  // if (!vendorUser || vendorUser.kycStatus !== 'approved') {
  //   return res.status(403).json({ error: 'Vendor KYC not approved' })
  // }
  
  // Update order status directly without triggering full validation
  const order = await Order.findByIdAndUpdate(
    req.params.id,
    { 
      status: "accepted",
      acceptedAt: new Date()
    },
    { new: true }
  ).populate('consumerId', 'name phone');
  
  if (!order) return res.status(404).json({ error: "Not found" });
  
  // No vendor/admin wallet movements here under consumer-only service charge model

  // Emit socket event to customer
  try { 
    req.app.get('io')?.to(String(order.consumerId._id)).emit('order:update', { 
      id: order._id, 
      status: order.status,
      message: 'Vendor accepted your order!' 
    }); 
  } catch {}
  
  // Emit to vendor's own socket to trigger "Call Dispatcher" popup
  try {
    req.app.get('io')?.to(String(userId)).emit('order:accepted_show_dispatcher', {
      orderId: order._id,
      message: 'Order accepted! You can now call a dispatcher when ready.'
    });
  } catch {}
  
  try { 
    await sendNotification({ 
      userId: order.consumerId._id, 
      title: 'Order accepted 🎉', 
      message: 'Vendor accepted your order. Preparing your food...', 
      type: 'order', 
      meta: { orderId: order._id }, 
      app: req.app 
    }); 
  } catch {}
  
  res.json({ order, showDispatcherPopup: true });
});

// Mark order as ready for pickup (vendor)
router.post("/:id/ready", authRequired("vendor"), async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('vendor')
      .populate('consumerId', 'name phone');
    
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.status !== 'accepted') {
      return res.status(400).json({ error: 'Order must be accepted first' });
    }
    
    order.status = "ready";
    order.readyAt = new Date();
    await order.save();
    
    const io = req.app.get('io');
    
    // Check if this is a multi-vendor order
    if (order.orderGroupId) {
      // Find all orders in this group
      const groupOrders = await Order.find({ 
        orderGroupId: order.orderGroupId 
      }).populate('vendor');
      
      const totalOrders = groupOrders.length;
      const readyOrders = groupOrders.filter(o => o.status === 'ready').length;
      
      console.log(`📦 Multi-vendor: ${readyOrders}/${totalOrders} orders ready (Group: ${order.orderGroupId})`);
      
      // Notify customer of progress
      if (io) {
        io.to(String(order.consumerId._id)).emit('order:update', {
          id: order._id,
          status: 'ready',
          message: `${order.vendor?.businessName} is ready! (${readyOrders}/${totalOrders} vendors ready)`,
          progress: { ready: readyOrders, total: totalOrders }
        });
      }
      
      // Only call dispatcher when ALL vendors are ready
      if (readyOrders === totalOrders) {
        console.log('🚀 All vendors ready! Broadcasting to dispatchers...');
        
        // Build pickup route for dispatcher
        const pickupLocations = groupOrders.map(o => ({
          orderId: o._id,
          vendor: {
            businessName: o.vendor?.businessName,
            address: o.vendor?.address,
            phone: o.vendor?.phone
          },
          items: o.items,
          subtotal: o.subtotal
        }));
        
        // Broadcast to all available dispatchers
        if (io) {
          io.to('dispatchers_room').emit('new_delivery_request', {
            orderGroupId: order.orderGroupId,
            isMultiVendor: true,
            pickupCount: totalOrders,
            pickupLocations,
            customer: {
              name: order.consumerId?.name,
              phone: order.consumerId?.phone,
              address: order.deliveryAddress
            },
            totalAmount: groupOrders.reduce((sum, o) => sum + (o.total || 0), 0),
            earning: 70, // Same ₦70 for multi-pickup
            message: `Multi-vendor delivery: ${totalOrders} pickups → 1 delivery!`
          });
        }
        
        // Notify ALL vendors in the group
        groupOrders.forEach(groupOrder => {
          if (io && groupOrder.vendor?.user) {
            io.to(String(groupOrder.vendor.user)).emit('dispatcher:called', {
              orderGroupId: order.orderGroupId,
              message: `All ${totalOrders} vendors ready! Calling dispatcher now...`
            });
          }
        });
        
        // Notify customer
        if (io) {
          io.to(String(order.consumerId._id)).emit('order:update', {
            id: order._id,
            status: 'dispatch_requested',
            message: `All items ready! Looking for a dispatcher to collect from ${totalOrders} locations...`
          });
        }
      }
      
    } else {
      // Single vendor order - original flow
      if (io) {
        io.to('dispatchers_room').emit('new_delivery_request', {
          orderId: order._id,
          isMultiVendor: false,
          pickupCount: 1,
          vendor: {
            businessName: order.vendor?.businessName,
            address: order.vendor?.address,
            phone: order.vendor?.phone
          },
          customer: {
            name: order.consumerId?.name,
            phone: order.consumerId?.phone,
            address: order.deliveryAddress
          },
          totalAmount: order.totalAmount,
          earning: 70,
          message: `New delivery from ${order.vendor?.businessName || 'Vendor'}!`
        });
      }
      
      // Notify customer
      try {
        await sendNotification({
          userId: order.consumerId._id,
          title: 'Order Ready! 🍽️',
          message: 'Your order is ready. Calling a dispatcher now...',
          type: 'order',
          meta: { orderId: order._id },
          app: req.app
        });
      } catch {}
      
      // Update customer in real-time
      if (io) {
        io?.to(String(order.consumerId._id)).emit('order:update', {
          id: order._id,
          status: 'ready',
          message: 'Your order is ready! Looking for a dispatcher...'
        });
      }
    }
    
    res.json({ 
      order, 
      message: order.orderGroupId 
        ? `Order marked ready. Waiting for other vendors in group ${order.orderGroupId}`
        : 'Order marked as ready. Broadcasted to all dispatchers!'
    });
  } catch (error) {
    console.error('Error marking order ready:', error);
    res.status(500).json({ error: 'Server error' });
  }
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
      // Distribute service charge: admin +30, rider +70 (defaults; can be overridden via env)
      const adminShare = Number(process.env.SERVICE_CHARGE_ADMIN || 30);
      const riderShare = Number(process.env.SERVICE_CHARGE_RIDER || 70);
      const admin = await User.findOne({ role: 'admin' });
      if (admin) await adjustUserWallet(admin._id, adminShare, 'credit', { kind: 'admin_fee', stage: 'rider_delivery', order: order._id });
      if (order.riderId) await adjustUserWallet(order.riderId, riderShare, 'credit', { kind: 'rider_share', stage: 'rider_delivery', order: order._id });
        try {
          const io = req.app.get('io');
          io?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status });
          if (order.riderId) io?.to(String(order.riderId)).emit('order:update', { id: order._id, status: order.status });
        } catch {}
        try { if (order.riderId) await sendNotification({ userId: order.riderId, title: 'Delivery complete ✔️', message: `Order ${String(order._id).slice(-6)} marked delivered.`, type: 'order', meta: { orderId: order._id }, app: req.app }); } catch {}
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
  try {
    const { status } = req.body;
    const valid = ["preparing"];
    if (!valid.includes(status)) return res.status(400).json({ error: "Invalid status" });

    // Use atomic update to avoid validation issues on required fields like consumerId
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { $set: { status } },
      { new: true, runValidators: false }
    );

    if (!order) return res.status(404).json({ error: "Not found" });

    try { req.app.get('io')?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status }); } catch {}
    try { await sendNotification({ userId: order.consumerId, title: 'Order preparing 👨‍🍳', message: 'Your order is now being prepared.', type: 'order', meta: { orderId: order._id }, app: req.app }); } catch {}
    res.json({ order });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Vendor packs order and sets packaging choice; moves to waiting_pickup and charges admin fee (₦50)
router.post("/:id/pack", authRequired("vendor"), async (req, res) => {
  try {
    const { packagingChoice, packagingNotes } = req.body || {};
    const set = { status: "waiting_pickup" };
    if (packagingChoice) set.packagingChoice = packagingChoice;
    if (packagingNotes) set.packagingNotes = packagingNotes;

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { $set: set },
      { new: true, runValidators: false }
    );

    if (!order) return res.status(404).json({ error: "Not found" });

    try { req.app.get('io')?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status, packagingChoice }); } catch {}
    try { await sendNotification({ userId: order.consumerId, title: 'Order ready for pickup 📦', message: 'Your order is ready for pickup.', type: 'order', meta: { orderId: order._id }, app: req.app }); } catch {}
    // Broadcast dispatch request to all riders/dispatchers (multiple rooms + alias)
    try {
      const io = req.app.get('io');
      const payload = { id: order._id, vendorId: order.vendorId, subtotal: order.subtotal, createdAt: order.createdAt };
      io?.to('role:rider').emit('dispatch:request', payload);
      io?.to('role:dispatcher').emit('dispatch:request', payload);
      io?.to('dispatchers_room').emit('dispatch:request', payload);
      // legacy alias used by some clients
      io?.to('role:rider').emit('new_delivery_request', payload);
      io?.to('dispatchers_room').emit('new_delivery_request', payload);
    } catch {}
    try { await notifyAdmin('Dispatch Requested 🚚', `Order <b>${order._id}</b> is ready for pickup.`); } catch {}
    res.json({ order });
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// Rider assignment (simple manual endpoint for now)
router.post("/:id/assign-rider", authRequired("vendor"), async (req, res) => {
  // JWT token contains _id field, not id
  const userId = req.user._id || req.user.id;
  const vendorUser = await User.findById(userId)
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
  const riderQr = await generateQrPngBase64(riderToken);
  const consumerQr = await generateQrPngBase64(consumerToken);

  // Notify all parties
  try {
    const io = req.app.get('io');
    io?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status, riderAssigned: true });
    io?.to(String(order.riderId)).emit('order:assigned', { id: order._id });
  } catch {}
  try { await notifyAdmin('Rider Assigned 🏍️', `Order <b>${order._id}</b> assigned to rider.`); } catch {}
  try { await sendNotification({ userId: order.consumerId, title: 'Rider assigned 🏍️', message: 'A rider has been assigned to your order.', type: 'order', meta: { orderId: order._id }, app: req.app }); } catch {}
  res.json({ order, riderQrBase64: riderQr, consumerQrBase64: consumerQr });
});

// List available orders for riders (ready for pickup)
router.get('/available/list', authRequired('rider'), async (req, res) => {
  const items = await Order.find({ status: 'waiting_pickup', riderId: { $in: [null, undefined] } }).sort({ createdAt: -1 });
  res.json({ items });
});

// Get my orders (for any role) — must be declared BEFORE any ":id" routes
router.get("/mine", authRequired(), async (req, res) => {
  const role = req.user.role;
  // JWT token contains _id field, not id
  const id = req.user._id || req.user.id;
  let q = {};
  if (role === "customer") q.consumerId = id;
  if (role === "vendor") {
    // Vendor orders are stored with vendorId = vendor userId
    q.vendorId = id;
  }
  if (role === "rider") q.riderId = id;
  const items = await Order.find(q).sort({ createdAt: -1 });
  res.json({ items });
});

// First-come-first-serve: rider accepts a dispatch
router.post('/:id/accept-dispatch', authRequired('rider'), async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ error: 'Not found' });
    if (order.riderId) return res.status(409).json({ error: 'Order already assigned' });
    if (order.status !== 'waiting_pickup') return res.status(400).json({ error: 'Order not ready for dispatch' });

    // JWT token contains _id field, not id
    const userId = req.user._id || req.user.id;
    // Some legacy/demo orders may be missing consumerId; synthesize a guest so validation doesn't fail
    try {
      if (!order.consumerId) {
        const base = String(order.orderGroupId || order._id);
        const email = `guest+${base}@quickserve.local`;
        let guest = await User.findOne({ email });
        if (!guest) {
          const randomPass = Math.random().toString(36).slice(2, 10) + '!A9';
          guest = await User.create({ role: 'customer', email, password: randomPass, name: 'Guest', isVerified: false });
        }
        order.consumerId = guest._id;
      }
    } catch {}
    order.riderId = userId;
    order.status = 'assigned';

    // Create QR tokens for both parties
    const riderToken = signQrToken(order._id.toString(), 'rider');
    const consumerToken = signQrToken(order._id.toString(), 'customer');
    order.qrRiderToken = riderToken;
    order.qrConsumerToken = consumerToken;
    order.qrTokenExpiresAt = new Date(Date.now() + 1000 * 60 * 60);
    await order.save();

    const riderQr = await generateQrPngBase64(riderToken);
    const consumerQr = await generateQrPngBase64(consumerToken);

    // Notify parties
    const io = req.app.get('io');
    try { io?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status, riderAssigned: true }); } catch {}
    try { io?.to(String(order.vendorId)).emit('order:update', { id: order._id, status: order.status, riderAssigned: true }); } catch {}
    // Let other dispatchers auto-dismiss their popups
    try { io?.to('dispatchers_room').emit('delivery_taken', { orderId: order._id }); } catch {}
    try { await notifyAdmin('Dispatch Accepted ✅', `Order <b>${order._id}</b> accepted by a dispatcher.`); } catch {}

    res.json({ order, riderQrBase64: riderQr, consumerQrBase64: consumerQr });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 🆕 PUBLIC: Track order by ID (for guest checkout)
// This endpoint allows anyone to view an order's tracking info without authentication
router.get('/track/:id', async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate('vendorId', 'businessName storeName')
      .populate('riderId', 'phone');
    
    if (!order) return res.status(404).json({ error: 'Order not found' });
    
    // Return limited info for public tracking
    res.json({ 
      order: {
        _id: order._id,
        status: order.status,
        items: order.items,
        totalAmount: order.totalAmount,
        seatNumber: order.seatNumber,
        createdAt: order.createdAt,
        estimatedDeliveryTime: order.estimatedDeliveryTime,
        vendorId: order.vendorId,
        riderId: order.riderId ? { phone: order.riderId.phone } : null,
        deliveryLocation: order.deliveryLocation
      }
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get single order with permissions
router.get('/:id', authRequired(), async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: 'Not found' });
  const uid = req.user.id;
  const role = req.user.role;
  
  // ✅ Allow all customers (registered or guest) to view any order - no restrictions
  if (role === 'customer') {
    return res.json({ order });
  }
  
  // For vendors: only their own orders
  if (role === 'vendor') {
    const v = await Vendor.findOne({ user: uid });
    if (!v || String(order.vendorId) !== String(v._id)) return res.status(403).json({ error: 'Forbidden' });
  }
  
  // For riders: only assigned orders
  if (role === 'rider' && order.riderId && String(order.riderId) !== String(uid)) return res.status(403).json({ error: 'Forbidden' });
  
  res.json({ order });
});

// Rider marks in_transit
router.post("/:id/in-transit", authRequired("rider"), async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: "Not found" });
  order.status = "in_transit";
  order.inTransitAt = new Date();
  await order.save();
  // Emit ETA to consumer based on distance and assumed speed
  try {
    const io = req.app.get('io');
    const speedKmh = Number(process.env.RIDER_SPEED_KMH || 20);
    const etaSec = Math.max(60, Math.round(((order.distanceKm || 3) / speedKmh) * 3600));
    io?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status, etaSeconds: etaSec });
  } catch {}
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

  // Distribute service charge
  try {
    const adminShare = Number(process.env.SERVICE_CHARGE_ADMIN || 30);
    const riderShare = Number(process.env.SERVICE_CHARGE_RIDER || 70);
    const admin = await User.findOne({ role: 'admin' });
    if (admin) await adjustUserWallet(admin._id, adminShare, 'credit', { kind: 'admin_fee', stage: 'confirm_delivery', order: order._id });
    if (order.riderId) await adjustUserWallet(order.riderId, riderShare, 'credit', { kind: 'rider_share', stage: 'confirm_delivery', order: order._id });
  } catch {}

  // Notify admin + parties
  await notifyAdmin(
    "Order Delivered ✔️",
    `<p>Order <b>${order._id}</b> has been delivered.</p>
     <p>QuickServe fee: ₦${order.platformFee}.</p>`
  );
  try { await sendNotification({ userId: order.consumerId, title: 'Delivered ✔️', message: 'Your order has been delivered.', type: 'order', meta: { orderId: order._id }, app: req.app }); } catch {}
  try { if (order.riderId) await sendNotification({ userId: order.riderId, title: 'Delivery complete ✔️', message: `Order ${String(order._id).slice(-6)} marked delivered.`, type: 'order', meta: { orderId: order._id }, app: req.app }); } catch {}

  res.json({ order });
});

// Get QR image for current role (customer or rider)
router.get('/:id/qr', authRequired(), async (req, res) => {
  const { type } = req.query; // 'customer' or 'rider'
  const order = await Order.findById(req.params.id);
  if (!order) return res.status(404).json({ error: 'Not found' });
  const role = req.user.role;
  const uid = req.user.id;

  // Permission checks
  if (role === 'customer' && String(order.consumerId) !== String(uid)) return res.status(403).json({ error: 'Forbidden' });
  if (role === 'rider') {
    if (!order.riderId || String(order.riderId) !== String(uid)) return res.status(403).json({ error: 'Forbidden' });
  }

  let token;
  if (type === 'customer') token = order.qrConsumerToken;
  else if (type === 'rider') token = order.qrRiderToken;
  else return res.status(400).json({ error: 'Invalid type' });

  if (!token) return res.status(404).json({ error: 'QR not available' });
  const qrBase64 = await generateQrPngBase64(token);
  res.json({ qrBase64 });
});

// DEV ONLY: Create orders without payment for testing
router.post('/demo-create-batch', async (req, res) => {
  try {
    const demoOn = process.env.EVENT_DEMO_MODE === 'true';
    if (!demoOn) {
      return res.status(403).json({ error: 'Demo order creation disabled' });
    }
    const { seatNumber, phone, orders, orderGroupId, isMultiVendor } = req.body; // 🆕 Added orderGroupId, isMultiVendor
    if (!Array.isArray(orders) || !orders.length) return res.status(400).json({ error: 'orders array required' });

    // Determine consumer (logged-in customer or guest)
    let consumerId = null;
    try {
      if (req.user && req.user.role === 'customer') {
        consumerId = req.user.id;
      } else {
        // Create or reuse a guest customer for this phone/seat
        const base = phone ? String(phone).replace(/\D/g,'') : Date.now();
        const email = `guest+${base}@quickserve.local`;
        let guest = await User.findOne({ email });
        if (!guest) {
          const randomPass = Math.random().toString(36).slice(2, 10) + '!A9';
          guest = await User.create({
            role: 'customer',
            email,
            password: randomPass,
            name: seatNumber ? `Guest ${seatNumber}` : 'Guest',
            isVerified: false,
            profile: { phone: phone || '' }
          });
        }
        consumerId = guest._id;
      }
    } catch {}

    const created = [];
    for (const o of orders) {
      if (!o.vendorUserId || !Array.isArray(o.items) || !o.items.length) continue;
      const subtotal = o.items.reduce((s, it) => s + Number(it.price || 0) * Number(it.qty || 1), 0);
      const platformFee = orders.length > 1 ? 0 : Number(process.env.SERVICE_CHARGE_TOTAL || 70); // Only first pays fee
      const total = subtotal + platformFee;
      const ord = await Order.create({
        consumerId,
        vendorId: o.vendorUserId,
        items: o.items.map(it => ({ name: it.name, price: Number(it.price || 0), qty: Number(it.qty || 1) })),
        subtotal,
        deliveryFee: 0,
        platformFee,
        total,
        deliveryAddress: seatNumber ? `Seat ${seatNumber}` : undefined,
        notes: phone ? `Phone: ${phone}` : undefined,
        status: 'placed',
        orderGroupId: orderGroupId || undefined,  // 🆕 Link orders together
        isMultiVendor: isMultiVendor || false,    // 🆕 Flag multi-vendor
        payment: { paid: false, reference: 'demo' }
      });
      created.push(ord);
      // Emit to vendor personal room and admin role that a new order arrived
      try {
        const io = req.app.get('io');
        io?.to(String(ord.vendorId)).emit('order:new', { 
          id: ord._id,
          isMultiVendor: ord.isMultiVendor,
          orderGroupId: ord.orderGroupId
        });
        io?.to('role:admin').emit('order:new', { id: ord._id });
      } catch {}
      // In-app notifications for vendor and consumer
      try { await sendNotification({ userId: ord.vendorId, title: 'New order 🧾', message: 'A new order has been placed.', type: 'order', meta: { orderId: ord._id }, app: req.app }); } catch {}
      try { if (ord.consumerId) await sendNotification({ userId: ord.consumerId, title: 'Order placed 🧾', message: 'Your order has been placed.', type: 'order', meta: { orderId: ord._id }, app: req.app }); } catch {}
    }
    res.json({ success: true, created });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// 🆕 Get all orders in a multi-vendor group
router.get('/group/:orderGroupId', authRequired(), async (req, res) => {
  try {
    const { orderGroupId } = req.params;
    
    if (!orderGroupId) {
      return res.status(400).json({ error: 'orderGroupId is required' });
    }
    
    const orders = await Order.find({ orderGroupId })
      .populate('vendorId', 'businessName location')
      .populate('consumerId', 'name phone')
      .select('_id vendorId consumerId items subtotal status orderGroupId isMultiVendor createdAt')
      .sort('createdAt');
    
    if (orders.length === 0) {
      return res.status(404).json({ error: 'No orders found for this group' });
    }
    
    // Calculate progress
    const readyCount = orders.filter(o => ['ready', 'delivered'].includes(o.status)).length;
    const totalCount = orders.length;
    const allReady = readyCount === totalCount;
    
    res.json({
      success: true,
      orderGroupId,
      orders,
      progress: {
        ready: readyCount,
        total: totalCount,
        allReady
      }
    });
  } catch (error) {
    console.error('Error fetching order group:', error);
    res.status(500).json({ error: 'Failed to fetch order group' });
  }
});

export default router;

