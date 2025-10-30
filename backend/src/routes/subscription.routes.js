import express from 'express'
import Subscription from '../models/Subscription.js'
import User from '../models/User.js'
import { authRequired } from '../middleware/auth.js'

const router = express.Router()

const PLAN_AMOUNTS = { basic: 25000, standard: 50000, premium: 75000 }

// Create subscription (requires payment)
router.post('/', authRequired('customer'), async (req, res) => {
  const { plan, deliveryTimeDaily = '12:00', autoRenew = true } = req.body
  if (!PLAN_AMOUNTS[plan]) return res.status(400).json({ error: 'Invalid plan' })
  const s = await Subscription.create({
    user: req.user.id,
    plan,
    amount: PLAN_AMOUNTS[plan],
    deliveryTimeDaily,
    autoRenew,
    status: 'pending',
  })
  res.json({ subscription: s })
})

// My subscriptions
router.get('/mine', authRequired('customer'), async (req, res) => {
  const items = await Subscription.find({ user: req.user.id }).sort({ createdAt: -1 })
  res.json({ items })
})

// Admin list
router.get('/', authRequired('admin'), async (req, res) => {
  const items = await Subscription.find({}).sort({ createdAt: -1 })
  res.json({ items })
})

export default router
