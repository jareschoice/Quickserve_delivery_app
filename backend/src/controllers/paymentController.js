// ===============================
// FILE: backend/src/controllers/paymentController.js
// ===============================
import axios from 'axios'
import crypto from 'crypto'
import Transaction from '../models/Transaction.js'
import User from '../models/User.js'
import Order from '../models/Order.js'
import PendingOrder from '../models/PendingOrder.js'
import { adjustUserWallet } from '../utils/wallet.js'
import { sendEmail } from '../utils/emailClient.js'
import { generatePaymentReceiptHTML } from '../utils/paymentReceipt.js' // ✅ new utility

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY
const APP_BASE_URL = process.env.APP_BASE_URL || 'http://localhost:5000'

// =====================================
// ✳️ INITIATE WALLET FUNDING
// =====================================
export const initPayment = async (req, res) => {
  try {
    const { amount } = req.body
    const user = req.user

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Valid amount required' })
    }

    const kobo = Math.max(100, Math.round(Number(amount) * 100)) // NGN to kobo

    // ✅ Initialize Paystack transaction
    const resp = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        email: user.email,
        amount: kobo,
        currency: process.env.PAYSTACK_CURRENCY || 'NGN',
        callback_url: `${APP_BASE_URL}/api/payment/verify`,
        metadata: {
          userId: user._id.toString(),
          reason: 'wallet_funding',
          role: user.role,
        },
      },
      {
        headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` },
      }
    )

    // ✅ Create a pending transaction log
    await Transaction.create({
      user: user._id,
      amount: Number(amount),
      type: 'credit',
      status: 'pending',
      meta: {
        reason: 'wallet_funding',
        via: 'paystack',
        reference: resp.data.data.reference,
      },
    })

    res.json({
      success: true,
      message: 'Payment session created successfully',
      authorization_url: resp.data.data.authorization_url,
      reference: resp.data.data.reference,
    })
  } catch (e) {
    console.error('initPayment error:', e.response?.data || e.message)
    res.status(500).json({
      error: 'Payment initiation failed',
      detail: e.response?.data || e.message,
    })
  }
}

// =====================================
// ✳️ INITIATE ORDER PAYMENT (PAYMENT-FIRST FLOW)
// =====================================
export const initOrderPayment = async (req, res) => {
  try {
    const {
      vendorId,
      items, // [{ productId, name, price, qty }]
      deliveryAddress,
      deliveryFee = 0,
      notes,
      packagingChoice,
      packagingNotes,
      distanceKm
    } = req.body

    const user = req.user

    // Validate required fields
    if (!vendorId || !items || items.length === 0 || !deliveryAddress) {
      return res.status(400).json({ 
        error: 'vendorId, items, and deliveryAddress are required' 
      })
    }

    // Calculate order totals
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.qty), 0)
    const platformFee = 50 // ₦50 platform fee per order
    const total = subtotal + Number(deliveryFee) + platformFee

    if (total <= 0) {
      return res.status(400).json({ error: 'Invalid order total' })
    }

    // Initialize Paystack payment
    const kobo = Math.round(total * 100) // Convert to kobo
    const resp = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        email: user.email,
        amount: kobo,
        currency: process.env.PAYSTACK_CURRENCY || 'NGN',
        callback_url: `${APP_BASE_URL}/api/payments/verify-order`,
        metadata: {
          userId: user._id.toString(),
          vendorId,
          reason: 'order_payment',
          role: user.role,
          orderTotal: total,
        },
      },
      {
        headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` },
      }
    )

    const paymentReference = resp.data.data.reference

    // Store pending order with payment reference
    const pendingOrder = await PendingOrder.create({
      consumerId: user._id,
      vendorId,
      items,
      subtotal,
      deliveryFee: Number(deliveryFee),
      platformFee,
      total,
      deliveryAddress,
      notes,
      packagingChoice,
      packagingNotes,
      distanceKm,
      paymentReference,
      paymentStatus: 'pending',
    })

    // Create pending transaction log
    await Transaction.create({
      user: user._id,
      amount: total,
      type: 'debit',
      status: 'pending',
      meta: {
        reason: 'order_payment',
        via: 'paystack',
        reference: paymentReference,
        orderId: pendingOrder._id.toString(),
      },
    })

    res.json({
      success: true,
      message: 'Order payment session created. Complete payment to place order.',
      authorization_url: resp.data.data.authorization_url,
      reference: paymentReference,
      pendingOrderId: pendingOrder._id,
      total,
    })
  } catch (e) {
    console.error('initOrderPayment error:', e.response?.data || e.message)
    console.error('Full error:', JSON.stringify(e.response?.data, null, 2))
    res.status(500).json({
      error: 'Order payment initiation failed',
      detail: e.response?.data?.message || e.message,
      paystackError: e.response?.data || null,
    })
  }
}

