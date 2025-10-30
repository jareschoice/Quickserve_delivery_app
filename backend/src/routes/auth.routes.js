import express from "express";
import jwt from "jsonwebtoken";
import User from "../models/User.js";

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
  req.body.role = 'customer';
  return router.handle({ ...req, url: '/register', method: 'POST' }, res);
});

router.post("/register/vendor", async (req, res) => {
  req.body.role = 'vendor';
  return router.handle({ ...req, url: '/register', method: 'POST' }, res);
});

router.post("/register/rider", async (req, res) => {
  req.body.role = 'rider';
  return router.handle({ ...req, url: '/register', method: 'POST' }, res);
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ error: "Invalid credentials" });
    const ok = await user.comparePassword(password);
    if (!ok) return res.status(400).json({ error: "Invalid credentials" });
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || "7d" });
    res.json({ user: { id: user._id, name: user.name, email: user.email, role: user.role }, token });
  } catch (e) {
    res.status(500).json({ error: e.message });
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
