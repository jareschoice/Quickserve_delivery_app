// ===============================
// FILE: backend/src/controllers/adminController.js
// ===============================
import Order from '../models/Order.js'
import Transaction from '../models/Transaction.js'
import User from '../models/User.js'
import Vendor from '../models/Vendor.js'
import WithdrawalRequest from '../models/WithdrawalRequest.js'
import { adjustUserWallet, adjustVendorWallet } from '../utils/wallet.js'
import { sendNotification, notifyAdmin } from '../utils/notify.js'
import { sendMail } from '../lib/email.js';
 // optional email
import { generatePaymentReceiptHTML } from '../utils/paymentReceipt.js' // if you use receipts

// -----------------------------
// Admin: Dashboard Overview
// GET /api/admin/overview
// -----------------------------
export const overview = async (req, res) => {
  try {
    // orders counts
    const totalOrders = await Order.countDocuments()
    const delivered = await Order.countDocuments({ status: 'delivered' })
    const cancelled = await Order.countDocuments({ status: 'cancelled' })

    // revenue (delivered subtotal)
    const revenueAgg = await Order.aggregate([
      { $match: { status: 'delivered' } },
      { $group: { _id: null, revenue: { $sum: '$subtotal' } } }
    ])

    // transactions summary
    const totalTransactions = await Transaction.countDocuments()
    const totalRefundsAgg = await Transaction.aggregate([
      { $match: { 'meta.reason': 'refund' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ])

    // users
    const totalUsers = await User.countDocuments()
    const totalVendors = await User.countDocuments({ role: 'vendor' })
    const totalRiders = await User.countDocuments({ role: 'rider' })
    const totalCustomers = await User.countDocuments({ role: 'customer' })

    // wallets total
    const walletsAgg = await User.aggregate([{ $group: { _id: null, total: { $sum: '$wallet' } } }])

    // pending withdrawal requests
    const pendingWithdrawals = await WithdrawalRequest.countDocuments({ status: 'pending' })

    res.json({
      success: true,
      data: {
        orders: { total: totalOrders, delivered, cancelled },
        revenue: revenueAgg[0]?.revenue || 0,
        transactions: { total: totalTransactions, totalRefunds: totalRefundsAgg[0]?.total || 0 },
        users: { total: totalUsers, vendors: totalVendors, riders: totalRiders, customers: totalCustomers },
        walletsTotal: walletsAgg[0]?.total || 0,
        pendingWithdrawals
      }
    })
  } catch (err) {
    console.error('admin.overview error', err)
    res.status(500).json({ error: 'Failed to fetch overview' })
  }
}

// -----------------------------
// Admin: List users with filters / pagination
// GET /api/admin/users
// query: page, limit, role, q (email or name)
// -----------------------------
export const listUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1
    const limit = parseInt(req.query.limit) || 20
    const skip = (page - 1) * limit
    const { role, q } = req.query

    const filter = {}
    if (role) filter.role = role
    if (q) filter.$or = [{ email: { $regex: q, $options: 'i' } }, { name: { $regex: q, $options: 'i' } }]

    const users = await User.find(filter).skip(skip).limit(limit).sort({ createdAt: -1 })
    const total = await User.countDocuments(filter)

    res.json({ success: true, pagination: { page, totalPages: Math.ceil(total / limit), total }, users })
  } catch (err) {
    console.error('admin.listUsers error', err)
    res.status(500).json({ error: 'Failed to fetch users' })
  }
}

// -----------------------------
// Admin: Get user detail
// GET /api/admin/users/:id
// -----------------------------
export const getUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).lean()
    if (!user) return res.status(404).json({ error: 'User not found' })
    res.json({ success: true, user })
  } catch (err) {
    console.error('admin.getUser error', err)
    res.status(500).json({ error: 'Failed to fetch user' })
  }
}

// -----------------------------
// Admin: Update user (role, kycStatus, suspend)
// PATCH /api/admin/users/:id
// body: { role?, kycStatus?, suspend? (boolean), name?, email? }
// -----------------------------
export const updateUser = async (req, res) => {
  try {
    const { role, kycStatus, suspend, name, email } = req.body
    const u = await User.findById(req.params.id)
    if (!u) return res.status(404).json({ error: 'User not found' })

    if (role) u.role = role
    if (kycStatus) u.kycStatus = kycStatus
    if (name) u.name = name
    if (email) u.email = email
    // suspend: optionally add a field in user or we can use kycStatus for block — here we add 'suspended' meta
    if (suspend !== undefined) u.profile = u.profile || {}, u.profile.suspended = Boolean(suspend)

    await u.save()
    res.json({ success: true, user: u })
  } catch (err) {
    console.error('admin.updateUser error', err)
    res.status(500).json({ error: 'Failed to update user' })
  }
}

