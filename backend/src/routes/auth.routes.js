import express from "express";
import jwt from "jsonwebtoken";
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import User from "../models/User.js";
import sendEmail from "../utils/email.js";

const router = express.Router();

router.post("/register", async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    if (!name || !email || !password) return res.status(400).json({ error: "Missing fields" });
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ error: "Email already in use" });
    const user = await User.create({ name, email, password, role: role || "customer" });
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    res.json({ user: { id: user._id, name: user.name, email: user.email, role: user.role }, token });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Backward-compatible role-specific register endpoints
router.post("/register/customer", async (req, res) => {
  try {
    console.log('📥 Customer registration request:', req.body);
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      console.log('❌ Missing fields:', { name: !!name, email: !!email, password: !!password });
      return res.status(400).json({ error: "Missing fields" });
    }
    const exists = await User.findOne({ email });
    if (exists) {
      console.log('❌ Email already in use:', email);
      return res.status(400).json({ error: "Email already in use" });
    }
    const user = await User.create({ name, email, password, role: 'customer' });

    // Send verification email
    try {
      const verifyToken = user.createVerifyToken();
      await user.save({ validateBeforeSave: false });

      const verifyURL = `${req.protocol}://${req.get('host')}/api/auth/verify-email/${verifyToken}`;
      const message = `Hi ${user.name},\n\nPlease verify your email address by clicking the link below:\n${verifyURL}\n\nThis link will expire in 10 minutes.\n\nIf you did not create this account, please ignore this email.`;

      await sendEmail({
        email: user.email,
        subject: 'QuickServe - Verify Your Email',
        message,
      });
      console.log(`✅ Verification email sent to ${user.email}`);
    } catch (err) {
      console.error('💥 Error sending verification email. Full error:', err);
      // We don't block registration if email fails, but we should log it
    }

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    console.log('✅ User registered:', user.email);
    res.json({ ok: true, user: { id: user._id, name: user.name, email: user.email, role: user.role }, token });
  } catch (e) {
    console.error('💥 Registration error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

router.post("/register/vendor", async (req, res) => {
  try {
    console.log('📥 Vendor registration request:', req.body);
    const { name, email, password } = req.body;
    
    if (!name || !email || !password) {
      console.log('❌ Vendor registration: Missing fields');
      return res.status(400).json({ error: "Missing fields" });
    }
    
    const exists = await User.findOne({ email });
    if (exists) {
      console.log('❌ Vendor registration: Email already in use:', email);
      return res.status(400).json({ error: "Email already in use" });
    }
    
    const user = await User.create({ name, email, password, role: 'vendor' });

    // Send verification email
    try {
      const verifyToken = user.createVerifyToken();
      await user.save({ validateBeforeSave: false });

      const verifyURL = `${req.protocol}://${req.get('host')}/api/auth/verify-email/${verifyToken}`;
      const message = `Hi ${user.name},\n\nPlease verify your email address by clicking the link below:\n${verifyURL}\n\nThis link will expire in 10 minutes.\n\nIf you did not create this account, please ignore this email.`;

      await sendEmail({
        email: user.email,
        subject: 'QuickServe - Verify Your Email',
        message,
      });
      console.log(`✅ Verification email sent to ${user.email}`);
    } catch (err) {
      console.error('💥 Error sending verification email. Full error:', err);
    }

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    console.log('✅ Vendor registered:', user.email, '| Role:', user.role);
    res.json({ ok: true, user: { id: user._id, name: user.name, email: user.email, role: user.role }, token });
  } catch (e) {
    console.error('💥 Vendor registration error:', e.message);
    res.status(500).json({ error: e.message });
  }
});

router.post("/register/rider", async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) return res.status(400).json({ error: "Missing fields" });
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ error: "Email already in use" });
    const user = await User.create({ name, email, password, role: 'rider' });

    // Send verification email
    try {
      const verifyToken = user.createVerifyToken();
      await user.save({ validateBeforeSave: false });

      const verifyURL = `${req.protocol}://${req.get('host')}/api/auth/verify-email/${verifyToken}`;
      const message = `Hi ${user.name},\n\nPlease verify your email address by clicking the link below:\n${verifyURL}\n\nThis link will expire in 10 minutes.\n\nIf you did not create this account, please ignore this email.`;

      await sendEmail({
        email: user.email,
        subject: 'QuickServe - Verify Your Email',
        message,
      });
      console.log(`✅ Verification email sent to ${user.email}`);
    } catch (err) {
      console.error('💥 Error sending verification email. Full error:', err);
    }

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    console.log('✅ Rider registered:', user.email);
    res.json({ ok: true, user: { id: user._id, name: user.name, email: user.email, role: user.role }, token });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: "Missing email or password" });
    }

    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const ok = await user.comparePassword(password);
    if (!ok) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    console.log(`✅ Login successful: ${user.email}`);
    res.json({ ok: true, user: { id: user._id, name: user.name, email: user.email, role: user.role }, token });
  } catch (e) {
    console.error(`💥 Login error for ${req.body.email}:`, e.message);
    res.status(500).json({ error: e.message });
  }
});

router.get('/verify-email/:token', async (req, res) => {
  try {
    // 1) Get user based on the token
    const hashedToken = crypto
      .createHash('sha256')
      .update(req.params.token)
      .digest('hex');

    const user = await User.findOne({
      verifyToken: hashedToken,
      verifyTokenExpires: { $gt: Date.now() },
    });

    // 2) If token has not expired and there is a user, set the new password
    if (!user) {
      return res.status(400).send('<h1>Token is invalid or has expired</h1>');
    }

    user.isVerified = true;
    user.verifyToken = undefined;
    user.verifyTokenExpires = undefined;
    await user.save();

    // 3) Log the user in, send JWT
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    
    // Redirect to a success page in the frontend
    // For now, just send a success message
    res.status(200).send(`<h1>Email Verified Successfully!</h1><p>You can now close this window and log in to the app.</p>`);

  } catch (err) {
    console.error('💥 Email verification error:', err);
    res.status(500).send('<h1>Error verifying email</h1>');
  }
});

// Minimal verification endpoints for app flows
router.post('/dev-verify', async (req, res) => {
  const { email } = req.body || {}
  if (!email) return res.status(400).json({ error: 'Email required' })
  return res.json({ message: 'Verified (dev)' })
})

router.post('/resend-verification', async (req, res) => {
  const { email } = req.body || {}
  if (!email) return res.status(400).json({ error: 'Email required' })
  return res.json({ message: 'Verification sent' })
})

export default router;
