// ===============================
// FILE: backend/src/middleware/paymentVerification.js
// PURPOSE: Verify payment before allowing order operations
// ===============================
import Order from '../models/Order.js'

/**
 * Middleware to verify that an order has been paid before allowing operations
 * Use this on routes like GET /api/orders/:id, PUT /api/orders/:id/status
 */
export const requirePaidOrder = async (req, res, next) => {
  try {
    const orderId = req.params.id || req.params.orderId

    if (!orderId) {
      return res.status(400).json({ error: 'Order ID required' })
    }

    const order = await Order.findById(orderId)

    if (!order) {
      return res.status(404).json({ error: 'Order not found' })
    }

    // Check if payment is verified
    if (!order.payment || !order.payment.paid) {
      return res.status(403).json({ 
        error: 'Payment required',
        message: 'This order has not been paid. Please complete payment first.',
        orderId: order._id
      })
    }

    // Check if payment reference exists
    if (!order.payment.reference) {
      return res.status(403).json({ 
        error: 'Invalid payment',
        message: 'Order payment verification failed.',
        orderId: order._id
      })
    }

    // Attach order to request for use in route handler
    req.order = order
    next()

  } catch (error) {
    console.error('requirePaidOrder middleware error:', error)
    res.status(500).json({ 
      error: 'Payment verification failed',
      detail: error.message 
    })
  }
}

/**
 * Middleware to prevent direct order creation without payment
 * Use this on POST /api/orders/ to block unpaid orders
 */
export const blockUnpaidOrderCreation = (req, res, next) => {
  return res.status(403).json({
    error: 'Direct order creation blocked',
    message: 'Orders must be created through payment flow. Use POST /api/payments/init-order-payment instead.',
    correctEndpoint: '/api/payments/init-order-payment'
  })
}
