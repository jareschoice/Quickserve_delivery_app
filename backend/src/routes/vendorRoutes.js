import { Router } from 'express'
import { authRequired } from '../middleware/auth.js'
import { upload } from '../utils/upload.js'
import { createProduct, listProducts, packOrder, getWallet, requestWithdraw, setNotificationPref } from '../controllers/vendorController.js'

const router = Router()

router.get('/me', authRequired('vendor'), (req, res) => {
  res.json({
    vendor: req.user.vendor || {},
    user: { id: req.user._id, fullName: req.user.fullName }
  })
})

// Products
router.post('/products', authRequired('vendor'), upload.single('image'), createProduct)
router.get('/products', authRequired('vendor'), listProducts)

// Orders
router.post('/orders/:id/pack', authRequired('vendor'), packOrder)

// Wallet
router.get('/wallet', authRequired('vendor'), getWallet)
router.post('/wallet/withdraw', authRequired('vendor'), requestWithdraw)

// Settings
router.post('/settings/notifications', authRequired('vendor'), setNotificationPref)

export default router