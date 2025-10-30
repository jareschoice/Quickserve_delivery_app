import { Router } from 'express'
import { initPayment, verifyPayment } from '../controllers/paymentController.js'
import { authRequired } from '../middleware/auth.js'

const router = Router()
router.post('/init', authRequired('consumer','vendor'), initPayment)
router.get('/verify', verifyPayment)

export default router
