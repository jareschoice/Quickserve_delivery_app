import EventOrder from '../models/EventOrder.js';
import User from '../models/User.js';
import Product from '../models/Product.js';
import QRCode from 'qrcode';
import crypto from 'crypto';
import { sendOrderNotification } from '../utils/notify.js';

// =======================
// CONSUMER ENDPOINTS
// =======================

// Get all vendors
export const getAllVendors = async (req, res) => {
  try {
    const vendors = await User.find({ role: 'vendor', isVerified: true })
      .select('name profile email')
      .lean();
    
    res.json({ success: true, vendors });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get vendor products
export const getVendorProducts = async (req, res) => {
  try {
    const { vendorId } = req.params;
    
    const products = await Product.find({ vendor: vendorId, available: true })
      .select('name description price category imageUrl')
      .lean();
    
    res.json({ success: true, products });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Create order (consumer)
export const createOrder = async (req, res) => {
  try {
    const { phone, seatNumber, vendorId, items } = req.body;

    if (!phone || !seatNumber || !vendorId || !items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    // Calculate totals
    let subtotal = 0;
    for (const item of items) {
      subtotal += item.price * item.qty;
    }

    const serviceCharge = 100;
    const total = subtotal + serviceCharge;

    // Generate QR token for delivery confirmation
    const deliveryToken = crypto.randomBytes(32).toString('hex');

    const order = await EventOrder.create({
      phone,
      seatNumber,
      vendorId,
      items,
      subtotal,
      serviceCharge,
      total,
      deliveryConfirmationToken: deliveryToken,
      status: 'pending'
    });

  // Auto-reduce stock for ordered items
    try {
      for (const item of items) {
        if (item.productId) {
          const product = await Product.findById(item.productId);
          if (product && product.quantity >= item.qty) {
            product.quantity -= item.qty;
            await product.save();
            console.log(`Stock reduced for ${product.name}: -${item.qty} (${product.quantity} remaining)`);
          } else if (product) {
            console.warn(`Insufficient stock for ${product.name}. Ordered: ${item.qty}, Available: ${product.quantity}`);
          }
        }
      }
    } catch (stockError) {
      console.error('Stock reduction error:', stockError);
      // Continue with order even if stock update fails
    }

    // Notify consumer + dispatchers/admin that order was placed
    try {
      const io = req.app.get('io');
      // Send existing structured notifications (admin, order rooms, consumer)
      sendOrderNotification(io, order, 'placed', 'Your order has been placed successfully!');

      // Also emit a direct vendor-facing event so vendor dashboards listing "pending" orders
      // receive the new order in real-time. This targets common room keys used by the frontend:
      // - vendor user id (legacy plain id)
      // - user:<vendorId>
      // - order:<orderId> and order_<orderId>
      if (io && order && order.vendorId) {
        const vendorIdStr = String(order.vendorId);
        const payload = {
          orderId: String(order._id),
          seatNumber: order.seatNumber,
          phone: order.phone,
          status: order.status,
          total: order.total,
          items: order.items
        };

        io.to(vendorIdStr).emit('order:placed', payload);
        io.to(`user:${vendorIdStr}`).emit('order:placed', payload);
        io.to(`order:${String(order._id)}`).emit('order:placed', payload);
        io.to(`order_${String(order._id)}`).emit('order:placed', payload);
      }
    } catch (nErr) { console.error('notify createOrder', nErr && nErr.message); }

    res.json({ 
      success: true, 
      order: {
        _id: order._id,
        phone: order.phone,
        seatNumber: order.seatNumber,
        total: order.total,
        status: order.status
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Track order
export const trackOrder = async (req, res) => {
  try {
    const { orderId } = req.params;

    const order = await EventOrder.findById(orderId)
      .populate('vendorId', 'name profile')
      .populate('dispatcherId', 'name')
      .lean();

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // Generate QR code for the delivery token
    let qrCodeDataUrl = null;
    if (order.deliveryConfirmationToken) {
      qrCodeDataUrl = await QRCode.toDataURL(order.deliveryConfirmationToken);
    }

    res.json({ 
      success: true, 
      order: {
        ...order,
        qrCode: qrCodeDataUrl
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// =======================
// VENDOR ENDPOINTS
// =======================

// Get vendor's orders
export const getVendorOrders = async (req, res) => {
  try {
    const vendorId = req.user._id;

    const orders = await EventOrder.find({ vendorId })
      .populate('dispatcherId', 'name')
      .sort({ createdAt: -1 })
      .lean();

    res.json({ success: true, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Update order status (vendor)
export const updateOrderStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;
    const vendorId = req.user._id;

    const validStatuses = ['accepted', 'preparing', 'ready', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const order = await EventOrder.findOne({ _id: orderId, vendorId });
    
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    order.status = status;
    await order.save();

    // Emit socket event for real-time updates
    const io = req.app.get('io');
    if (io) {
      // Generic status update (legacy/listeners)
      io.emit('orderStatusUpdate', { orderId, status });

      // Targeted emits for frontend rooms used across the app
      const orderIdStr = String(order._id);
      const vendorIdStr = order.vendorId ? String(order.vendorId) : null;
      const payload = {
        orderId: orderIdStr,
        status,
        seatNumber: order.seatNumber,
        phone: order.phone,
        items: order.items,
        total: order.total,
        vendorId: vendorIdStr
      };

      // Emit status-specific events
      if (status === 'accepted') {
        // Notify dispatchers to consider this order
        io.to('dispatchers_room').emit('order:accepted', payload);
        // Notify admin and vendor rooms
        io.to('admin_room').emit('order:accepted', payload);
        if (vendorIdStr) {
          io.to(vendorIdStr).emit('order:accepted', payload);
          io.to(`user:${vendorIdStr}`).emit('order:accepted', payload);
        }
        // Also notify any listeners on the order room
        io.to(`order:${orderIdStr}`).emit('order:accepted', payload);
        io.to(`order_${orderIdStr}`).emit('order:accepted', payload);
      } else if (status === 'preparing') {
        io.to(`order:${orderIdStr}`).emit('order:preparing', payload);
        io.to('admin_room').emit('order:preparing', payload);
      } else if (status === 'ready') {
        // Ready orders should notify dispatchers (pickup) and order room
        io.to('dispatchers_room').emit('order:ready', { ...payload, pickup: true });
        io.to(`order:${orderIdStr}`).emit('order:ready', payload);
        io.to('admin_room').emit('order:ready', payload);
        if (vendorIdStr) {
          io.to(vendorIdStr).emit('order:ready', payload);
          io.to(`user:${vendorIdStr}`).emit('order:ready', payload);
        }
      } else if (status === 'cancelled') {
        io.to(`order:${orderIdStr}`).emit('order:cancelled', payload);
        io.to('admin_room').emit('order:cancelled', payload);
        if (vendorIdStr) io.to(vendorIdStr).emit('order:cancelled', payload);
      }
    }

    // Send friendly notifications to consumer (and other parties as appropriate)
    try {
      sendOrderNotification(req.app.get('io'), order, status, (
        status === 'accepted' ? 'Vendor accepted your order. Preparing your meal...' :
        status === 'preparing' ? 'Your order is being prepared.' :
        status === 'ready' ? 'Your order is ready for pickup.' :
        status === 'cancelled' ? 'Order cancelled.' :
        `Order status updated to ${status}`
      ));
    } catch (nErr) {
      console.error('notify updateOrderStatus', nErr && nErr.message);
    }

    res.json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get vendor earnings summary
export const getVendorEarnings = async (req, res) => {
  try {
    const vendorId = req.user._id;

    const orders = await EventOrder.find({ 
      vendorId, 
      'payment.paid': true 
    }).lean();

    const totalEarnings = orders.reduce((sum, order) => sum + order.subtotal, 0);
    const totalOrders = orders.length;

    res.json({ 
      success: true, 
      earnings: {
        totalEarnings,
        totalOrders,
        orders
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// =======================
// DISPATCHER ENDPOINTS
// =======================

// Get ready orders (for claiming)
export const getReadyOrders = async (req, res) => {
  try {
    const orders = await EventOrder.find({ 
      status: 'ready',
      dispatcherId: null 
    })
    .populate('vendorId', 'name profile')
    .sort({ createdAt: 1 })
    .lean();

    res.json({ success: true, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Claim order (dispatcher)
export const claimOrder = async (req, res) => {
  try {
    const { orderId } = req.body;
    const dispatcherId = req.user._id;

    // Use findOneAndUpdate with atomic operation to prevent race conditions
    // This ensures only ONE dispatcher can claim the order
    const order = await EventOrder.findOneAndUpdate(
      { 
        _id: orderId, 
        status: 'ready', 
        dispatcherId: null // Only claim if no dispatcher assigned yet
      },
      { 
        dispatcherId: dispatcherId,
        status: 'out_for_delivery'
      },
      { 
        new: true // Return the updated document
      }
    );

    // If order is null, it means another dispatcher already claimed it
    if (!order) {
      return res.status(409).json({ 
        success: false, 
        message: 'Order already claimed by another dispatcher or no longer available' 
      });
    }

    // Emit socket events with consistent payload (include vendor info + orderGroupId if present)
    const io = req.app.get('io');
    try {
      // Populate vendor info for richer payload
      const populated = await EventOrder.findById(order._id).populate('vendorId', 'name profile').lean();

      const payload = {
        orderId: String(order._id),
        dispatcherId: String(dispatcherId),
        seatNumber: order.seatNumber,
        phone: order.phone,
        status: order.status,
        items: order.items,
        total: order.total,
        vendorId: populated?.vendorId?._id ? String(populated.vendorId._id) : (order.vendorId ? String(order.vendorId) : null),
        vendorName: populated?.vendorId?.name || null,
        orderGroupId: populated?.orderGroupId || null
      };

      if (io) {
        // Backwards-compatible raw event
        io.emit('orderClaimed', { orderId: String(order._id), dispatcherId: String(dispatcherId), seatNumber: order.seatNumber });

        // New, namespaced events for frontend consumers
        io.to('dispatchers_room').emit('order:in_transit', payload);
        io.to(`order:${String(order._id)}`).emit('order:in_transit', payload);
        io.to(`order_${String(order._id)}`).emit('order:in_transit', payload);

        // Notify admin and vendor rooms as well
        io.to('admin_room').emit('order:in_transit', payload);
        if (payload.vendorId) {
          io.to(payload.vendorId).emit('order:in_transit', payload);
          io.to(`user:${payload.vendorId}`).emit('order:in_transit', payload);
        }
      }

      try {
        sendOrderNotification(io, order, 'in_transit', 'Your order is now on the way.');
      } catch (nErr) { console.error('notify claimOrder', nErr && nErr.message); }
    } catch (emitErr) {
      console.error('emit claimOrder error', emitErr && emitErr.message);
    }

    res.json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Confirm delivery (with QR verification)
export const confirmDelivery = async (req, res) => {
  try {
    const { orderId, qrToken } = req.body;
    const dispatcherId = req.user._id;

    const order = await EventOrder.findOne({ _id: orderId, dispatcherId });

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found or not assigned to you' });
    }

    if (order.deliveryConfirmationToken !== qrToken) {
      return res.status(400).json({ success: false, message: 'Invalid QR token' });
    }

    order.status = 'delivered';
    order.deliveryConfirmedAt = new Date();
    await order.save();

    // Emit socket event
    const io = req.app.get('io');
    try {
      // Populate vendor for payload enrichment
      const populated = await EventOrder.findById(order._id).populate('vendorId', 'name profile').lean();
      const payload = {
        orderId: String(order._id),
        status: order.status,
        deliveredAt: order.deliveryConfirmedAt,
        phone: order.phone,
        seatNumber: order.seatNumber,
        items: order.items,
        total: order.total,
        vendorId: populated?.vendorId?._id ? String(populated.vendorId._id) : (order.vendorId ? String(order.vendorId) : null),
        vendorName: populated?.vendorId?.name || null,
        orderGroupId: populated?.orderGroupId || null
      };

      if (io) {
        // Backwards-compatible event
        io.emit('orderDelivered', { orderId: String(order._id) });

        // Namespaced event
        io.to(`order:${String(order._id)}`).emit('order:delivered', payload);
        io.to(`order_${String(order._id)}`).emit('order:delivered', payload);
        io.to('admin_room').emit('order:delivered', payload);
        if (payload.vendorId) {
          io.to(payload.vendorId).emit('order:delivered', payload);
          io.to(`user:${payload.vendorId}`).emit('order:delivered', payload);
        }
      }

      try {
        sendOrderNotification(io, order, 'delivered', 'Order delivered successfully! Please rate your experience.');
      } catch (nErr) { console.error('notify confirmDelivery', nErr && nErr.message); }
    } catch (emitErr) {
      console.error('emit confirmDelivery error', emitErr && emitErr.message);
    }

    res.json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get dispatcher's delivery stats
export const getDispatcherStats = async (req, res) => {
  try {
    const dispatcherId = req.user._id;

    const deliveredOrders = await EventOrder.find({ 
      dispatcherId, 
      status: 'delivered' 
    }).lean();

    const activeOrders = await EventOrder.find({ 
      dispatcherId, 
      status: 'out_for_delivery' 
    })
    .populate('vendorId', 'name')
    .lean();

    res.json({ 
      success: true, 
      stats: {
        totalDeliveries: deliveredOrders.length,
        activeDeliveries: activeOrders.length,
        activeOrders
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// =======================
// ADMIN ENDPOINTS
// =======================

// Get all orders (admin)
export const getAllOrders = async (req, res) => {
  try {
    const orders = await EventOrder.find()
      .populate('vendorId', 'name profile')
      .populate('dispatcherId', 'name')
      .sort({ createdAt: -1 })
      .lean();

    res.json({ success: true, orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get event summary (admin)
export const getEventSummary = async (req, res) => {
  try {
    const totalOrders = await EventOrder.countDocuments();
    const paidOrders = await EventOrder.countDocuments({ 'payment.paid': true });
    
    const orders = await EventOrder.find({ 'payment.paid': true }).lean();
    
    const totalRevenue = orders.reduce((sum, order) => sum + order.total, 0);
    const totalServiceCharges = orders.reduce((sum, order) => sum + order.serviceCharge, 0);
    const totalVendorEarnings = orders.reduce((sum, order) => sum + order.subtotal, 0);

    // Vendor breakdown
    const vendorBreakdown = {};
    for (const order of orders) {
      const vendorId = order.vendorId.toString();
      if (!vendorBreakdown[vendorId]) {
        vendorBreakdown[vendorId] = {
          vendorId,
          totalOrders: 0,
          totalEarnings: 0
        };
      }
      vendorBreakdown[vendorId].totalOrders += 1;
      vendorBreakdown[vendorId].totalEarnings += order.subtotal;
    }

    // Populate vendor names
    const vendorIds = Object.keys(vendorBreakdown);
    const vendors = await User.find({ _id: { $in: vendorIds } }).select('name').lean();
    
    vendors.forEach(vendor => {
      vendorBreakdown[vendor._id.toString()].vendorName = vendor.name;
    });

    res.json({ 
      success: true, 
      summary: {
        totalOrders,
        paidOrders,
        totalRevenue,
        totalServiceCharges,
        totalVendorEarnings,
        vendorBreakdown: Object.values(vendorBreakdown)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Verify payment (Paystack webhook will call this)
export const verifyPayment = async (req, res) => {
  try {
    const { reference, orderId } = req.body;

    const order = await EventOrder.findById(orderId);
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // Mark payment as verified
    order.payment = {
      reference,
      paid: true,
      verifiedAt: new Date()
    };
    await order.save();

    // Update vendor wallet (internal tracking)
    const vendor = await User.findById(order.vendorId);
    if (vendor) {
      vendor.wallet += order.subtotal;
      await vendor.save();
    }

    // Emit socket event
    const io = req.app.get('io');
    if (io) {
      io.emit('paymentVerified', { orderId: order._id });
    }

    res.json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
