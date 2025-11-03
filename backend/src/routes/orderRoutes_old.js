import { Router } from 'express'
import { authRequired } from '../middleware/auth.js'
import { createOrder, setStatus, confirmDelivery, myOrders } from '../controllers/orderController.js'

const router = Router()

router.get('/mine', authRequired('consumer','vendor','rider','admin'), myOrders)
router.post('/', authRequired('consumer'), createOrder)
router.patch('/:id/status', authRequired('vendor','admin','rider'), setStatus)
router.post('/:id/confirm-delivery', authRequired('consumer'), confirmDelivery)

export default router
