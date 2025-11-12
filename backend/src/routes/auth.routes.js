import express from "express";
import jwt from "jsonwebtoken";
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import User from "../models/User.js";
import sendEmail from "../utils/email.js";

const router = express.Router();

router.post("/register", async (req, res) => {
  try {
    console.log('📥 Registration request:', req.body);
    const { name, email, password, phone, seatNumber, role } = req.body;
    
    if (!name || !email || !password) {
      console.log('❌ Missing fields:', { name: !!name, email: !!email, password: !!password });
      return res.status(400).json({ error: "Missing required fields", message: "Name, email, and password are required" });
    }
    
    const exists = await User.findOne({ email });
    if (exists) {
      console.log('❌ Email already in use:', email);
      return res.status(400).json({ error: "Email already in use", message: "This email is already registered" });
    }
    
    // Create user with additional fields
    const userData = { 
      name, 
      email, 
      password, 
      role: role || "customer",
      profile: {}
    };
    
    // Add optional fields to profile if provided
    if (phone) userData.profile.phone = phone;
    if (seatNumber) userData.profile.seatNumber = seatNumber;
    
    const user = await User.create(userData);

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
      console.error('💥 Error sending verification email:', err.message);
      // We don't block registration if email fails
    }

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    console.log('✅ User registered:', user.email, '| Role:', user.role);
    res.json({ 
      ok: true, 
      message: "Account created successfully! Please check your email to verify your account.",
      user: { id: user._id, name: user.name, email: user.email, role: user.role }, 
      token 
    });
  } catch (e) {
    console.error('💥 Registration error:', e.message);
    res.status(500).json({ error: "Registration failed", message: e.message });
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

// Forgot Password - Send reset token to email
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const user = await User.findOne({ email }).select('+password');
    
    if (!user) {
      // Don't reveal if user exists or not for security
      return res.json({ message: 'If that email exists, a reset link has been sent' });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
    
    user.resetPasswordToken = resetTokenHash;
    user.resetPasswordExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
    await user.save({ validateBeforeSave: false });

    // Send reset email
    try {
      // For development, use the frontend's actual URL (adjust port to match Live Server)
      const frontendURL = process.env.FRONTEND_URL || 'http://127.0.0.1:5500/event-frontend';
      const resetURL = `${frontendURL}/reset-password.html?token=${resetToken}`;
      const message = `Hi ${user.name},\n\nYou requested a password reset. Click the link below to reset your password:\n\n${resetURL}\n\nThis link will expire in 10 minutes.\n\nIf you did not request this, please ignore this email.`;

      await sendEmail({
        email: user.email,
        subject: 'QuickServe - Password Reset Request',
        message,
      });

      console.log(`✅ Password reset email sent to ${user.email}`);
      console.log(`📧 Reset URL: ${resetURL}`);
    } catch (err) {
      console.error('💥 Error sending reset email:', err);
      user.resetPasswordToken = undefined;
      user.resetPasswordExpires = undefined;
      await user.save({ validateBeforeSave: false });
      return res.status(500).json({ error: 'Error sending email. Please try again.' });
    }

    res.json({ message: 'If that email exists, a reset link has been sent' });
  } catch (error) {
    console.error('💥 Forgot password error:', error);
    res.status(500).json({ error: 'Server error. Please try again.' });
  }
});

// Reset Password - Update password with token
router.post('/reset-password/:token', async (req, res) => {
  try {
    const { password } = req.body;
    
    if (!password || password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Hash the token from URL to compare with database
    const resetTokenHash = crypto.createHash('sha256').update(req.params.token).digest('hex');
    
    const user = await User.findOne({
      resetPasswordToken: resetTokenHash,
      resetPasswordExpires: { $gt: Date.now() }
    }).select('+password');

    if (!user) {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }

    // Update password
    user.password = password;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    console.log(`✅ Password reset successful for ${user.email}`);
    
    res.json({ message: 'Password reset successful! You can now sign in with your new password.' });
  } catch (error) {
    console.error('💥 Reset password error:', error);
    res.status(500).json({ error: 'Server error. Please try again.' });
  }
});

export default router;
