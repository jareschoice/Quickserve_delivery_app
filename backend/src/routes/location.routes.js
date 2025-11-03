// ===============================
// FILE: backend/src/routes/location.routes.js
// ===============================
import express from 'express'
import User from '../models/User.js'
import Order from '../models/Order.js'
import { authRequired } from '../middleware/auth.js'
import { isValidLatLng } from '../utils/geo.js'

const router = express.Router()

/**
 * Rider updates their live location.
 * Body: { lat: Number, lng: Number, orderId?: String }
 * Emits: socket event "rider:location" to room `rider:<riderId>` and `order:<orderId>` if provided
 */
router.post('/rider/update', authRequired('rider'), async (req, res) => {
  try {
    const { lat, lng, orderId } = req.body
    if (!isValidLatLng(lat, lng)) return res.status(400).json({ error: 'Invalid coordinates' })

    const rider = await User.findById(req.user._id)
    if (!rider) return res.status(404).json({ error: 'Rider not found' })

    rider.profile = rider.profile || {}
    rider.profile.currentLocation = { lat: Number(lat), lng: Number(lng), updatedAt: new Date() }
    await rider.save()

    // Emit to rider room and order room (if any)
    try {
      const io = req.app.get('io')
      if (io) {
        io.to(`rider:${rider._id}`).emit('rider:location', {
          riderId: rider._id,
          lat: rider.profile.currentLocation.lat,
          lng: rider.profile.currentLocation.lng,
          updatedAt: rider.profile.currentLocation.updatedAt
        })
        if (orderId) {
          io.to(`order:${orderId}`).emit('rider:location', {
            riderId: rider._id,
            lat: rider.profile.currentLocation.lat,
            lng: rider.profile.currentLocation.lng,
            updatedAt: rider.profile.currentLocation.updatedAt
          })
        }
      }
    } catch (e) {
      console.warn('Socket emit failed:', e.message)
    }

    return res.json({ success: true, location: rider.profile.currentLocation })
  } catch (e) {
    console.error('updateLocation error:', e)
    return res.status(500).json({ error: 'Failed to update location' })
  }
})

/**
 * Public: Get latest location of a rider by riderId
 * GET /api/location/rider/:riderId
 */
router.get('/rider/:riderId', authRequired(), async (req, res) => {
  try {
    const { riderId } = req.params
    const rider = await User.findById(riderId).select('profile.currentLocation name email')
    if (!rider) return res.status(404).json({ error: 'Rider not found' })
    return res.json({ success: true, rider: { id: rider._id, name: rider.name, currentLocation: rider.profile?.currentLocation || null } })
  } catch (e) {
    console.error('getRiderLocation error:', e)
    return res.status(500).json({ error: 'Failed to fetch rider location' })
  }
})

/**
 * Optional: Get rider location for an order (if order has rider assigned)
 * GET /api/location/order/:orderId
 */
router.get('/order/:orderId', authRequired(), async (req, res) => {
  try {
    const { orderId } = req.params
    const order = await Order.findById(orderId)
    if (!order) return res.status(404).json({ error: 'Order not found' })
    if (!order.riderId) return res.status(400).json({ error: 'No rider assigned yet' })
    const rider = await User.findById(order.riderId).select('profile.currentLocation name')
    if (!rider) return res.status(404).json({ error: 'Rider not found' })
    return res.json({ success: true, rider: { id: rider._id, name: rider.name, currentLocation: rider.profile?.currentLocation || null } })
  } catch (e) {
    console.error('getOrderRiderLocation error:', e)
    return res.status(500).json({ error: 'Failed to fetch rider location for order' })
  }
})

export default router
