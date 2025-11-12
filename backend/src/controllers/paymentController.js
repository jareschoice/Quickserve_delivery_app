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
import { adjustVendorWallet } from '../utils/wallet.js'
import Vendor from '../models/Vendor.js'
import { sendNotification } from '../utils/notify.js'
import { sendEmail } from '../utils/emailClient.js'
import { generatePaymentReceiptHTML } from '../utils/paymentReceipt.js' // ✅ new utility
import jwt from 'jsonwebtoken'

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY
const APP_BASE_URL = process.env.APP_BASE_URL || 'http://localhost:5555'
const CURRENCY = process.env.PAYSTACK_CURRENCY || 'NGN'

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
      distanceKm,
      seatNumber,
      guestEmail,
      guestPhone,
      redirectUrl
    } = req.body

    let user = req.user
    const allowGuest = process.env.EVENT_GUEST_CHECKOUT === 'true'

    // Validate required fields
    if (!vendorId || !items || items.length === 0 || !deliveryAddress) {
      return res.status(400).json({ 
        error: 'vendorId, items, and deliveryAddress are required' 
      })
    }

    // Calculate order totals
    const subtotal = items.reduce((sum, item) => sum + (item.price * item.qty), 0)
  const platformFee = Number(process.env.SERVICE_CHARGE_TOTAL || 100) // Service charge paid by consumer
    const total = subtotal + Number(deliveryFee) + platformFee

    if (total <= 0) {
      return res.status(400).json({ error: 'Invalid order total' })
    }

  // If guest allowed and no user, create/reuse a guest customer
    if (!user && allowGuest) {
      const base = (guestPhone || seatNumber || Date.now()).toString().replace(/\D/g,'')
      const email = (guestEmail && guestEmail.includes('@')) ? guestEmail : `guest+${base}@quickserve.local`
      let guest = await User.findOne({ email })
      if (!guest) {
        const randomPass = Math.random().toString(36).slice(2, 10) + '!A9'
        guest = await User.create({ role: 'customer', email, password: randomPass, name: seatNumber ? `Guest ${seatNumber}` : 'Guest', isVerified: false, profile: { phone: guestPhone || '' } })
      }
      user = guest
    }

    if (!user) {
      return res.status(401).json({ error: 'Authentication required' })
    }

    const demoMode = process.env.EVENT_DEMO_MODE === 'true'
    let paymentReference
    let authorization_url

    if (demoMode) {
      // Simulate a payment session and return demo pay page URL
      paymentReference = `demo_${Date.now()}_${Math.random().toString(36).slice(2,8)}`
      authorization_url = `${APP_BASE_URL}/api/payments/demo-pay/${paymentReference}`
    } else {
      // Initialize Paystack payment
      const kobo = Math.round(total * 100) // Convert to kobo
      const resp = await axios.post(
        'https://api.paystack.co/transaction/initialize',
        {
          email: user.email,
          amount: kobo,
          currency: CURRENCY,
          // Prefer backend redirect so we can finalize order without webhook
          callback_url: `${APP_BASE_URL}/api/payments/verify-order`,
          metadata: {
            userId: user._id.toString(),
            vendorId,
            reason: 'order_payment',
            redirectUrl: redirectUrl || undefined,
            role: user.role,
            orderTotal: total,
          },
        },
        {
          headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` },
        }
      )
      paymentReference = resp.data.data.reference
      authorization_url = resp.data.data.authorization_url
    }

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
      notes: notes || (guestPhone ? `Phone: ${guestPhone}` : undefined),
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
      message: demoMode ? 'Demo payment session created' : 'Order payment session created. Complete payment to place order.',
      authorization_url,
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
// ✳️ INITIALIZE MULTI-VENDOR ORDER PAYMENT (NEW)
// =====================================
export const initMultiVendorPayment = async (req, res) => {
  try {
    const {
      orders,           // Array of { vendorId, items }
      orderGroupId,     // Unique ID linking all orders
      isMultiVendor,    // Boolean flag
      deliveryAddress,
      deliveryFee = 0,
      notes,
      seatNumber,
      guestPhone,
      guestEmail,
      redirectUrl,
      packagingChoice,
      packagingNotes,
      distanceKm,
    } = req.body

    let user = req.user
    const allowGuest = process.env.EVENT_GUEST_CHECKOUT === 'true'

    // Validate required fields
    if (!orders || orders.length === 0 || !deliveryAddress) {
      return res.status(400).json({ 
        error: 'orders and deliveryAddress are required' 
      })
    }

    // Calculate total across all vendors
    let grandTotal = 0
    const pendingOrders = []

    for (const order of orders) {
      const { vendorId, items } = order
      if (!vendorId || !items || items.length === 0) {
        return res.status(400).json({ 
          error: 'Each order must have vendorId and items' 
        })
      }

      const subtotal = items.reduce((sum, item) => sum + (item.price * item.qty), 0)
      grandTotal += subtotal
    }

    // Add service charge (₦70 for single dispatcher delivery)
    const platformFee = Number(process.env.SERVICE_CHARGE_TOTAL || 70)
    const total = grandTotal + Number(deliveryFee) + platformFee

    if (total <= 0) {
      return res.status(400).json({ error: 'Invalid order total' })
    }

    // Handle guest checkout
    if (!user && allowGuest) {
      const base = (guestPhone || seatNumber || Date.now()).toString().replace(/\D/g,'')
      const email = (guestEmail && guestEmail.includes('@')) ? guestEmail : `guest+${base}@quickserve.local`
      let guest = await User.findOne({ email })
      if (!guest) {
        const randomPass = Math.random().toString(36).slice(2, 10) + '!A9'
        guest = await User.create({ 
          role: 'customer', 
          email, 
          password: randomPass, 
          name: seatNumber ? `Guest ${seatNumber}` : 'Guest', 
          isVerified: false, 
          profile: { phone: guestPhone || '' } 
        })
      }
      user = guest
    }

    if (!user) {
      return res.status(401).json({ error: 'Authentication required' })
    }

    const demoMode = process.env.EVENT_DEMO_MODE === 'true'
    let paymentReference
    let authorization_url

    if (demoMode) {
      // Simulate a payment session
      paymentReference = `demo_mv_${Date.now()}_${Math.random().toString(36).slice(2,8)}`
      authorization_url = `${APP_BASE_URL}/api/payments/demo-pay/${paymentReference}`
    } else {
      // Initialize Paystack payment
      const kobo = Math.round(total * 100)
      const resp = await axios.post(
        'https://api.paystack.co/transaction/initialize',
        {
          email: user.email,
          amount: kobo,
          currency: CURRENCY,
          // Prefer backend redirect so we can finalize order without webhook
          callback_url: `${APP_BASE_URL}/api/payments/verify-order`,
          metadata: {
            userId: user._id.toString(),
            orderGroupId,
            isMultiVendor: true,
            vendorCount: orders.length,
            reason: 'multi_vendor_order_payment',
            redirectUrl: redirectUrl || undefined,
            role: user.role,
            orderTotal: total,
          },
        },
        {
          headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` },
        }
      )
      paymentReference = resp.data.data.reference
      authorization_url = resp.data.data.authorization_url
    }

    // Create pending orders for each vendor
    for (const order of orders) {
      const { vendorId, items } = order
      const subtotal = items.reduce((sum, item) => sum + (item.price * item.qty), 0)
      
      const pendingOrder = await PendingOrder.create({
        consumerId: user._id,
        vendorId,
        items,
        subtotal,
        deliveryFee: 0, // Split delivery fee or charge once
        platformFee: orders.length > 1 ? 0 : platformFee, // Only first order pays platform fee
        total: subtotal,
        deliveryAddress,
        notes: notes || (guestPhone ? `Phone: ${guestPhone}` : undefined),
        packagingChoice,
        packagingNotes,
        distanceKm,
        paymentReference,
        paymentStatus: 'pending',
        orderGroupId,     // 🆕 Link orders together
        isMultiVendor,    // 🆕 Flag for multi-vendor
      })

      pendingOrders.push(pendingOrder)
    }

    // Create pending transaction log
    await Transaction.create({
      user: user._id,
      amount: total,
      type: 'debit',
      status: 'pending',
      meta: {
        reason: 'multi_vendor_order_payment',
        via: 'paystack',
        reference: paymentReference,
        orderGroupId,
        pendingOrderIds: pendingOrders.map(o => o._id.toString()),
        vendorCount: orders.length,
      },
    })

    res.json({
      success: true,
      message: demoMode 
        ? `Demo multi-vendor payment session created (${orders.length} vendors)` 
        : `Multi-vendor payment session created. Complete payment to place orders from ${orders.length} vendors.`,
      authorization_url,
      reference: paymentReference,
      orderGroupId,
      pendingOrderIds: pendingOrders.map(o => o._id),
      vendorCount: orders.length,
      total,
    })
  } catch (e) {
    console.error('initMultiVendorPayment error:', e.response?.data || e.message)
    res.status(500).json({
      error: 'Multi-vendor payment initiation failed',
      detail: e.response?.data?.message || e.message,
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
    if (reason === 'order_payment' || reason === 'multi_vendor_order_payment') {
      // Find all pending orders with this reference
      const pendingOrders = await PendingOrder.find({ 
        paymentReference: reference,
        paymentStatus: 'pending'
      })

      if (pendingOrders.length === 0) {
        console.error(`❌ Pending order(s) not found for reference: ${reference}`)
        return res.status(404).json({ error: 'Pending order not found' })
      }

      // For multi-vendor, verify total across all orders
      const totalPending = pendingOrders.reduce((sum, po) => sum + po.total, 0)
      const platformFee = Number(process.env.SERVICE_CHARGE_TOTAL || 70)
      const expectedTotal = totalPending + platformFee
      
      if (Math.abs(amount - expectedTotal) > 0.01) {
        console.error(`❌ Payment amount mismatch. Expected: ${expectedTotal}, Got: ${amount}`)
        return res.status(400).json({ error: 'Payment amount mismatch' })
      }

      const createdOrders = []
      const orderGroupId = pendingOrders[0].orderGroupId
      const isMultiVendor = pendingOrders.length > 1

      // Create actual orders for each vendor
      for (const pendingOrder of pendingOrders) {
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
          orderGroupId,      // 🆕 Link orders together
          isMultiVendor,     // 🆕 Flag for multi-vendor
          payment: {
            reference,
            paid: true,
            channel: data.channel,
            verifiedAt: new Date(),
          },
        })

        createdOrders.push(order)

        // Update pending order status
        pendingOrder.paymentStatus = 'paid'
        await pendingOrder.save()

        // ✅ Credit the vendor for this order's subtotal (best-effort)
        try {
          const vendorDoc = await Vendor.findById(order.vendorId)
          if (vendorDoc && vendorDoc.user) {
            await adjustVendorWallet(
              vendorDoc.user,
              order.subtotal,
              'credit',
              {
                reason: 'order_payment',
                via: 'paystack_webhook',
                orderId: order._id.toString(),
                reference,
              },
              req?.app
            )
            // mark order as already paid to vendor to avoid duplicate credit on delivery
            order.isPaidToVendor = true
            await order.save()
          }
        } catch (e) {
          console.error('❌ Vendor credit failed for order', order._id, e.message)
        }

        // Emit socket event for each vendor
        try {
          const io = globalThis.io || req?.app?.get?.('io');
          io?.to(String(order.vendorId)).emit('order:new', { 
            id: order._id,
            isMultiVendor,
            orderGroupId,
            totalVendors: pendingOrders.length
          });
        } catch (err) {
          console.error('❌ Socket emit error:', err);
        }
      }

      // Update transaction record
      await Transaction.findOneAndUpdate(
        { 'meta.reference': reference },
        { 
          status: 'success',
          'meta.orderIds': createdOrders.map(o => o._id.toString()),
          'meta.orderGroupId': orderGroupId
        },
        { new: true }
      )

      // Send confirmation email to customer
      const user = await User.findById(userId)
      if (user) {
        const orderIdsList = createdOrders.map(o => 
          `#${o._id.toString().slice(-8).toUpperCase()}`
        ).join(', ')
        
        await sendEmail({
          to: user.email,
          subject: isMultiVendor 
            ? `Multi-Vendor Order Confirmed - ${createdOrders.length} vendors` 
            : `Order Confirmed - #${createdOrders[0]._id.toString().slice(-8).toUpperCase()}`,
          html: `
            <h2>Order${isMultiVendor ? 's' : ''} Placed Successfully! 🎉</h2>
            <p>Hi ${user.name},</p>
            <p>Your ${isMultiVendor ? 'multi-vendor ' : ''}order has been confirmed and payment received.</p>
            ${isMultiVendor ? `<p><strong>Order Group ID:</strong> ${orderGroupId}</p>` : ''}
            <p><strong>Order ID${isMultiVendor ? 's' : ''}:</strong> ${orderIdsList}</p>
            <p><strong>Total Paid:</strong> ₦${amount.toLocaleString()}</p>
            <p><strong>Payment Reference:</strong> ${reference}</p>
            ${isMultiVendor ? `
              <p><strong>Vendors:</strong> ${createdOrders.length}</p>
              <p>✅ All items will be delivered together by one dispatcher</p>
              <p>✅ You'll be notified as each vendor prepares your order</p>
            ` : ''}
            <p><strong>Status:</strong> Order${isMultiVendor ? 's' : ''} Placed</p>
            <p>The vendor${isMultiVendor ? 's' : ''} will start preparing your order shortly.</p>
          `,
        })
      }

      console.log(`✅ Order${isMultiVendor ? 's' : ''} created: ${createdOrders.map(o => o._id).join(', ')}`)
      return res.json({
        success: true,
        message: 'Payment verified and order created',
        orderIds: createdOrders.map(o => o._id),
        orderGroupId,
        isMultiVendor
      })
    }

    // =====================================
    // HANDLE WALLET FUNDING
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

// =====================================
// ✳️ REDIRECT HANDLER (ORDER VERIFY WITHOUT PUBLIC WEBHOOK)
// This endpoint is used as Paystack callback_url so that after payment
// we can verify the transaction and create the order(s) locally.
// It then redirects the browser to the tracking page.
// =====================================
export const verifyOrderRedirect = async (req, res) => {
  try {
    const { reference, trxref } = req.query
    const ref = reference || trxref
    if (!ref) return res.status(400).send('Missing reference')

    // Verify with Paystack
    const resp = await axios.get(
      `https://api.paystack.co/transaction/verify/${encodeURIComponent(ref)}`,
      { headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` } }
    )

    const data = resp.data?.data
    if (!data || data.status !== 'success') {
      return res.status(400).send('Payment not successful')
    }

    const reason = data.metadata?.reason
    const userId = data.metadata?.userId
    const channel = data.channel
    const amount = (data.amount || 0) / 100

    // Idempotency: if already processed, just redirect to track page using existing order
    const existingTxn = await Transaction.findOne({ 'meta.reference': ref, status: 'success' }).lean()
    if (existingTxn?.meta?.orderIds?.length) {
      const firstOrderId = existingTxn.meta.orderIds[0]
      // Best-effort token for tracking
      const token = jwt.sign({ id: userId, role: data.metadata?.role || 'customer' }, process.env.JWT_SECRET, { expiresIn: '7d' })

      // Prefer redirectUrl passed in metadata, then Referer header, then APP_BASE_URL
      let baseRedirect = data.metadata?.redirectUrl || req.headers.referer || `${req.protocol}://${req.get('host')}`
      baseRedirect = String(baseRedirect || '').replace(/\/$/, '')
      const hasFrontendPath = baseRedirect.includes('/event-frontend/') || baseRedirect.includes('track.html')
      let redirectTarget = hasFrontendPath ? baseRedirect : `${baseRedirect}/event-frontend/track.html`
      const sep = redirectTarget.includes('?') ? '&' : '?'
      redirectTarget = `${redirectTarget}${sep}orderId=${firstOrderId}&token=${encodeURIComponent(token)}`
      return res.redirect(redirectTarget)
    }

    // Handle order creation similar to webhook flow
    if (reason === 'order_payment' || reason === 'multi_vendor_order_payment') {
      const pendingOrders = await PendingOrder.find({ paymentReference: ref, paymentStatus: 'pending' })
      if (!pendingOrders.length) return res.status(404).send('Pending order not found')

      const totalPending = pendingOrders.reduce((sum, po) => sum + (po.total || 0), 0)
      const platformFee = Number(process.env.SERVICE_CHARGE_TOTAL || 70)
      const expectedTotal = totalPending + platformFee
      if (Math.abs(amount - expectedTotal) > 0.01) {
        return res.status(400).send('Payment amount mismatch')
      }

      const createdOrders = []
      const orderGroupId = pendingOrders[0].orderGroupId
      const isMultiVendor = pendingOrders.length > 1

      for (const pendingOrder of pendingOrders) {
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
          orderGroupId,
          isMultiVendor,
          payment: { reference: ref, paid: true, channel, verifiedAt: new Date() }
        })
        createdOrders.push(order)
        pendingOrder.paymentStatus = 'paid'
        await pendingOrder.save()

        try {
          const io = globalThis.io
          io?.to(String(order.vendorId)).emit('order:new', { id: order._id, isMultiVendor, orderGroupId, totalVendors: pendingOrders.length })
        } catch {}

        // ✅ Credit vendor wallet for this order (best-effort)
        try {
          const vendorDoc = await Vendor.findById(order.vendorId)
          if (vendorDoc && vendorDoc.user) {
            await adjustVendorWallet(
              vendorDoc.user,
              order.subtotal,
              'credit',
              {
                reason: 'order_payment',
                via: 'paystack_redirect_verify',
                orderId: order._id.toString(),
                reference: ref,
              },
              req?.app
            )
            // mark order as already paid to vendor to avoid duplicate credit on delivery
            order.isPaidToVendor = true
            await order.save()
          }
        } catch (e) {
          console.error('❌ Vendor credit failed (redirect verify) for order', order._id, e.message)
        }
      }

      await Transaction.findOneAndUpdate(
        { 'meta.reference': ref },
        { status: 'success', 'meta.orderIds': createdOrders.map(o => o._id.toString()), 'meta.orderGroupId': orderGroupId },
        { new: true }
      )

      // Notify customer via email (best effort)
      try {
        const user = await User.findById(userId)
        if (user) {
          const orderIdsList = createdOrders.map(o => `#${o._id.toString().slice(-8).toUpperCase()}`).join(', ')
          await sendEmail({
            to: user.email,
            subject: isMultiVendor ? `Multi-Vendor Order Confirmed - ${createdOrders.length} vendors` : `Order Confirmed - #${createdOrders[0]._id.toString().slice(-8).toUpperCase()}`,
            html: `<p>Payment confirmed.</p><p>Order ID(s): ${orderIdsList}</p><p>Total: ₦${amount.toLocaleString()}</p>`
          })
        }
      } catch {}

    // Redirect to tracking page for first order
    const firstOrderId = createdOrders[0]._id
    const token = jwt.sign({ id: userId, role: data.metadata?.role || 'customer' }, process.env.JWT_SECRET, { expiresIn: '7d' })

    // Use redirectUrl from Paystack metadata when available so the browser returns to the same origin/environment
    let baseRedirect = data.metadata?.redirectUrl || req.headers.referer || `${req.protocol}://${req.get('host')}`
    baseRedirect = String(baseRedirect || '').replace(/\/$/, '')
    const hasFrontendPath = baseRedirect.includes('/event-frontend/') || baseRedirect.includes('track.html')
    let redirectTarget = hasFrontendPath ? baseRedirect : `${baseRedirect}/event-frontend/track.html`
    const sep = redirectTarget.includes('?') ? '&' : '?'
    redirectTarget = `${redirectTarget}${sep}orderId=${firstOrderId}&token=${encodeURIComponent(token)}`
    return res.redirect(redirectTarget)
    }

    // Not an order payment: redirect to home
    return res.redirect(`${APP_BASE_URL.replace(/\/$/, '')}/event-frontend/home.html`)
  } catch (e) {
    console.error('verifyOrderRedirect error:', e.response?.data || e.message)
    return res.status(500).send('Verification failed')
  }
}

