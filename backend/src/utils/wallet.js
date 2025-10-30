import User from '../models/User.js'
import Vendor from '../models/Vendor.js'
import Transaction from '../models/Transaction.js'

// Adjust wallet for a user (consumer, rider, admin)
export const adjustUserWallet = async (userId, amount, type, meta={}) => {
  const user = await User.findById(userId)
  if (!user) throw new Error('User not found')
  user.wallet = (user.wallet || 0) + (type === 'credit' ? amount : -amount)
  if (user.wallet < 0) user.wallet = 0 // prevent negative; adjust as business rules
  await user.save()
  await Transaction.create({ user: user._id, amount, type, meta })
  return user.wallet
}

// Adjust wallet for vendor entity and log transaction to vendor's user
export const adjustVendorWallet = async (userId, amount, type, meta={}) => {
  const v = await Vendor.findOne({ user: userId })
  if (!v) throw new Error('Vendor profile not found')
  v.wallet = (v.wallet || 0) + (type === 'credit' ? amount : -amount)
  if (v.wallet < 0) v.wallet = 0
  await v.save()
  await Transaction.create({ user: userId, amount, type, meta })
  return v.wallet
}
