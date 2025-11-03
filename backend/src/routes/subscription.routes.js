import express from 'express'
import Subscription from '../models/Subscription.js'
import User from '../models/User.js'
import { authRequired } from '../middleware/auth.js'

const router = express.Router()

// ✅ Plan amounts: Basic ₦25k, Standard ₦50k, Premium ₦75k
const PLAN_AMOUNTS = { basic: 25000, standard: 50000, premium: 75000 }

// ✅ Create subscription (consumer subscribes, payment goes to QuickServe admin)
router.post('/', authRequired('consumer'), async (req, res) => {
  const { 
    plan, 
    mealSchedule, // { breakfast: { enabled, time }, lunch: { enabled, time }, dinner: { enabled, time } }
    deliveryAddress,
    autoRenew = true 
  } = req.body
  
  if (!PLAN_AMOUNTS[plan]) {
    return res.status(400).json({ error: 'Invalid plan. Choose: basic, standard, or premium' })
  }
  
  if (!deliveryAddress) {
    return res.status(400).json({ error: 'Delivery address is required' })
  }
  
  // Validate at least one meal is selected
  const hasSchedule = mealSchedule && (
    mealSchedule.breakfast?.enabled || 
    mealSchedule.lunch?.enabled || 
    mealSchedule.dinner?.enabled
  )
  
  if (!hasSchedule) {
    return res.status(400).json({ error: 'Please select at least one meal time (breakfast, lunch, or dinner)' })
  }
  
  const s = await Subscription.create({
    user: req.user.id,
    plan,
    amount: PLAN_AMOUNTS[plan],
    mealSchedule: mealSchedule || {
      breakfast: { enabled: false, time: '08:00' },
      lunch: { enabled: false, time: '13:00' },
      dinner: { enabled: false, time: '19:00' }
    },
    deliveryAddress,
    autoRenew,
    status: 'pending', // Will be 'active' after payment
    isAdminManaged: true, // QuickServe admin handles this
  })
  
  res.json({ subscription: s })
})

// ✅ Activate subscription after payment (webhook or manual)
router.post('/:id/activate', authRequired('admin'), async (req, res) => {
  const { paymentRef, periodDays = 30 } = req.body
  const s = await Subscription.findById(req.params.id)
  if (!s) return res.status(404).json({ error: 'Subscription not found' })
  
  s.status = 'active'
  s.paymentRef = paymentRef
  s.periodStart = new Date()
  s.periodEnd = new Date(Date.now() + periodDays * 24 * 60 * 60 * 1000)
  await s.save()
  
  res.json({ subscription: s, message: 'Subscription activated successfully' })
})

// ✅ Get my subscriptions (consumer)
router.get('/mine', authRequired('consumer'), async (req, res) => {
  const items = await Subscription.find({ user: req.user.id }).sort({ createdAt: -1 })
  res.json({ items })
})

// ✅ Admin: List ALL subscriptions with notifications for scheduled deliveries
router.get('/admin/all', authRequired('admin'), async (req, res) => {
  const items = await Subscription.find({})
    .populate('user', 'name email phone')
    .sort({ createdAt: -1 })
  res.json({ items })
})

// ✅ Admin: Get today's scheduled deliveries (for notifications)
router.get('/admin/today-deliveries', authRequired('admin'), async (req, res) => {
  try {
    const now = new Date()
    const currentHour = now.getHours()
    const currentMinute = now.getMinutes()
    const currentTime = `${String(currentHour).padStart(2, '0')}:${String(currentMinute).padStart(2, '0')}`
    
    const activeSubscriptions = await Subscription.find({ status: 'active' })
      .populate('user', 'name email phone')
    
    const deliveries = []
    
    for (const sub of activeSubscriptions) {
      const { mealSchedule } = sub
      
      // Check each meal time
      if (mealSchedule?.breakfast?.enabled && mealSchedule.breakfast.time === currentTime) {
        deliveries.push({
          subscriptionId: sub._id,
          user: sub.user,
          plan: sub.plan,
          mealType: 'breakfast',
          scheduledTime: mealSchedule.breakfast.time,
          deliveryAddress: sub.deliveryAddress
        })
      }
      
      if (mealSchedule?.lunch?.enabled && mealSchedule.lunch.time === currentTime) {
        deliveries.push({
          subscriptionId: sub._id,
          user: sub.user,
          plan: sub.plan,
          mealType: 'lunch',
          scheduledTime: mealSchedule.lunch.time,
          deliveryAddress: sub.deliveryAddress
        })
      }
      
      if (mealSchedule?.dinner?.enabled && mealSchedule.dinner.time === currentTime) {
        deliveries.push({
          subscriptionId: sub._id,
          user: sub.user,
          plan: sub.plan,
          mealType: 'dinner',
          scheduledTime: mealSchedule.dinner.time,
          deliveryAddress: sub.deliveryAddress
        })
      }
    }
    
    res.json({ 
      deliveries,
      currentTime,
      count: deliveries.length 
    })
  } catch (e) {
    res.status(500).json({ error: e.message })
  }
})

// ✅ Admin: Pause/Cancel subscription
router.post('/:id/status', authRequired('admin'), async (req, res) => {
  const { status } = req.body // 'active', 'paused', 'cancelled'
  const s = await Subscription.findById(req.params.id)
  if (!s) return res.status(404).json({ error: 'Subscription not found' })
  
  s.status = status
  await s.save()
  
  res.json({ subscription: s, message: `Subscription ${status}` })
})

export default router
