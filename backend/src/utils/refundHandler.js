// ===============================
// FILE: backend/src/utils/refundHandler.js
// ===============================
import { adjustUserWallet } from './wallet.js'
import Transaction from '../models/Transaction.js'
import User from '../models/User.js'
import { sendEmail } from './emailClient.js'
import { generatePaymentReceiptHTML } from './paymentReceipt.js'

/**
 * Handles wallet refund logic
 * @param {Object} params
 * @param {String} params.consumerId - ID of the user receiving refund
 * @param {Number} params.amount - Refund amount
 * @param {String} params.reason - Reason for refund
 * @param {String} params.orderId - Related order
 * @param {Boolean} [params.sendEmail=true] - Send email receipt or not
 */
export const processRefund = async ({ consumerId, amount, reason, orderId, sendEmail = true }) => {
  try {
    if (!consumerId || !amount) throw new Error('Invalid refund parameters')

    // ✅ Step 1: Credit user's wallet
    const updatedUser = await adjustUserWallet(consumerId, amount, 'credit', {
      reason: 'refund',
      orderId,
      metaReason: reason,
    })

    // ✅ Step 2: Create refund transaction
    await Transaction.create({
      user: consumerId,
      amount,
      type: 'credit',
      status: 'success',
      meta: {
        reason: 'refund',
        order: orderId,
        via: 'system_auto',
      },
    })

    // ✅ Step 3: Send email receipt (optional)
    if (sendEmail) {
      const user = await User.findById(consumerId)
      if (user) {
        const html = generatePaymentReceiptHTML({
          name: user.name,
          amount,
          reference: `REF-${orderId?.slice(-6).toUpperCase()}`,
          balance: updatedUser.wallet,
          date: new Date(),
        })
        await sendEmail({
          to: user.email,
          subject: `Refund Processed - ₦${amount.toLocaleString()}`,
          html,
        })
      }
    }

    console.log(`✅ Refund processed: ₦${amount} → User: ${consumerId}`)
    return true
  } catch (err) {
    console.error('processRefund error:', err.message)
    return false
  }
}
