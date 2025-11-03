// ===============================
// FILE: backend/src/routes/payment.routes.js (V2 API)
// ===============================
import express from 'express'
import { 
  initPayment, 
  verifyPayment, 
  handlePaystackWebhook,
  initOrderPayment 
} from '../controllers/paymentController.js'
import { authRequired } from '../middleware/auth.js'

const router = express.Router()

// ✅ Initialize wallet funding payment (consumer, vendor, or rider)
router.post('/init', authRequired('consumer', 'vendor', 'rider'), initPayment)

// ✅ Initialize order payment (PAYMENT-FIRST FLOW) - Customer only
router.post('/init-order-payment', authRequired('customer'), initOrderPayment)

// ✅ Manually verify payment if needed
router.get('/verify', verifyPayment)

// ✅ Webhook for Paystack auto-verification (handles both wallet + orders)
router.post('/webhook', express.json({ type: '*/*' }), handlePaystackWebhook)

export default router