// =====================================
// ✳️ MANUAL PAYMENT VERIFICATION (optional)
// =====================================
export const verifyPayment = async (req, res) => {
  try {
    const { reference } = req.query
    if (!reference) return res.status(400).json({ error: 'reference required' })

    const resp = await axios.get(
      `https://api.paystack.co/transaction/verify/${reference}`,
      { headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` } }
    )

    const data = resp.data.data
    if (data.status !== 'success') {
      return res.status(400).json({ error: 'Payment not successful' })
    }

    const { userId } = data.metadata
    const amount = data.amount / 100

    // ✅ Credit user wallet
    const updatedUser = await adjustUserWallet(userId, amount, 'credit', {
      reason: 'wallet_funding',
      via: 'paystack_manual_verify',
      reference,
    })

    // ✅ Update transaction record
    await Transaction.findOneAndUpdate(
      { 'meta.reference': reference },
      { status: 'success' },
      { new: true }
    )

    // ✅ Send email receipt
    const user = await User.findById(userId)
    if (user) {
      const html = generatePaymentReceiptHTML({
        name: user.name,
        amount,
        reference,
        balance: updatedUser.wallet,
        date: new Date(),
      })
      await sendEmail({
        to: user.email,
        subject: `Payment Receipt - ₦${amount.toLocaleString()}`,
        html,
      })
    }

    res.json({
      success: true,
      message: 'Wallet credited successfully',
      amount,
      reference,
    })
  } catch (e) {
    console.error('verifyPayment error:', e.response?.data || e.message)
    res.status(500).json({
      error: 'Verification failed',
      detail: e.response?.data || e.message,
    })
  }
}

// =====================================
// ✳️ PAYSTACK WEBHOOK HANDLER (AUTO CREDIT + ORDER CREATION)
// =====================================
export const handlePaystackWebhook = async (req, res) => {
  try {
    const signature = req.headers['x-paystack-signature']
    const computedHash = crypto
      .createHmac('sha512', PAYSTACK_SECRET_KEY)
      .update(JSON.stringify(req.body))
      .digest('hex')

    if (signature !== computedHash) {
      console.warn('⚠️ Invalid Paystack webhook signature')
      return res.status(400).json({ error: 'Invalid signature' })
    }

    const { event, data } = req.body
    if (event !== 'charge.success') return res.sendStatus(200)

    const userId = data.metadata.userId
    const amount = data.amount / 100
    const reference = data.reference
    const reason = data.metadata.reason

    // Prevent duplicate processing
    const alreadyProcessed = await Transaction.findOne({
      'meta.reference': reference,
      status: 'success',
    })
    if (alreadyProcessed) {
      console.log(`⚠️ Duplicate webhook ignored: ${reference}`)
      return res.sendStatus(200)
    }

    // =====================================
    // HANDLE ORDER PAYMENT
    // =====================================
    if (reason === 'order_payment') {
      // Find pending order
      const pendingOrder = await PendingOrder.findOne({ 
        paymentReference: reference,
        paymentStatus: 'pending'
      })

      if (!pendingOrder) {
        console.error(`❌ Pending order not found for reference: ${reference}`)
        return res.status(404).json({ error: 'Pending order not found' })
      }

      // Verify payment amount matches order total
      if (Math.abs(amount - pendingOrder.total) > 0.01) {
        console.error(`❌ Payment amount mismatch. Expected: ${pendingOrder.total}, Got: ${amount}`)
        return res.status(400).json({ error: 'Payment amount mismatch' })
      }

      // Create actual order
      const order = await Order.create({
        consumerId: pendingOrder.consumerId,
        vendorId: pendingOrder.vendorId,
        items: pendingOrder.items,
        subtotal: pendingOrder.subtotal,
        deliveryFee: pendingOrder.deliveryFee,
        platformFee: pendingOrder.platformFee,
        total: pendingOrder.total,
        deliveryAddress: pendingOrder.deliveryAddress,
        notes: pendingOrder.notes,
        packagingChoice: pendingOrder.packagingChoice,
        packagingNotes: pendingOrder.packagingNotes,
        distanceKm: pendingOrder.distanceKm,
        status: 'placed',
        payment: {
          reference,
          paid: true,
          channel: data.channel,
          verifiedAt: new Date(),
        },
      })

      // Update pending order status
      pendingOrder.paymentStatus = 'paid'
      await pendingOrder.save()

      // Update transaction record
      await Transaction.findOneAndUpdate(
        { 'meta.reference': reference },
        { 
          status: 'success',
          'meta.orderId': order._id.toString()
        },
        { new: true }
      )

      // Deduct vendor commission (₦50 platform fee)
      await adjustUserWallet(pendingOrder.vendorId, -50, 'debit', {
        reason: 'platform_fee',
        via: 'order_commission',
        orderId: order._id.toString(),
      })

      // Send confirmation email to customer
      const user = await User.findById(userId)
      if (user) {
        await sendEmail({
          to: user.email,
          subject: `Order Confirmed - #${order._id.toString().slice(-8).toUpperCase()}`,
          html: `
            <h2>Order Placed Successfully! 🎉</h2>
            <p>Hi ${user.name},</p>
            <p>Your order has been confirmed and payment received.</p>
            <p><strong>Order ID:</strong> #${order._id.toString().slice(-8).toUpperCase()}</p>
            <p><strong>Total Paid:</strong> ₦${amount.toLocaleString()}</p>
            <p><strong>Payment Reference:</strong> ${reference}</p>
            <p><strong>Status:</strong> Order Placed</p>
            <p>The vendor will start preparing your order shortly.</p>
          `,
        })
      }

      console.log(`✅ Order created successfully: ${order._id} → Payment: ₦${amount}`)
      return res.sendStatus(200)
    }

    // =====================================
    // HANDLE WALLET FUNDING (EXISTING)
    // =====================================
    if (reason === 'wallet_funding') {
      // Credit wallet automatically
      const updatedUser = await adjustUserWallet(userId, amount, 'credit', {
        reason: 'wallet_funding',
        via: 'paystack_webhook',
        reference,
      })

      // Update transaction record
      await Transaction.findOneAndUpdate(
        { 'meta.reference': reference },
        { status: 'success' },
        { new: true }
      )

      // Send email receipt automatically
      const user = await User.findById(userId)
      if (user) {
        const html = generatePaymentReceiptHTML({
          name: user.name,
          amount,
          reference,
          balance: updatedUser.wallet,
          date: new Date(),
        })
        await sendEmail({
          to: user.email,
          subject: `Payment Receipt - ₦${amount.toLocaleString()}`,
          html,
        })
      }

      console.log(`✅ Wallet funded successfully: ₦${amount} → User: ${userId}`)
      return res.sendStatus(200)
    }

    // Unknown reason
    console.warn(`⚠️ Unknown payment reason: ${reason}`)
    res.sendStatus(200)

  } catch (e) {
    console.error('handlePaystackWebhook error:', e.message)
    res.status(500).json({ error: 'Webhook processing failed' })
  }
}

