// ===============================
// FILE: backend/controllers/orderController.js
// ===============================
import Order from '../models/Order.js'
import Product from '../models/Product.js'
import Vendor from '../models/Vendor.js'
import Transaction from '../models/Transaction.js'
import { sendOrderNotification } from '../utils/notify.js'

// =====================================
// ✳️ CUSTOMER CREATES AN ORDER
// =====================================
export const createOrder = async (req, res) => {
  try {
    const { items, vendorId, deliveryAddress, notes, paymentMethod, seatNumber, phoneNumber } = req.body

    if (!items || items.length === 0)
      return res.status(400).json({ error: 'Order must contain items' })

    const vendor = await Vendor.findById(vendorId)
    if (!vendor) return res.status(404).json({ error: 'Vendor not found' })

    let subtotal = 0
    const orderItems = []

    for (const i of items) {
      const product = await Product.findById(i.productId)
      if (!product) continue
      const subtotalItem = product.price * i.qty
      subtotal += subtotalItem
      orderItems.push({
        productId: product._id,
        name: product.name,
        price: product.price,
        qty: i.qty,
        imageUrl: product.imageUrl,
        subtotal: subtotalItem
      })
    }

    const deliveryFee = 200
    const platformFee = 50
    const total = subtotal + deliveryFee + platformFee

    // ✅ Create new order
    const order = await Order.create({
      consumerId: req.user._id,
      vendorId,
      items: orderItems,
      subtotal,
      deliveryFee,
      platformFee,
      total,
      deliveryAddress,
      notes,
      seatNumber,
      phoneNumber,
      payment: { channel: paymentMethod || 'cash', paid: false },
      status: 'placed'
    })

    // ✅ Emit to dispatchers
    try {
      const io = req.app.get('io')
      if (io) {
        io.to('dispatchers_room').emit('new_delivery_request', {
          orderId: order._id,
          seatNumber,
          phoneNumber,
          totalAmount: total,
          items: orderItems,
          vendor: {
            businessName: vendor.storeName,
            businessAddress: vendor.businessAddress || 'AutoFest Arena',
            phone: vendor.phoneNumber || 'N/A'
          }
        })
        console.log(`📦 Order emitted to dispatchers: ${order._id}`)
      }
    } catch (emitErr) {
      console.error('Socket emit failed:', emitErr.message)
    }

    // Send placed notification
    try {
      sendOrderNotification(req.app.get('io'), order, 'placed', 'Your order has been placed successfully!');
    } catch (nErr) { console.error('notify createOrder', nErr && nErr.message); }

    res.status(201).json({ success: true, message: 'Order placed successfully', order })
  } catch (e) {
    console.error('createOrder error', e)
    res.status(500).json({ error: 'Failed to create order' })
  }
}

// =====================================
// ✳️ GET CUSTOMER ORDERS
// =====================================
export const getCustomerOrders = async (req, res) => {
  try {
    const orders = await Order.find({ consumerId: req.user._id })
      .sort('-createdAt')
      .populate('vendorId', 'storeName')
    res.json({ success: true, orders })
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch orders' })
  }
}

// =====================================
// ✳️ GET VENDOR ORDERS
// =====================================
export const getVendorOrders = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ user: req.user._id })
    if (!vendor) return res.status(404).json({ error: 'Vendor not found' })

    const orders = await Order.find({ vendorId: vendor._id }).sort('-createdAt')
    res.json({ success: true, orders })
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch vendor orders' })
  }
}

// =====================================
// ✳️ UPDATE ORDER STATUS
// =====================================
export const updateOrderStatus = async (req, res) => {
  try {
    const { id } = req.params
    const { status } = req.body
    const order = await Order.findById(id)
    if (!order) return res.status(404).json({ error: 'Order not found' })

    const now = new Date()
    order.status = status

    if (status === 'accepted') order.acceptedAt = now
    if (status === 'preparing') order.preparedAt = now
    if (status === 'ready') order.readyAt = now
    if (status === 'in_transit') order.pickedAt = now
    if (status === 'delivered') {
      order.deliveredAt = now
      order.isPaidToVendor = true

      // Auto credit vendor
      const vendor = await Vendor.findById(order.vendorId)
      if (vendor) {
        vendor.wallet += order.subtotal
        await vendor.save()
      }

      await Transaction.create({
        user: order.vendorId,
        amount: order.subtotal,
        type: 'credit',
        meta: { reason: 'order_delivery', orderId: order._id }
      })
    }

    await order.save()
    // Send notifications according to status
    try {
      const msg = status === 'accepted' ? 'Vendor accepted your order. Preparing your meal...' :
        status === 'preparing' ? 'Your order is being prepared.' :
        status === 'ready' ? 'Your order is ready for pickup.' :
        status === 'in_transit' ? 'Your order is now on the way.' :
        status === 'delivered' ? 'Order delivered successfully! Please rate your experience.' :
        `Order updated to ${status}`

      sendOrderNotification(req.app.get('io'), order, status, msg)
    } catch (nErr) {
      console.error('notify updateOrderStatus', nErr && nErr.message)
    }

    res.json({ success: true, message: `Order updated to ${status}`, order })
  } catch (e) {
    res.status(500).json({ error: 'Failed to update order status' })
  }
}

// =====================================
// ✳️ FEEDBACK + ANALYTICS
// =====================================
export const rateOrder = async (req, res) => {
  try {
    const { id } = req.params
    const { rating, feedback } = req.body

    const order = await Order.findById(id)
    if (!order) return res.status(404).json({ error: 'Order not found' })

    order.rating = rating
    order.feedback = feedback
    await order.save()

    res.json({ success: true, message: 'Feedback submitted', order })
  } catch (e) {
    res.status(500).json({ error: 'Failed to rate order' })
  }
}

export const getOrderAnalytics = async (req, res) => {
  try {
    const totalOrders = await Order.countDocuments()
    const totalDelivered = await Order.countDocuments({ status: 'delivered' })
    const totalCancelled = await Order.countDocuments({ status: 'cancelled' })
    const totalRevenue = await Order.aggregate([
      { $match: { status: 'delivered' } },
      { $group: { _id: null, revenue: { $sum: '$subtotal' } } }
    ])
    res.json({
      success: true,
      analytics: {
        totalOrders,
        totalDelivered,
        totalCancelled,
        totalRevenue: totalRevenue[0]?.revenue || 0
      }
    })
  } catch (e) {
    res.status(500).json({ error: 'Failed to fetch analytics' })
  }
}
