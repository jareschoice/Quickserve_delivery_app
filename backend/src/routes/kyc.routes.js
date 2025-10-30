import express from 'express'
import { authRequired } from '../middleware/auth.js'
import User from '../models/User.js'

const router = express.Router()

// Submit KYC (vendor or rider)
router.post('/submit', authRequired(), async (req, res) => {
  const { idUrl, licenseUrl, govIdNumber, extra } = req.body
  const u = await User.findById(req.user.id)
  if (!u) return res.status(404).json({ error: 'User not found' })
  u.kycStatus = 'pending'
  u.kycMeta = { ...(u.kycMeta||{}), idUrl, licenseUrl, govIdNumber, extra }
  await u.save()
  res.json({ user: u })
})

// Get my KYC state
router.get('/me', authRequired(), async (req, res) => {
  const u = await User.findById(req.user.id)
  if (!u) return res.status(404).json({ error: 'User not found' })
  res.json({ kycStatus: u.kycStatus, kycMeta: u.kycMeta, kycReviewedAt: u.kycReviewedAt })
})

export default router
