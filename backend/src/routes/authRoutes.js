import { Router } from 'express'
import User from '../models/User.js'
import {
  registerCustomer,
  registerVendor,
  registerRider,
  login,
  verifyEmail,
  verifyOTP,
  resendVerification,
  me
} from '../controllers/authController.js'
import { authRequired } from '../middleware/auth.js' // ✅ FIXED

const router = Router()

// Registration per role
router.post('/register/customer', registerCustomer)
router.post('/register/vendor', registerVendor)
router.post('/register/rider', registerRider)

// Email verify & resend
router.get('/verify', verifyEmail)
router.post('/verify-otp', verifyOTP)
// 🚀 DEVELOPMENT: Auto-verify by email (for testing)
router.post('/dev-verify', async (req, res) => {
  try {
    const { email } = req.body
    if (!email) return res.status(400).json({ error: 'Email required' })
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ error: 'User not found' })
    user.isVerified = true
    user.verifyToken = undefined
    user.verifyTokenExpires = undefined
    user.otp = undefined
    user.otpExpires = undefined
    await user.save()
    res.json({ message: `✅ ${email} verified for development!` })
  } catch (e) {
    res.status(500).json({ error: e.message })
  }
})
router.post('/resend-verification', resendVerification)

// Login / Me
router.post('/login', login)
router.get('/me', authRequired, me) // ✅ FIXED here too

export default router