// -----------------------------
// Admin: Transactions list with filters
// GET /api/admin/transactions
// query: page, limit, type, reason, q
// -----------------------------
export const listTransactions = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1
    const limit = parseInt(req.query.limit) || 20
    const skip = (page - 1) * limit
    const { type, reason, q } = req.query

    const filter = {}
    if (type) filter.type = type // credit/debit
    if (reason) filter['meta.reason'] = reason
    if (q) filter.$or = [{ 'meta.order': { $regex: q, $options: 'i' } }, { 'meta.reference': { $regex: q, $options: 'i' } }]

    const txs = await Transaction.find(filter).skip(skip).limit(limit).sort({ createdAt: -1 }).populate('user', 'name email role')
    const total = await Transaction.countDocuments(filter)
    res.json({ success: true, pagination: { page, totalPages: Math.ceil(total / limit), total }, transactions: txs })
  } catch (err) {
    console.error('admin.listTransactions error', err)
    res.status(500).json({ error: 'Failed to fetch transactions' })
  }
}

// -----------------------------
// Admin: Fetch withdrawal requests
// GET /api/admin/withdrawals
// -----------------------------
export const listWithdrawals = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1
    const limit = parseInt(req.query.limit) || 20
    const skip = (page - 1) * limit
    const filter = {}
    if (req.query.status) filter.status = req.query.status

    const items = await WithdrawalRequest.find(filter).skip(skip).limit(limit).sort({ createdAt: -1 }).populate('user', 'name email role')
    const total = await WithdrawalRequest.countDocuments(filter)
    res.json({ success: true, pagination: { page, totalPages: Math.ceil(total / limit), total }, items })
  } catch (err) {
    console.error('admin.listWithdrawals error', err)
    res.status(500).json({ error: 'Failed to fetch withdrawals' })
  }
}

// -----------------------------
// Admin: Process withdrawal (approve/reject/paid)
// POST /api/admin/withdrawals/:id/process
// body: { action: 'approve'|'reject'|'paid', note }
// -----------------------------
export const processWithdrawal = async (req, res) => {
  try {
    const { action, note } = req.body
    const id = req.params.id
    const w = await WithdrawalRequest.findById(id).populate('user')
    if (!w) return res.status(404).json({ error: 'Withdrawal not found' })

    if (action === 'approve') {
      // mark approved (payment will be done outside or by another integration)
      w.status = 'approved'
      w.processedBy = req.user._id
      w.processedAt = new Date()
      w.note = note || w.note
      await w.save()

      // optionally notify vendor
      await sendNotification({ userId: w.user._id, title: 'Withdrawal approved', message: `Your withdrawal of ₦${w.amount} was approved.`, type: 'wallet', app: req.app })
      return res.json({ success: true, withdrawal: w })
    }

    if (action === 'reject') {
      // reject and refund to wallet
      w.status = 'rejected'
      w.processedBy = req.user._id
      w.processedAt = new Date()
      w.note = note || w.note
      await w.save()

      // refund amount to user's wallet
      await adjustUserWallet(w.user._id, w.amount, 'credit', { reason: 'withdrawal_rejected', withdrawalId: w._id })
      await Transaction.create({ user: w.user._id, amount: w.amount, type: 'credit', status: 'success', meta: { reason: 'withdrawal_rejected', withdrawalId: w._id } })

      await sendNotification({ userId: w.user._id, title: 'Withdrawal rejected', message: `Your withdrawal of ₦${w.amount} was rejected and refunded to your wallet.`, type: 'wallet', app: req.app })
      return res.json({ success: true, withdrawal: w })
    }

    if (action === 'paid') {
      w.status = 'paid'
      w.processedBy = req.user._id
      w.processedAt = new Date()
      w.note = note || w.note
      await w.save()

      await sendNotification({ userId: w.user._id, title: 'Withdrawal paid', message: `Your withdrawal of ₦${w.amount} was paid out.`, type: 'wallet', app: req.app })
      return res.json({ success: true, withdrawal: w })
    }

    res.status(400).json({ error: 'Invalid action' })
  } catch (err) {
    console.error('admin.processWithdrawal error', err)
    res.status(500).json({ error: 'Failed to process withdrawal' })
  }
}

// -----------------------------
// Admin: Create withdrawal request (admin side) - optional
// POST /api/admin/withdrawals/create
// -----------------------------
export const createWithdrawal = async (req, res) => {
  try {
    const { userId, amount, method, meta } = req.body
    if (!userId || !amount) return res.status(400).json({ error: 'userId & amount required' })

    const w = await WithdrawalRequest.create({ user: userId, amount: Number(amount), method: method || 'bank', meta: meta || {}, status: 'pending' })
    res.json({ success: true, withdrawal: w })
  } catch (err) {
    console.error('admin.createWithdrawal error', err)
    res.status(500).json({ error: 'Failed to create withdrawal' })
  }
}
// -----------------------------
// Admin: Fetch all orders with vendor & consumer details
// GET /api/admin/orders
// -----------------------------
export const listOrders = async (req, res) => {
  try {
    console.log("📦 [ADMIN] Fetching all orders...");
    const orders = await Order.find()
      .populate('vendorId', 'storeName businessAddress phone')
      .populate('consumerId', 'name email phone')
      .sort({ createdAt: -1 })
      .lean();

    res.json({ success: true, orders });
  } catch (err) {
    console.error('🔥 admin.listOrders error:', err.message);
    res.status(500).json({ error: 'Failed to fetch admin orders', details: err.message });
  }
};
