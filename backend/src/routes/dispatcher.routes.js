// ===============================
// FILE: backend/src/routes/dispatcher.routes.js
// Dispatcher API endpoints
// ===============================
import express from "express";
import mongoose from "mongoose";
import Dispatcher from "../models/Dispatcher.js";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import { adjustUserWallet } from "../utils/wallet.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// Get dispatcher profile
router.get("/profile", authRequired("dispatcher"), async (req, res) => {
  try {
    const dispatcher = await Dispatcher.findOne({ user: req.user._id || req.user.id })
      .populate('user', 'name email')
      .populate('currentDelivery.orderId');
    
    if (!dispatcher) {
      return res.status(404).json({ error: "Dispatcher profile not found" });
    }
    
    res.json({ dispatcher });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get dispatcher wallet (READ-ONLY)
router.get("/wallet", authRequired("dispatcher"), async (req, res) => {
  try {
    const dispatcher = await Dispatcher.findOne({ user: req.user.id });
    if (!dispatcher) {
      return res.status(400).json({ error: "Dispatcher profile not found" });
    }
    
    res.json({
      wallet: dispatcher.wallet || 0,
      totalDeliveries: dispatcher.totalDeliveries || 0,
      completedDeliveries: dispatcher.completedDeliveries || 0,
      earningsPerDelivery: 70, // ₦70 per delivery
      readOnly: true,
      message: "Service fee earnings only. Admin will process payout after event."
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Update dispatcher location (GPS tracking)
router.post("/location", authRequired("dispatcher"), async (req, res) => {
  try {
    const { latitude, longitude } = req.body;
    
    if (!latitude || !longitude) {
      return res.status(400).json({ error: "Latitude and longitude required" });
    }
    
    const dispatcher = await Dispatcher.findOne({ user: req.user.id });
    if (!dispatcher) {
      return res.status(400).json({ error: "Dispatcher profile not found" });
    }
    
    await dispatcher.updateLocation(latitude, longitude);
    
    // Broadcast location to customer if in active delivery
    if (dispatcher.currentDelivery && dispatcher.currentDelivery.orderId) {
      const io = req.app.get('io');
      if (io) {
        io.to(`order_${dispatcher.currentDelivery.orderId}`).emit('dispatcher_location', {
          latitude,
          longitude,
          timestamp: new Date()
        });
      }
    }
    
    res.json({ success: true, location: dispatcher.location });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Accept delivery request (handles both single and multi-vendor orders)
router.post("/accept/:orderIdOrGroupId", authRequired("dispatcher"), async (req, res) => {
  try {
    const { orderIdOrGroupId } = req.params;
    
    const dispatcher = await Dispatcher.findOne({ user: req.user.id }).populate('user', 'name');
    if (!dispatcher) {
      return res.status(400).json({ error: "Dispatcher profile not found" });
    }
    
    // Check if already on a delivery
    if (dispatcher.currentDelivery && dispatcher.currentDelivery.status !== 'idle') {
      return res.status(400).json({ error: "You are already on a delivery" });
    }
    
    const Order = mongoose.model('Order');
    
    // Check if this is a multi-vendor order group or single order
    let orders = [];
    let isMultiVendor = false;
    
    // Try to find by orderGroupId first
    const groupOrders = await Order.find({ orderGroupId: orderIdOrGroupId })
      .populate('vendor')
      .populate('consumerId', 'name phone');
    
    if (groupOrders.length > 0) {
      // Multi-vendor order
      orders = groupOrders;
      isMultiVendor = true;
    } else {
      // Single order
      const singleOrder = await Order.findById(orderIdOrGroupId)
        .populate('vendor')
        .populate('consumerId', 'name phone');
      
      if (!singleOrder) {
        return res.status(404).json({ error: "Order not found" });
      }
      orders = [singleOrder];
    }
    
    // Check if any order in the group is already assigned
    const alreadyAssigned = orders.find(o => o.dispatcher);
    if (alreadyAssigned) {
      return res.status(400).json({ 
        error: "This delivery has already been accepted by another dispatcher" 
      });
    }
    
    // Check if all orders are ready
    const notReady = orders.find(o => o.status !== 'ready');
    if (notReady) {
      return res.status(400).json({ 
        error: "Not all orders in this group are ready for pickup" 
      });
    }
    
    // Assign dispatcher to ALL orders in the group
    for (const order of orders) {
      order.dispatcher = dispatcher._id;
      order.status = 'assigned';
      order.dispatcherAssignedAt = new Date();
      await order.save();
    }
    
    // Update dispatcher current delivery (store first order or group ID)
    await dispatcher.assignDelivery(orders[0]._id);
    
    // Real-time updates to all parties
    const io = req.app.get('io');
    if (io) {
      if (isMultiVendor) {
        // Notify ALL vendors in the group
        orders.forEach(order => {
          io.to(String(order.vendor.user)).emit('order:dispatcher_assigned', {
            orderId: order._id,
            orderGroupId: order.orderGroupId,
            isMultiVendor: true,
            dispatcher: {
              dispatcherId: dispatcher.dispatcherId,
              name: dispatcher.name,
              phone: dispatcher.phone
            },
            message: `${dispatcher.name} (${dispatcher.dispatcherId}) will collect from ${orders.length} vendors!`,
            pickupPosition: orders.indexOf(order) + 1,
            totalPickups: orders.length
          });
        });
        
        // Notify customer once
        io.to(String(orders[0].consumerId._id)).emit('order:update', {
          id: orders[0]._id,
          status: 'assigned',
          isMultiVendor: true,
          dispatcher: {
            name: dispatcher.name,
            phone: dispatcher.phone
          },
          message: `Dispatcher assigned! Collecting from ${orders.length} vendors...`,
          pickupLocations: orders.map(o => o.vendor?.businessName)
        });
        
        // Notify other dispatchers
        io.to('dispatchers_room').emit('delivery_taken', {
          orderGroupId: orders[0].orderGroupId,
          isMultiVendor: true,
          message: `Multi-vendor delivery accepted by ${dispatcher.name}`
        });
        
        // Notify admin
        io.to('admin_room').emit('order:dispatcher_assigned', {
          orderGroupId: orders[0].orderGroupId,
          isMultiVendor: true,
          vendorCount: orders.length,
          dispatcher: dispatcher.dispatcherId,
          timestamp: new Date()
        });
        
      } else {
        // Single vendor - original flow
        const order = orders[0];
        
        io.to(String(order.vendor.user)).emit('order:dispatcher_assigned', {
          orderId: order._id,
          dispatcher: {
            dispatcherId: dispatcher.dispatcherId,
            name: dispatcher.name,
            phone: dispatcher.phone
          },
          message: `${dispatcher.name} (${dispatcher.dispatcherId}) is on the way to pickup!`
        });
        
        io.to(String(order.consumerId._id)).emit('order:update', {
          id: order._id,
          status: 'assigned',
          dispatcher: {
            name: dispatcher.name,
            phone: dispatcher.phone
          },
          message: 'Dispatcher assigned! On the way to pickup your order.'
        });
        
        io.to('dispatchers_room').emit('delivery_taken', {
          orderId: order._id,
          message: 'This delivery has been accepted by another dispatcher'
        });
        
        io.to('admin_room').emit('order:dispatcher_assigned', {
          orderId: order._id,
          vendor: order.vendor?.businessName,
          dispatcher: dispatcher.dispatcherId,
          timestamp: new Date()
        });
      }
    }
    
    res.json({ 
      success: true, 
      isMultiVendor,
      pickupCount: orders.length,
      orders: orders.map(o => ({
        orderId: o._id,
        vendor: o.vendor?.businessName,
        status: o.status
      })),
      message: isMultiVendor 
        ? `Multi-vendor delivery accepted! Collect from ${orders.length} locations.`
        : "Delivery accepted! Proceed to pickup location."
    });
  } catch (e) {
    console.error('Dispatcher accept error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Update delivery status
router.post("/status", authRequired("dispatcher"), async (req, res) => {
  try {
    const { status } = req.body; // 'picked_up', 'in_transit', 'arrived'
    
    const dispatcher = await Dispatcher.findOne({ user: req.user.id });
    if (!dispatcher || !dispatcher.currentDelivery || !dispatcher.currentDelivery.orderId) {
      return res.status(400).json({ error: "No active delivery" });
    }
    
    const Order = mongoose.model('Order');
    const order = await Order.findById(dispatcher.currentDelivery.orderId);
    
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }
    
    // Update dispatcher currentDelivery status and handle single or multi-vendor group updates
    dispatcher.currentDelivery.status = status;
    const now = new Date();
    if (status === 'picked_up') {
      dispatcher.currentDelivery.pickedUpAt = now;
    } else if (status === 'in_transit') {
      dispatcher.currentDelivery.inTransitAt = now;
    } else if (status === 'arrived') {
      dispatcher.currentDelivery.arrivedAt = now;
    }

    await dispatcher.save();

    // Determine mapped order status for orders (group or single)
    let mappedStatus = 'in_transit';
    if (status === 'arrived') mappedStatus = 'arrived_customer';

    const io = req.app.get('io');

    if (order.orderGroupId) {
      // Update all orders in the group atomically
      const groupOrders = await Order.find({ orderGroupId: order.orderGroupId });
      for (const o of groupOrders) {
        o.status = mappedStatus;
        if (mappedStatus === 'in_transit') o.inTransitAt = now;
        if (mappedStatus === 'arrived_customer') o.arrivedAt = now;
        await o.save();

        // Notify customer for each order
        if (io) {
          io.to(`order_${o._id}`).emit('delivery_status_update', { status: o.status, timestamp: now });
          // also notify consumer user room
          io.to(String(o.consumerId)).emit('order:update', { id: o._id, status: o.status, message: 'Delivery status updated' });
        }
      }
    } else {
      // Single order
      if (mappedStatus === 'in_transit') order.inTransitAt = now;
      if (mappedStatus === 'arrived_customer') order.arrivedAt = now;
      order.status = mappedStatus;
      await order.save();
      if (io) {
        io.to(`order_${order._id}`).emit('delivery_status_update', { status: order.status, timestamp: now });
      }
    }
    
    res.json({ success: true, status: order.status });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Confirm delivery via QR scan
router.post("/confirm-delivery", authRequired("dispatcher"), async (req, res) => {
  try {
    const { qrCode, orderId } = req.body;
    
    const dispatcher = await Dispatcher.findOne({ user: req.user.id });
    if (!dispatcher) {
      return res.status(400).json({ error: "Dispatcher profile not found" });
    }
    
    const Order = mongoose.model('Order');
    const order = await Order.findById(orderId).populate('vendor');
    
    if (!order) {
      return res.status(404).json({ error: "Order not found" });
    }
    
    // Verify QR code matches order
    const expectedQR = `QUICKSERVE-${order._id}-${order.createdAt.getTime()}`;
    if (qrCode !== expectedQR) {
      return res.status(400).json({ error: "Invalid QR code" });
    }
    
    // Mark order as delivered
    order.status = 'delivered';
    order.deliveredAt = new Date();
    await order.save();
    
    // Credit dispatcher wallet with ₦70 service fee
    // For multi-vendor groups, mark all group orders delivered and credit vendors
    const io = req.app.get('io');
    if (order.orderGroupId) {
      const groupOrders = await Order.find({ orderGroupId: order.orderGroupId }).populate('vendor').populate('consumerId', 'name');
      // Track which orders still need dispatcher payment
      const dispatcherOrdersToPay = [];

      for (const o of groupOrders) {
        o.status = 'delivered';
        o.deliveredAt = new Date();
        const wasPaid = !!o.isPaidToVendor;
        if (!wasPaid) {
          // mark as paid now (delivery-time)
          o.isPaidToVendor = true;
        }
        await o.save();

        // Credit vendor wallet and create transaction only if it wasn't already credited earlier
        try {
          if (!wasPaid) {
            if (o.vendor) {
              const v = await Vendor.findById(o.vendor._id);
              if (v) {
                v.wallet = (v.wallet || 0) + (o.subtotal || 0);
                await v.save();
              }
              await Transaction.create({ user: o.vendor._id, amount: o.subtotal || 0, type: 'credit', meta: { reason: 'order_delivery', orderId: o._id } });
            }
          }
        } catch (txErr) { console.error('vendor credit error', txErr); }

        // Admin share: only create/admin-credit if not already recorded for this order
        try {
          const adminFeeExists = await Transaction.findOne({ 'meta.orderId': o._id, 'meta.reason': 'admin_fee', status: 'success' });
          if (!adminFeeExists) {
            const adminShare = Number(process.env.SERVICE_CHARGE_ADMIN || 30);
            const admin = await User.findOne({ role: 'admin' });
            if (admin) {
              await adjustUserWallet(admin._id, adminShare, 'credit', { reason: 'admin_fee', orderId: o._id, stage: 'delivery' }, req.app);
            }
          }
        } catch (admErr) { console.error('admin fee credit error', admErr); }

        // Dispatcher share: record for later aggregation (avoid double-pay)
        try {
          const dispatcherFeeExists = await Transaction.findOne({ 'meta.orderId': o._id, 'meta.reason': 'dispatcher_fee', status: 'success' });
          if (!dispatcherFeeExists) dispatcherOrdersToPay.push(o._id);
        } catch (dErr) { console.error('dispatcher fee check error', dErr); }

        // Notify customer for each order
        if (io) {
          io.to(`order_${o._id}`).emit('order_delivered', { timestamp: new Date(), message: 'Your order has been delivered! Please rate your experience.' });
        }
      }

      // Credit dispatcher once for all eligible orders (₦70 per order)
      try {
        const dispatcherShare = Number(process.env.SERVICE_CHARGE_TOTAL || 100) - Number(process.env.SERVICE_CHARGE_ADMIN || 30);
        if (dispatcherOrdersToPay.length > 0) {
          const totalDispatcherAmount = dispatcherShare * dispatcherOrdersToPay.length;
          // update dispatcher model wallet and counters
          dispatcher.wallet = (dispatcher.wallet || 0) + totalDispatcherAmount;
          dispatcher.totalDeliveries = (dispatcher.totalDeliveries || 0) + dispatcherOrdersToPay.length;
          dispatcher.completedDeliveries = (dispatcher.completedDeliveries || 0) + dispatcherOrdersToPay.length;
          dispatcher.currentDelivery = { orderId: null, status: 'idle' };
          await dispatcher.save();

          // create a transaction per order for auditing
          for (const oid of dispatcherOrdersToPay) {
            try {
              await Transaction.create({ user: dispatcher.user, amount: dispatcherShare, type: 'credit', meta: { reason: 'dispatcher_fee', orderId: oid } });
            } catch (txnErr) { console.error('dispatcher transaction create error', txnErr); }
          }
        }
      } catch (aggErr) { console.error('dispatcher aggregate credit error', aggErr); }

    } else {
      // Single order flow
      const wasPaidSingle = !!order.isPaidToVendor;
      if (!wasPaidSingle) {
        order.isPaidToVendor = true;
        try {
          await Transaction.create({ user: order.vendor._id, amount: order.subtotal || 0, type: 'credit', meta: { reason: 'order_delivery', orderId: order._id } });
        } catch (txErr) { console.error('vendor credit error', txErr); }
      }
      await dispatcher.completeDelivery();
      if (io) {
        io.to(`order_${order._id}`).emit('order_delivered', { timestamp: new Date(), message: 'Your order has been delivered! Please rate your experience.' });
      }
    }
    
    res.json({ 
      success: true, 
      message: "Delivery confirmed! ₦70 credited to your wallet.",
      newWalletBalance: dispatcher.wallet
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get delivery history
router.get("/history", authRequired("dispatcher"), async (req, res) => {
  try {
    const dispatcher = await Dispatcher.findOne({ user: req.user.id });
    if (!dispatcher) {
      return res.status(400).json({ error: "Dispatcher profile not found" });
    }
    
    const Order = mongoose.model('Order');
    const deliveries = await Order.find({ 
      dispatcher: dispatcher._id 
    })
    .populate('vendor', 'storeName')
    .sort({ createdAt: -1 })
    .limit(50);
    
    res.json({ deliveries });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
