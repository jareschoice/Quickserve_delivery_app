import QRCode from 'qrcode'
import crypto from 'crypto'
import Order from '../models/Order.js'
import Transaction from '../models/Transaction.js'
import { sendEmail } from '../utils/emailClient.js' // ✅ FIXED HERE
import { orderStatusEmail } from '../utils/emailTemplates.js'

const fees = {
  platform: Number(process.env.COMMISSION_PLATFORM || 50),
  vendor: Number(process.env.COMMISSION_VENDOR || 50),
  rider: Number(process.env.COMMISSION_RIDER || 50),
}

// ✅ Create new order
export const createOrder = async (req, res) => {
  try {
    const { vendorId, items, deliveryAddress, distanceKm, notes } = req.body
    if (!vendorId || !items?.length) {
      return res.status(400).json({ error: 'Missing required fields' })
    }

    const subtotal = items.reduce((s, i) => s + (i.price || 0) * (i.qty || 1), 0)
    const deliveryFee = Math.max(300, Math.round((distanceKm || 1) * 120))
    const platformFee = fees.platform
    const total = subtotal + deliveryFee + platformFee
    const qrToken = crypto.randomBytes(12).toString('hex')

    const consumerId = req.user.id || req.user._id || req.user._userId
    const order = await Order.create({
      consumerId,
      vendorId,
      items,
      subtotal,
      deliveryFee,
      platformFee,
      total,
      status: 'placed',
      distanceKm,
      deliveryAddress,
      notes,
      qrToken
    })

    const qrDataUrl = await QRCode.toDataURL(qrToken)

    // create transaction crediting platform (admin)
    try {
      await Transaction.create({
        user: null, // platform transaction (no user)
        order: order._id,
        amount: platformFee,
        type: 'credit',
        meta: { reason: 'platform_fee' }
      })
    } catch (txErr) {
      console.error('transaction create failed', txErr)
    }

    // emit socket event for order created
    try {
      const io = req.app.locals.io
      io.emit('order.created', { orderId: order._id, status: order.status })
    } catch (e) {
      console.error('socket emit failed', e)
    }
    res.json({ order, qrDataUrl })
  } catch (e) {
    console.error('createOrder error:', e)
    res.status(500).json({ error: 'Failed to create order' })
  }
}

// ✅ Update order status + send email notification
export const setStatus = async (req, res) => {
  const { id } = req.params
  const { status } = req.body
  const allowed = [
    'accepted',
    'preparing',
    'ready',
    'dispatch_requested',
    'assigned',
    'in_transit',
    'delivered',
    'cancelled'
  ]

  if (!allowed.includes(status)) return res.status(400).json({ error: 'Bad status' })
  const order = await Order.findById(id)
  if (!order) return res.status(404).json({ error: 'Order not found' })

  order.status = status
  await order.save()

  try {
    await sendEmail({
      to: req.user.email,
      subject: `Order Update: ${status}`,
      html: orderStatusEmail(status, order._id),
    })
  } catch (e) {
    console.log('Email failed:', e.message)
  }

  // Credit vendor upon delivery (show earnings in wallet)
  if (status === 'delivered') {
    try {
      await Transaction.create({
        user: order.vendorId,
        order: order._id,
        amount: order.subtotal || 0,
        type: 'credit',
        meta: { reason: 'vendor_payout_pending' }
      })
    } catch (txErr) {
      console.error('vendor credit create failed', txErr)
    }
  }

  // emit socket event for status change
  try {
    const io = req.app.locals.io
    io.emit('order.status.updated', { orderId: order._id, status: order.status })
  } catch (e) {
    console.error('socket emit failed', e)
  }

  res.json({ ok: true, order })
}

// ✅ Confirm delivery by QR code
export const confirmDelivery = async (req, res) => {
  const { id } = req.params
  const { qrToken } = req.body
  const order = await Order.findById(id)
  if (!order) return res.status(404).json({ error: 'Not found' })
  if (order.qrToken !== qrToken) return res.status(400).json({ error: 'QR mismatch' })

  order.status = 'delivered'
  await order.save()
  res.json({ ok: true, order })
}

// ✅ Get orders by user role
export const myOrders = async (req, res) => {
  const role = req.user.role
  const filter =
    role === 'consumer'
      ? { consumerId: req.user._id }
      : role === 'vendor'
      ? { vendorId: req.user._id }
      : role === 'rider'
      ? { riderId: req.user._id }
      : {}

  const orders = await Order.find(filter).sort('-createdAt')
  res.json(orders)
}