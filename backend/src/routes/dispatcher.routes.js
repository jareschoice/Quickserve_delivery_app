// ===============================
// FILE: backend/src/routes/dispatcher.routes.js
// Dispatcher API endpoints
// ===============================
import express from "express";
import mongoose from "mongoose";
import Dispatcher from "../models/Dispatcher.js";
import Vendor from "../models/Vendor.js";
import EventOrder from "../models/EventOrder.js";
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import { adjustUserWallet } from "../utils/wallet.js";
import { authRequired } from "../middleware/auth.js";
import { emitToUser, emitToVendor, emitToVendorGuarded, emitToOrderRoom, emitToRole } from '../utils/socket-emit.js';

// Small haversine helper for ETA calculations
function haversineKm(lat1, lon1, lat2, lon2) {
  const toRad = v => v * Math.PI / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat/2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon/2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

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
        // Emit new standardized event name for real-time dispatcher location updates
        io.to(`order:${dispatcher.currentDelivery.orderId}`).emit('dispatcher:location:update', {
          orderId: String(dispatcher.currentDelivery.orderId),
          lat: Number(latitude),
          lng: Number(longitude)
        });
        io.to(`order_${dispatcher.currentDelivery.orderId}`).emit('dispatcher:location:update', {
          orderId: String(dispatcher.currentDelivery.orderId),
          lat: Number(latitude),
          lng: Number(longitude)
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
    let usedEventOrders = false;

    // Try to find by orderGroupId in legacy Order first
    let groupOrders = await Order.find({ orderGroupId: orderIdOrGroupId })
      .populate('vendorId')
      .populate('consumerId', 'name phone');

    if (groupOrders.length > 0) {
      orders = groupOrders;
      isMultiVendor = true;
    } else {
      // Legacy Order not found as a group; try single legacy Order id
      const singleOrder = await Order.findById(orderIdOrGroupId)
        .populate('vendorId')
        .populate('consumerId', 'name phone');

      if (singleOrder) {
        orders = [singleOrder];
      } else {
        // Legacy Order not found at all — attempt EventOrder (event system)
        try {
          const eventOrders = await EventOrder.find({ orderGroupId: orderIdOrGroupId }).populate('vendorId').populate('dispatcherId').lean();
          if (eventOrders && eventOrders.length > 0) {
            // Map EventOrder shape to legacy-compatible shape where possible
            orders = eventOrders.map(o => ({
              _id: o._id,
              vendor: o.vendorId || null,
              consumerId: o.consumerId || null,
              status: o.status,
              orderGroupId: o.orderGroupId,
              totalAmount: o.total || o.subtotal || 0
            }));
            isMultiVendor = true;
            usedEventOrders = true;
          } else {
            // Try single EventOrder by id
            const singleEvent = await EventOrder.findById(orderIdOrGroupId).populate('vendorId').lean();
            if (singleEvent) {
              orders = [{
                _id: singleEvent._id,
                vendor: singleEvent.vendorId || null,
                consumerId: singleEvent.consumerId || null,
                status: singleEvent.status,
                orderGroupId: singleEvent.orderGroupId,
                totalAmount: singleEvent.total || singleEvent.subtotal || 0
              }];
              usedEventOrders = true;
            } else {
              return res.status(404).json({ error: "Order not found" });
            }
          }
        } catch (evErr) {
          console.error('EventOrder lookup failed', evErr && evErr.message);
          return res.status(500).json({ error: 'Internal lookup error' });
        }
      }
    }
    
    // Check if any order in the group is already assigned
    const alreadyAssigned = orders.find(o => o.dispatcher || o.dispatcherId);
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
    // If these are legacy Order docs, they are mongoose documents with save(); for EventOrder mapping above we need to update EventOrder collection directly
    try {
      // If the found orders came from legacy Order model (have save method), perform atomic updates
      if (orders.length > 0 && orders[0] && orders[0].save) {
        // Use atomic findOneAndUpdate for group claim to avoid race conditions
        try {
          if (isMultiVendor && orders[0].orderGroupId) {
            // Attempt to atomically claim the group's canonical order (first ready one)
            const groupId = orders[0].orderGroupId;
            const claimed = await Order.findOneAndUpdate(
              { orderGroupId: groupId, groupAssigned: { $ne: true }, status: 'ready', dispatcher: { $exists: false } },
              { $set: { dispatcher: dispatcher._id, status: 'assigned', groupAssigned: true, dispatcherAssignedAt: new Date() } },
              { sort: { createdAt: 1 }, new: true }
            );
            if (!claimed) {
              return res.status(400).json({ error: "This delivery has already been accepted by another dispatcher" });
            }

            // Propagate assignment to remaining orders in the group
            await Order.updateMany({ orderGroupId: groupId, dispatcher: { $exists: false } }, { $set: { dispatcher: dispatcher._id, status: 'assigned', dispatcherAssignedAt: new Date() } });
          } else {
            // Single legacy Order: atomic claim on specific id
            const claimedSingle = await Order.findOneAndUpdate(
              { _id: orders[0]._id, status: 'ready', dispatcher: { $exists: false } },
              { $set: { dispatcher: dispatcher._id, status: 'assigned', dispatcherAssignedAt: new Date() } },
              { new: true }
            );
            if (!claimedSingle) {
              return res.status(400).json({ error: "This delivery has already been accepted by another dispatcher" });
            }
          }
        } catch (claimErr) {
          console.error('Atomic claim error for legacy Order:', claimErr && claimErr.message);
          return res.status(500).json({ error: 'Failed to assign delivery' });
        }
      } else {
        // Update EventOrder documents directly by orderGroupId or individual ids
        if (isMultiVendor && orders[0].orderGroupId) {
          await EventOrder.updateMany({ orderGroupId: orders[0].orderGroupId }, { $set: { dispatcherId: dispatcher._id, status: 'assigned', dispatcherAssignedAt: new Date() } });
        } else {
          // single EventOrder
          await EventOrder.findByIdAndUpdate(orders[0]._id, { $set: { dispatcherId: dispatcher._id, status: 'assigned', dispatcherAssignedAt: new Date() } });
        }
      }
    } catch (saveErr) {
      console.error('Error assigning dispatcher to orders', saveErr && saveErr.message);
      return res.status(500).json({ error: 'Failed to assign delivery' });
    }
    
    // Update dispatcher current delivery (store first order or group ID)
    await dispatcher.assignDelivery(orders[0]._id);

    // If we updated EventOrder documents, emit EventOrder-compatible realtime events and return
    if (typeof usedEventOrders !== 'undefined' && usedEventOrders) {
      try {
        const io = req.app.get('io');
        // Re-fetch full EventOrder docs for emits
        const realOrders = isMultiVendor
          ? await EventOrder.find({ orderGroupId: orders[0].orderGroupId }).populate('vendorId').lean()
          : [(await EventOrder.findById(orders[0]._id).populate('vendorId').lean())];

        const groupId = realOrders[0]?.orderGroupId || null;

        // Build a group-level payload
        const payloadGroup = {
          orderGroupId: groupId,
          isMultiVendor: isMultiVendor,
          pickupCount: realOrders.length,
          pickupLocations: realOrders.map(o => ({ orderId: String(o._id), vendorId: o.vendorId?._id || null, vendorName: o.vendorId?.businessName || o.vendorId?.name || null, items: o.items, subtotal: o.subtotal })),
          totalAmount: realOrders.reduce((s, r) => s + Number(r.total || r.subtotal || 0), 0),
          message: `Multi-vendor delivery accepted by ${dispatcher.name}`
        };

        // Notify dispatchers room once
        if (io) {
          io.to('dispatchers_room').emit('delivery_taken', { orderGroupId: groupId, isMultiVendor: true, message: `Multi-vendor delivery accepted by ${dispatcher.name}` });
          try { emitToRole(io, 'dispatcher', 'delivery_taken', { orderGroupId: groupId, isMultiVendor: true, message: `Multi-vendor delivery accepted by ${dispatcher.name}` }); } catch(e) {}
          io.to('dispatchers_room').emit('order:assigned', { orderGroupId: groupId, dispatcher: dispatcher.dispatcherId, isMultiVendor: true });
          try { emitToRole(io, 'dispatcher', 'order:assigned', { orderGroupId: groupId, dispatcher: dispatcher.dispatcherId, isMultiVendor: true }); } catch(e) {}

          // Notify each vendor's user & vendor rooms and emit dispatcher location update to order room
          realOrders.forEach((ro, idx) => {
            const vendorUserId = ro.vendorId?._id ? String(ro.vendorId._id) : (ro.vendorId?.user ? String(ro.vendorId.user) : null);
            if (vendorUserId) {
              emitToUser(io, vendorUserId, 'order:dispatcher_assigned', {
                orderId: String(ro._id),
                orderGroupId: groupId,
                isMultiVendor: true,
                dispatcher: { dispatcherId: dispatcher.dispatcherId, name: dispatcher.name, phone: dispatcher.phone },
                message: `${dispatcher.name} will collect from ${realOrders.length} vendors!`,
                pickupPosition: idx + 1,
                totalPickups: realOrders.length
              });
              // Gate vendor personal emits using the guarded helper
              try { emitToVendorGuarded(io, vendorUserId, 'order:dispatcher_assigned', {
                orderId: String(ro._id),
                orderGroupId: groupId,
                isMultiVendor: true,
                dispatcher: { dispatcherId: dispatcher.dispatcherId, name: dispatcher.name, phone: dispatcher.phone },
                message: `${dispatcher.name} will collect from ${realOrders.length} vendors!`,
                pickupPosition: idx + 1,
                totalPickups: realOrders.length
              }, ro.payment || null); } catch (e) {}
            }
            // Emit dispatcher location update to the order room
            try {
              const dLoc = dispatcher.location || (dispatcher.profile && dispatcher.profile.location) || null;
              if (dLoc && dLoc.lat && dLoc.lng) {
                emitToOrderRoom(io, ro._id, 'dispatcher:location:update', { orderId: String(ro._id), lat: Number(dLoc.lat), lng: Number(dLoc.lng) });
              }
            } catch (emitErr) { /* ignore */ }
          });

          // Notify admin room
          emitToRole(io, 'admin', 'order:dispatcher_assigned', { orderGroupId: groupId, isMultiVendor: true, vendorCount: realOrders.length, dispatcher: dispatcher.dispatcherId, timestamp: new Date() });

          // Notify group room and individual order rooms that dispatcher is assigned
          try { io.to(`orderGroup:${groupId}`).emit('order:assigned', payloadGroup); } catch(e) {}
          realOrders.forEach(ro => emitToOrderRoom(io, ro._id, 'order:assigned', payloadGroup));
        }
      } catch (emitErr) {
        console.error('EventOrder accept emits failed', emitErr && emitErr.message);
      }

      return res.json({ success: true, isMultiVendor, pickupCount: orders.length, orders: orders.map(o => ({ orderId: o._id, vendor: o.vendorId?.businessName || o.vendorId?.name || o.vendor?.businessName || o.vendor?.name || null, status: o.status })), message: isMultiVendor ? `Multi-vendor delivery accepted! Collect from ${orders.length} locations.` : 'Delivery accepted! Proceed to pickup location.' });
    }

    // Real-time updates to all parties
    const io = req.app.get('io');
    if (io) {
      if (isMultiVendor) {
        // Notify ALL vendors in the group and emit dispatcher location + ETA to order rooms
        // Compute a rough ETA (minutes) when possible and include in the assigned payload
        let etaMinutes = null;
        try {
          const venueLat = Number(process.env.VENUE_LAT);
          const venueLng = Number(process.env.VENUE_LNG);
          const speedKmh = Number(process.env.RIDER_SPEED_KMH || 20);
          // prefer dispatcher's last known location, fallback to null
          const dLoc = dispatcher.location || (dispatcher.profile && dispatcher.profile.location) || null;
          // choose primary vendor location (first order) if available
          const vendorLoc = orders[0].vendorId?.location || orders[0].vendorId?.profile?.location || null;
          let distKm = null;
          if (dLoc && dLoc.lat && dLoc.lng && vendorLoc && vendorLoc.lat && vendorLoc.lng) {
            // distance from dispatcher to first vendor
            distKm = haversineKm(Number(dLoc.lat), Number(dLoc.lng), Number(vendorLoc.lat), Number(vendorLoc.lng));
          } else if (vendorLoc && vendorLoc.lat && vendorLoc.lng && Number.isFinite(venueLat) && Number.isFinite(venueLng)) {
            // distance from vendor to venue
            distKm = haversineKm(Number(vendorLoc.lat), Number(vendorLoc.lng), venueLat, venueLng);
          }
          if (distKm !== null) etaMinutes = Math.max(1, Math.round((distKm / speedKmh) * 60));
        } catch (e) { etaMinutes = null; }

        const assignedPayload = {
          orderId: String(orders[0]._id),
          status: 'assigned',
          isMultiVendor: true,
          dispatcher: { name: dispatcher.name, phone: dispatcher.phone },
          message: `Dispatcher assigned! Collecting from ${orders.length} vendors...`,
          pickupLocations: orders.map(o => o.vendorId?.businessName || o.vendorId?.name),
          orderGroupId: orders[0].orderGroupId || null,
          etaMinutes
        };

        // Notify customer once (plain + namespaced + order rooms)
        emitToUser(io, orders[0].consumerId._id, 'order:update', { id: orders[0]._id, status: 'assigned', message: `Dispatcher assigned! Collecting from ${orders.length} vendors...` });
        emitToUser(io, orders[0].consumerId._id, 'order:assigned', assignedPayload);
        emitToOrderRoom(io, orders[0]._id, 'order:assigned', assignedPayload);

        // Notify ALL vendors and emit dispatcher location update for each order
        orders.forEach(order => {
          const vendorUserId = order.vendorId?.user ? String(order.vendorId.user) : (order.vendorId?._id ? String(order.vendorId._id) : null);
          if (vendorUserId) {
            // Notify vendor user (guarded: only after payment or when override enabled)
            try {
              emitToVendorGuarded(io, vendorUserId, 'order:dispatcher_assigned', {
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
              }, order.payment || null);
            } catch(e) { /* ignore */ }

            // emit dispatcher location update to the specific order room so consumer map can update immediately
          try {
            const dLoc = dispatcher.location || (dispatcher.profile && dispatcher.profile.location) || null;
            if (dLoc && dLoc.lat && dLoc.lng) {
              io.to(`order:${String(order._id)}`).emit('dispatcher:location:update', {
                orderId: String(order._id),
                lat: Number(dLoc.lat),
                lng: Number(dLoc.lng)
              });
            }
          } catch (emitErr) { /* ignore */ }
          }
        });

        // Notify other dispatchers
        io.to('dispatchers_room').emit('delivery_taken', { orderGroupId: orders[0].orderGroupId, isMultiVendor: true, message: `Multi-vendor delivery accepted by ${dispatcher.name}` });
        try { emitToRole(io, 'dispatcher', 'delivery_taken', { orderGroupId: orders[0].orderGroupId, isMultiVendor: true, message: `Multi-vendor delivery accepted by ${dispatcher.name}` }); } catch(e) {}
        io.to('dispatchers_room').emit('order:assigned', { orderGroupId: orders[0].orderGroupId, dispatcher: dispatcher.dispatcherId, isMultiVendor: true });
        try { emitToRole(io, 'dispatcher', 'order:assigned', { orderGroupId: orders[0].orderGroupId, dispatcher: dispatcher.dispatcherId, isMultiVendor: true }); } catch(e) {}

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
        
        const vendorUserIdSingle = order.vendorId?.user ? String(order.vendorId.user) : (order.vendorId?._id ? String(order.vendorId._id) : null);
        if (vendorUserIdSingle) {
          try {
            emitToVendorGuarded(io, vendorUserIdSingle, 'order:dispatcher_assigned', {
              orderId: order._id,
              dispatcher: {
                dispatcherId: dispatcher.dispatcherId,
                name: dispatcher.name,
                phone: dispatcher.phone
              },
              message: `${dispatcher.name} (${dispatcher.dispatcherId}) is on the way to pickup!`
            }, order.payment || null);
          } catch(e) { /* non-fatal */ }
        }

        emitToUser(io, order.consumerId._id, 'order:update', {
          id: order._id,
          status: 'assigned',
          dispatcher: {
            name: dispatcher.name,
            phone: dispatcher.phone
          },
          message: 'Dispatcher assigned! On the way to pickup your order.'
        });
        // Also emit namespaced assignment event
        emitToUser(io, order.consumerId._id, 'order:assigned', { orderId: order._id, status: 'assigned', dispatcher: { name: dispatcher.name, phone: dispatcher.phone }, orderGroupId: order.orderGroupId || null });
        emitToOrderRoom(io, order._id, 'order:assigned', { orderId: order._id, status: 'assigned', dispatcher: { name: dispatcher.name, phone: dispatcher.phone }, orderGroupId: order.orderGroupId || null });

        // notify other dispatchers (legacy room kept)
        emitToRole(io, 'dispatcher', 'delivery_taken', { orderId: order._id, message: 'This delivery has been accepted by another dispatcher' });
        try { io.to('dispatchers_room').emit('delivery_taken', { orderId: order._id, message: 'This delivery has been accepted by another dispatcher' }); } catch(e) {}
        try { emitToRole(io, 'dispatcher', 'delivery_taken', { orderId: order._id, message: 'This delivery has been accepted by another dispatcher' }); } catch(e) {}
        io.to('dispatchers_room').emit('order:assigned', { orderId: order._id, dispatcher: dispatcher.dispatcherId });
        try { emitToRole(io, 'dispatcher', 'order:assigned', { orderId: order._id, dispatcher: dispatcher.dispatcherId }); } catch(e) {}
        
        io.to('admin_room').emit('order:dispatcher_assigned', {
          orderId: order._id,
          vendor: order.vendorId?.businessName || order.vendorId?.name,
          dispatcher: dispatcher.dispatcherId,
          timestamp: new Date()
        });
        io.to('admin_room').emit('order:assigned', { orderId: order._id, vendor: order.vendorId?.businessName || order.vendorId?.name, dispatcher: dispatcher.dispatcherId, timestamp: new Date() });
      }
    }
    
    res.json({ 
      success: true, 
      isMultiVendor,
      pickupCount: orders.length,
      orders: orders.map(o => ({
        orderId: o._id,
        vendor: o.vendorId?.businessName || o.vendorId?.name || null,
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
          emitToOrderRoom(io, o._id, 'delivery_status_update', { status: o.status, timestamp: now });
          // also notify consumer user room
          emitToUser(io, o.consumerId, 'order:update', { id: o._id, status: o.status, message: 'Delivery status updated' });
          // emit namespaced delivery events
          const payload = { orderId: String(o._id), status: o.status, timestamp: now, orderGroupId: o.orderGroupId || null, vendorId: o.vendorId ? String(o.vendorId) : (o.vendor ? String(o.vendor) : null) };
          if (o.status === 'in_transit' || o.status === 'assigned' || o.status === 'picked_up') {
            emitToUser(io, o.consumerId, 'order:in_transit', payload);
            emitToOrderRoom(io, o._id, 'order:in_transit', payload);
          } else if (o.status === 'arrived_customer' || o.status === 'arrived') {
            emitToUser(io, o.consumerId, 'order:arrived', payload);
            emitToOrderRoom(io, o._id, 'order:arrived', payload);
          }
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
        const payload = { orderId: String(order._id), status: order.status, timestamp: now, orderGroupId: order.orderGroupId || null, vendorId: order.vendorId ? String(order.vendorId) : (order.vendor ? String(order.vendor) : null) };
        if (order.status === 'in_transit' || order.status === 'assigned' || order.status === 'picked_up') {
          emitToUser(io, order.consumerId, 'order:in_transit', payload);
          emitToOrderRoom(io, order._id, 'order:in_transit', payload);
        } else if (order.status === 'arrived_customer' || order.status === 'arrived') {
          emitToUser(io, order.consumerId, 'order:arrived', payload);
          emitToOrderRoom(io, order._id, 'order:arrived', payload);
        }
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
    const order = await Order.findById(orderId).populate('vendorId');
    
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
      const groupOrders = await Order.find({ orderGroupId: order.orderGroupId }).populate('vendorId').populate('consumerId', 'name');
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
            if (o.vendorId) {
              const v = await Vendor.findById(o.vendorId._id || o.vendorId);
              if (v) {
                v.wallet = (v.wallet || 0) + (o.subtotal || 0);
                await v.save();
              }
              await Transaction.create({ user: o.vendorId._id || o.vendorId, amount: o.subtotal || 0, type: 'credit', meta: { reason: 'order_delivery', orderId: o._id } });
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
          const payload = { orderId: String(o._id), status: 'delivered', deliveredAt: new Date(), orderGroupId: o.orderGroupId || null, vendorId: o.vendorId ? String(o.vendorId._id || o.vendorId) : null };
          io.to(`order_${o._id}`).emit('order_delivered', { timestamp: new Date(), message: 'Your order has been delivered! Please rate your experience.' });
          io.to(`order:${String(o._id)}`).emit('order:delivered', payload);
          io.to(`order_${String(o._id)}`).emit('order:delivered', payload);
          emitToUser(io, o.consumerId, 'order:delivered', payload);
          try { emitToVendorGuarded(io, o.vendorId, 'order:delivered', payload, { paid: true }); } catch (e) { /* ignore */ }
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
  const payload = { orderId: String(order._id), status: 'delivered', deliveredAt: new Date(), orderGroupId: order.orderGroupId || null, vendorId: order.vendorId ? String(order.vendorId._id || order.vendorId) : (order.vendor ? String(order.vendor._id || order.vendor) : null) };
        io.to(`order_${order._id}`).emit('order_delivered', { timestamp: new Date(), message: 'Your order has been delivered! Please rate your experience.' });
        io.to(`order:${String(order._id)}`).emit('order:delivered', payload);
        io.to(`order_${String(order._id)}`).emit('order:delivered', payload);
        emitToUser(io, order.consumerId, 'order:delivered', payload);
        try { emitToVendorGuarded(io, order.vendorId, 'order:delivered', payload, { paid: true }); } catch (e) { /* ignore */ }
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
