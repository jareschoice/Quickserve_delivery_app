// ===============================
// FILE: src/routes/vendorRoutes.js
// ===============================

import express from 'express'
import multer from 'multer'
import path from 'path'
import {
  registerBusiness,
  getBusiness,
  createProduct,
  listProducts,
  packOrder,
  getWallet,
  requestWithdraw,
  setNotificationPref,
  setStoreStatus,
  getVendorAnalytics,
  createVendor
} from '../controllers/vendorController.js'
import { authRequired } from '../middleware/auth.js' // ✅ FIXED import

// ✅ Initialize router BEFORE using it
const router = express.Router()

// ✅ Confirm router loaded
console.log('✅ vendorRoutes.js has been loaded into Express')

// =====================================
// ✅ Test route to verify connection
// =====================================
router.get('/test', (req, res) => {
  console.log('✅ /api/vendors/test hit successfully')
  res.json({ ok: true, message: 'Vendor routes are active' })
})

// =====================================
// 🧾 FILE UPLOAD SETUP (Product images)
// =====================================
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, `${Date.now()}-${file.originalname}`)
})
const upload = multer({ storage })

// =====================================
// ✳️ VENDOR BUSINESS MANAGEMENT
// =====================================
router.post('/register-business', authRequired('vendor'), registerBusiness)
router.get('/get-business', authRequired('vendor'), getBusiness)
router.post('/create-vendor', authRequired('admin'), createVendor)

// =====================================
// ✳️ PRODUCT MANAGEMENT
// =====================================
router.post('/create-product', authRequired('vendor'), upload.single('image'), createProduct)
router.get('/products', authRequired('vendor'), listProducts)

// =====================================
// ✳️ ORDER MANAGEMENT
// =====================================
router.put('/orders/:id/pack', authRequired('vendor'), packOrder)

// =====================================
// ✳️ WALLET & FINANCE
// =====================================
router.get('/wallet', authRequired('vendor'), getWallet)
router.post('/withdraw', authRequired('vendor'), requestWithdraw)

// =====================================
// ✳️ SETTINGS & NOTIFICATIONS
// =====================================
router.post('/notifications', authRequired('vendor'), setNotificationPref)
router.post('/store-status', authRequired('vendor'), setStoreStatus)
router.get('/analytics', authRequired('vendor'), getVendorAnalytics)

export default router
