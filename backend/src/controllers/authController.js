import crypto from 'crypto'
import User from '../models/User.js'
import { signJWT } from '../utils/jwt.js'
import { sendEmail } from '../utils/emailClient.js' // you already have this
                                                       // (we’ll reuse it)

const minutesFromNow = (m) => new Date(Date.now() + m * 60 * 1000)

// Generate 6-digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString()

const buildVerifyLink = (token) => {
  const base = process.env.APP_BASE_URL || 'http://localhost:5000'
  // You can later point this to a pretty frontend route
  return `${base}/auth/verify?token=${encodeURIComponent(token)}`
}

const sendVerificationEmail = async (user) => {
  const url = buildVerifyLink(user.verifyToken)
  
  // 🚀 DEVELOPMENT: Log verification link to console
  console.log(`\n🔗 VERIFICATION LINK for ${user.email}:`);
  console.log(`${url}\n`);
  
  const html = `
  <div style="font-family:Arial;max-width:560px;margin:auto">
    <h2>Verify your QuickServe account</h2>
    <p>Hi ${user.name},</p>
    <p>Thanks for signing up as <b>${user.role}</b>. Please verify your email to activate your account.</p>
    <p><a href="${url}" 
          style="background:#16a34a;color:#fff;padding:12px 18px;border-radius:6px;text-decoration:none;">
      Verify My Email
    </a></p>
    <p>If the button doesn't work, copy this link:</p>
    <p>${url}</p>
    <hr/>
    <small>QuickServe • getquickserves.com</small>
  </div>`
  await sendEmail({
    to: user.email,
    subject: 'Verify your QuickServe account',
    html
  })
}

const sendOTPEmail = async (user) => {
  // 🚀 DEVELOPMENT: Log OTP to console
  console.log(`\n🔢 OTP for ${user.email}: ${user.otp}\n`);
  
  const html = `
  <div style="font-family:Arial;max-width:560px;margin:auto">
    <h2>Your QuickServe Verification Code</h2>
    <p>Hi ${user.name},</p>
    <p>Your verification code is:</p>
    <div style="background:#f8f9fa;padding:20px;border-radius:8px;text-align:center;margin:20px 0;">
      <h1 style="font-size:36px;color:#16a34a;margin:0;letter-spacing:5px;">${user.otp}</h1>
    </div>
    <p>This code will expire in 10 minutes.</p>
    <p>If you didn't request this code, please ignore this email.</p>
    <hr/>
    <small>QuickServe • getquickserves.com</small>
  </div>`
  await sendEmail({
    to: user.email,
    subject: 'Your QuickServe verification code',
    html
  })
}

// ---------- REGISTERERS ----------
const baseRegister = async (req, res, role) => {
  try {
    const { name, email, password, profile, useOTP = false } = req.body
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Missing fields' })
    }

    const exists = await User.findOne({ email })
    if (exists) return res.status(409).json({ error: 'Email already in use' })

    const verifyToken = crypto.randomBytes(32).toString('hex')
    const otp = generateOTP()
    
    const user = await User.create({
      role, name, email, password,
      profile: profile || {},
      verifyToken,
      verifyTokenExpires: minutesFromNow(30),
      otp: useOTP ? otp : undefined,
      otpExpires: useOTP ? minutesFromNow(10) : undefined
    })

    let emailSent = true
    try {
      if (useOTP) {
        await sendOTPEmail(user)
      } else {
        await sendVerificationEmail(user)
      }
    } catch (err) {
      console.error('Failed to send verification email:', err)
      // don't fail registration if email cannot be sent; user can request resend
      emailSent = false
    }

    return res.status(201).json({ 
      message: useOTP ? 'Registered. Please enter the OTP sent to your email.' : 'Registered. Please verify email.',
      emailSent,
      useOTP 
    })
  } catch (e) {
    console.error(e)
    return res.status(500).json({ error: 'Failed to register' })
  }
}

export const registerCustomer = (req, res) => baseRegister(req, res, 'customer')
export const registerVendor   = (req, res) => baseRegister(req, res, 'vendor')
export const registerRider    = (req, res) => baseRegister(req, res, 'rider')

// ---------- VERIFY ----------
export const verifyEmail = async (req, res) => {
  try {
    const { token } = req.query
    if (!token) return res.status(400).json({ error: 'Missing token' })

    const user = await User.findOne({ verifyToken: token })
    if (!user) return res.status(400).json({ error: 'Invalid token' })
    if (user.isVerified) return res.json({ message: 'Already verified' })
    if (user.verifyTokenExpires && user.verifyTokenExpires < new Date()) {
      return res.status(400).json({ error: 'Token expired' })
    }

    user.isVerified = true
    user.verifyToken = undefined
    user.verifyTokenExpires = undefined
    await user.save()

    return res.json({ message: 'Email verified. You can now login.' })
  } catch (e) {
    console.error(e)
    return res.status(500).json({ error: 'Verification failed' })
  }
}

// ---------- RESEND ----------
export const resendVerification = async (req, res) => {
  try {
    const { email, useOTP = false } = req.body
    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ error: 'User not found' })
    if (user.isVerified) return res.json({ message: 'Already verified' })

    if (useOTP) {
      user.otp = generateOTP()
      user.otpExpires = minutesFromNow(10)
    } else {
      user.verifyToken = crypto.randomBytes(32).toString('hex')
      user.verifyTokenExpires = minutesFromNow(30)
    }
    await user.save()

    let emailSent = true
    try {
      if (useOTP) {
        await sendOTPEmail(user)
      } else {
        await sendVerificationEmail(user)
      }
    } catch (err) {
      console.error('Failed to send verification email (resend):', err)
      emailSent = false
    }
    return res.json({ 
      message: useOTP ? 'OTP sent to your email' : 'Verification email sent', 
      emailSent 
    })
  } catch (e) {
    console.error(e)
    return res.status(500).json({ error: 'Failed to resend' })
  }
}

// ---------- VERIFY OTP ----------
export const verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP required' })

    const user = await User.findOne({ email })
    if (!user) return res.status(404).json({ error: 'User not found' })
    if (user.isVerified) return res.json({ message: 'Already verified' })
    if (!user.otp || user.otp !== otp) return res.status(400).json({ error: 'Invalid OTP' })
    if (user.otpExpires && user.otpExpires < new Date()) {
      return res.status(400).json({ error: 'OTP expired' })
    }

    user.isVerified = true
    user.otp = undefined
    user.otpExpires = undefined
    user.verifyToken = undefined
    user.verifyTokenExpires = undefined
    await user.save()

    return res.json({ message: 'Email verified successfully. You can now login.' })
  } catch (e) {
    console.error(e)
    return res.status(500).json({ error: 'OTP verification failed' })
  }
}

// ---------- LOGIN ----------
export const login = async (req, res) => {
  try {
    const { email, password } = req.body
    const user = await User.findOne({ email }).select('+password')
    if (!user) return res.status(401).json({ error: 'Invalid credentials' })

    const ok = await user.comparePassword(password)
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' })
    if (!user.isVerified) return res.status(403).json({ error: 'Email not verified' })

    const token = signJWT({ id: user._id, role: user.role })
    return res.json({
      token,
      user: {
        id: user._id,
        role: user.role,
        name: user.name,
        email: user.email
      }
    })
  } catch (e) {
    console.error(e)
    return res.status(500).json({ error: 'Login failed' })
  }
}

// ---------- ME ----------
export const me = async (req, res) => {
  return res.json({
    id: req.user._id,
    role: req.user.role,
    name: req.user.name,
    email: req.user.email,
    isVerified: req.user.isVerified
  })
}
