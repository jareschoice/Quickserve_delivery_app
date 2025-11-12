// ===============================
// FILE: backend/src/routes/payment.routes.js (V2 API)
// ===============================
import express from 'express'
import { 
  initPayment, 
  verifyPayment, 
  handlePaystackWebhook,
  initOrderPayment,
  initMultiVendorPayment,  // 🆕 Multi-vendor payment
  verifyOrderRedirect
} from '../controllers/paymentController.js'
import { authRequired } from '../middleware/auth.js'

const router = express.Router()

// ✅ Initialize wallet funding payment (consumer, vendor, or rider)
router.post('/init', authRequired('consumer', 'vendor', 'rider'), initPayment)

// ✅ Initialize order payment (PAYMENT-FIRST FLOW)
// If EVENT_GUEST_CHECKOUT is not explicitly "false", allow guests (default true for events)
const allowGuest = process.env.EVENT_GUEST_CHECKOUT !== 'false'
const maybeAuthCustomer = allowGuest ? (req, res, next) => next() : authRequired('customer')
router.post('/init-order-payment', maybeAuthCustomer, initOrderPayment)

// ✅ Initialize multi-vendor order payment (NEW)
router.post('/init-multi-vendor-payment', maybeAuthCustomer, initMultiVendorPayment)

// ✅ Manually verify payment if needed
router.get('/verify', verifyPayment)

// ✅ Webhook for Paystack auto-verification (handles both wallet + orders)
router.post('/webhook', express.json({ type: '*/*' }), handlePaystackWebhook)

// ✅ Redirect verify endpoint for order payments (no public webhook needed)
router.get('/verify-order', verifyOrderRedirect)

// ✅ Demo pay page and confirm (enabled only when EVENT_DEMO_MODE=true)
const demoOn = process.env.EVENT_DEMO_MODE === 'true'
router.get('/demo-pay/:reference', (req, res) => {
  if (!demoOn) return res.status(403).send('Demo mode disabled')
  const { reference } = req.params
  res.type('html').send(`<!DOCTYPE html>
  <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <title>QuickServe Demo Payment</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">
  </head><body class="p-4">
    <div class="container" style="max-width:520px">
      <h3 class="mb-3">Demo Payment</h3>
      <p class="text-muted">Use any test card number (not charged). Reference: <code>${reference}</code></p>
      <form id="demoForm" class="card p-3 shadow-sm">
        <div class="mb-3">
          <label class="form-label">Card Number</label>
          <input class="form-control" placeholder="4242 4242 4242 4242" required />
        </div>
        <div class="row">
          <div class="col">
            <label class="form-label">Expiry</label>
            <input class="form-control" placeholder="12/30" required />
          </div>
          <div class="col">
            <label class="form-label">CVV</label>
            <input class="form-control" placeholder="123" required />
          </div>
        </div>
        <button class="btn btn-success mt-3" type="submit">Pay (Demo)</button>
      </form>
      <div id="msg" class="mt-3"></div>
    </div>
    <script>
      const form = document.getElementById('demoForm');
      const btn = form.querySelector('button[type="submit"]');
      const reference = '${reference}';
      console.log('Demo payment page loaded. Reference:', reference);
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        console.log('Form submitted, processing payment...');
        btn.disabled = true;
        btn.textContent = 'Processing...';
        try {
          const url = 'http://localhost:5555/api/payments/demo/confirm?reference=' + reference;
          console.log('Fetching:', url);
          const res = await fetch(url, { 
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
          });
          console.log('Response status:', res.status);
          const data = await res.json();
          console.log('Response data:', data);
          if (res.ok) {
            document.getElementById('msg').innerHTML = '<div class="alert alert-success">✅ Payment confirmed! Redirecting...</div>';
            if (data.redirectUrl) { 
              console.log('Redirecting to:', data.redirectUrl);
              setTimeout(() => window.location.href = data.redirectUrl, 1000);
            }
          } else {
            document.getElementById('msg').innerHTML = '<div class="alert alert-danger">❌ '+(data.error||'Failed')+'</div>';
            btn.disabled = false;
            btn.textContent = 'Pay (Demo)';
          }
        } catch (err) {
          console.error('Payment error:', err);
          document.getElementById('msg').innerHTML = '<div class="alert alert-danger">❌ Network error: '+err.message+'</div>';
          btn.disabled = false;
          btn.textContent = 'Pay (Demo)';
        }
      });
    </script>
  </body></html>`)
})

router.post('/demo/confirm', async (req, res) => {
  if (!demoOn) return res.status(403).json({ error: 'Demo mode disabled' })
  const { reference } = req.query
  if (!reference) return res.status(400).json({ error: 'reference required' })
  try {
    // Minimal inline logic to mirror webhook order creation
    const PendingOrder = (await import('../models/PendingOrder.js')).default
    const Order = (await import('../models/Order.js')).default
    const Transaction = (await import('../models/Transaction.js')).default
    const { sendNotification } = await import('../utils/notify.js')
    const pending = await PendingOrder.findOne({ paymentReference: reference, paymentStatus: 'pending' })
    if (!pending) return res.status(404).json({ error: 'Pending order not found' })

    const order = await Order.create({
      consumerId: pending.consumerId,
      vendorId: pending.vendorId,
      items: pending.items,
      subtotal: pending.subtotal,
      deliveryFee: pending.deliveryFee,
      platformFee: pending.platformFee,
      total: pending.total,
      deliveryAddress: pending.deliveryAddress,
      notes: pending.notes,
      packagingChoice: pending.packagingChoice,
      packagingNotes: pending.packagingNotes,
      distanceKm: pending.distanceKm,
      status: 'placed',
      payment: { reference, paid: true, channel: 'demo', verifiedAt: new Date() }
    })
    pending.paymentStatus = 'paid'
    await pending.save()
    await Transaction.create({ user: pending.consumerId, amount: pending.total, type: 'debit', status: 'success', meta: { reason: 'order_payment', reference, orderId: order._id.toString(), via: 'demo' } })
    try {
      const io = globalThis.io || req?.app?.get?.('io');
      io?.to(String(order.vendorId)).emit('order:new', { id: order._id });
      io?.to(String(order.consumerId)).emit('order:update', { id: order._id, status: order.status });
      io?.to('role:admin').emit('order:new', { id: order._id });
    } catch {}
    try { await sendNotification({ userId: order.vendorId, title: 'New order 🧾', message: 'A new order has been placed.', type: 'order', meta: { orderId: order._id } }); } catch {}
    try { await sendNotification({ userId: order.consumerId, title: 'Order placed 🧾', message: 'Your order has been placed.', type: 'order', meta: { orderId: order._id } }); } catch {}
  // Build a safe redirect URL using utility
  const { default: buildOrderRedirect } = await import('../utils/redirect.js')
  const frontendBase = req.headers.referer || process.env.FRONTEND_URL || `${req.protocol}://${req.get('host')}`
  const redirectUrl = buildOrderRedirect({ metadataRedirect: undefined, referer: frontendBase, frontendUrl: process.env.FRONTEND_URL, backendHost: `${req.protocol}://${req.get('host')}`, orderId: order._id })
  res.json({ success: true, orderId: order._id, redirectUrl })
  } catch (e) {
    res.status(500).json({ error: e.message })
  }
})

export default router

