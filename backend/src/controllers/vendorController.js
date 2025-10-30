import Product from '../models/Product.js'
import Order from '../models/Order.js'
import Transaction from '../models/Transaction.js'

// Create product (expects multipart with field 'image')
export const createProduct = async (req, res) => {
  try {
    const { name, price, quantity, description, prepDurationMins } = req.body
    if (!name || !price || !quantity) return res.status(400).json({ error: 'Missing fields' })

    const imageUrl = req.file ? `/uploads/${req.file.filename}` : req.body.imageUrl
    const product = await Product.create({
      vendorId: req.user._id,
      name,
      price: Number(price),
      quantity: Number(quantity),
      description,
      ...(prepDurationMins ? { prepDurationMins: Number(prepDurationMins) } : {}),
      imageUrl,
    })
    res.json({ product })
  } catch (e) {
    console.error('createProduct error', e)
    res.status(500).json({ error: 'Failed to create product' })
  }
}

export const listProducts = async (req, res) => {
  const products = await Product.find({ vendorId: req.user._id }).sort('-createdAt')
  res.json(products)
}

// Vendor packs an order: mark ready and charge ₦50 service fee to platform
export const packOrder = async (req, res) => {
  try {
    const { id } = req.params
    const order = await Order.findOne({ _id: id, vendorId: req.user._id })
    if (!order) return res.status(404).json({ error: 'Order not found' })

    order.status = 'ready'
    await order.save()

    // ₦50 service fee to platform (admin)
    const fee = Number(process.env.PACKING_FEE || 50)
    await Transaction.create({ user: null, order: order._id, amount: fee, type: 'credit', meta: { reason: 'packing_fee' } })

    res.json({ ok: true, order })
  } catch (e) {
    console.error('packOrder error', e)
    res.status(500).json({ error: 'Failed to pack order' })
  }
}

// Wallet balance and next withdrawal date (placeholder sums)
export const getWallet = async (req, res) => {
  // Sum of vendor transactions; if none yet, 0
  const tx = await Transaction.aggregate([
    { $match: { user: req.user._id, type: 'credit' } },
    { $group: { _id: null, total: { $sum: '$amount' } } }
  ])
  const balance = tx[0]?.total || 0
  // weekly schedule placeholder
  const now = new Date()
  const nextWithdrawAt = new Date(now.getTime() + 6 * 24 * 60 * 60 * 1000)
  res.json({ balance, currency: 'NGN', nextWithdrawAt })
}

export const requestWithdraw = async (req, res) => {
  // Placeholder: accept request and respond; backend rule to enforce weekly cadence can be added
  res.json({ ok: true, scheduled: true })
}

export const setNotificationPref = async (req, res) => {
  try {
    const { incomingOrderAlerts } = req.body
    req.user.profile = req.user.profile || {}
    req.user.profile.incomingOrderAlerts = Boolean(incomingOrderAlerts)
    await req.user.save()
    res.json({ ok: true, profile: req.user.profile })
  } catch (e) {
    console.error('setNotificationPref error', e)
    res.status(500).json({ error: 'Failed to update settings' })
  }
}
import Vendor from '../models/Vendor.js'
import User from '../models/User.js'
export async function createVendor(req,res){ const {storeName,userId}=req.body; const u=await User.findById(userId); if(!u) return res.status(404).json({error:'User not found'}); const v=await Vendor.create({user:u._id,storeName}); res.json(v) }
