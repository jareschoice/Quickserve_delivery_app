import express from "express";
import { authRequired } from "../middleware/auth.js";
import Order from "../models/Order.js";
import Vendor from "../models/Vendor.js";
import User from "../models/User.js";
import Transaction from "../models/Transaction.js";
import Product from "../models/Product.js";
import multer from 'multer';
import path from 'path';
import fs from 'fs';

const router = express.Router();

// Get all users
router.get("/users", authRequired("admin"), async (req, res) => {
  try {
    const users = await User.find().select('-password').sort({ createdAt: -1 });
    res.json({ users });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all vendors with populated user data
router.get("/vendors", authRequired("admin"), async (req, res) => {
  try {
    const vendors = await Vendor.find().populate('user', '-password');
    res.json({ vendors });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update a vendor (admin only)
router.put('/vendors/:id', authRequired('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    const allowed = ['storeName','businessName','businessAddress','businessPhone','category','isActive','availabilityStatus','tags'];
    const v = await Vendor.findById(id);
    if (!v) return res.status(404).json({ error: 'Vendor not found' });
    for (const k of allowed) {
      if (req.body[k] !== undefined) {
        v[k] = req.body[k];
      }
    }
    await v.save();
    const populated = await Vendor.findById(id).populate('user','-password');
    res.json({ success: true, vendor: populated });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete a vendor (admin only) — hard delete (use with care)
router.delete('/vendors/:id', authRequired('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    const v = await Vendor.findById(id);
    if (!v) return res.status(404).json({ error: 'Vendor not found' });
    await v.deleteOne();
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all orders with populated data (stable + vendor fix)
router.get("/orders", authRequired("admin"), async (req, res) => {
  try {
    console.log("📦 [ADMIN] Fetching all orders...");
    
    // Fetch all orders and populate vendor & consumer details directly
    const orders = await Order.find()
      .populate({
        path: "vendorId",
        select: "storeName businessName businessAddress phone user",
        populate: { path: "user", select: "name email" },
      })
      .populate("consumerId", "name email phone")
      .sort({ createdAt: -1 })
      .lean();

    // Shape orders for frontend UI
    const shaped = orders.map(o => ({
      ...o,
      vendorName: o.vendorId?.businessName || o.vendorId?.storeName || "Unknown Vendor",
      vendorEmail: o.vendorId?.user?.email || null,
      consumerName: o.consumerId?.name || "Guest",
      consumerEmail: o.consumerId?.email || null,
    }));

    console.log(`✅ [ADMIN] Loaded ${shaped.length} orders.`);
    res.json({ success: true, orders: shaped });
  } catch (error) {
    console.error("🔥 [ADMIN] listOrders error:", error.message);
    res.status(500).json({ error: "Failed to fetch admin orders", details: error.message });
  }
});

// Get all products
router.get("/products", authRequired("admin"), async (req, res) => {
  try {
    const products = await Product.find().populate({
      path: 'vendorId',
      populate: { path: 'user', select: 'name email' }
    });
    res.json({ products });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get("/stats", authRequired("admin"), async (req, res) => {
  // Midnight boundary for "today"
  const now = new Date();
  const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const [ordersTotal, ordersToday, vendorsActive, riders, customers, adminFeesAgg] = await Promise.all([
    Order.countDocuments({}),
    Order.countDocuments({ createdAt: { $gte: todayStart } }),
    Vendor.countDocuments({ isActive: { $ne: false } }),
    User.countDocuments({ role: "rider" }),
    User.countDocuments({ role: "customer" }),
    Transaction.aggregate([
      { $match: { type: 'credit', 'meta.kind': 'admin_fee' } },
      { $group: { _id: null, total: { $sum: '$amount' } } },
    ])
  ]);
  res.json({ 
    orders: ordersToday,      // expose as "today" for the tile
    ordersTotal,              // provide total separately for secondary tiles
    vendors: vendorsActive,   // active vendors (isActive != false)
    riders,
    customers,
    adminFees: adminFeesAgg?.[0]?.total || 0 
  });
});

// KYC review endpoints
router.post('/kyc/:userId/approve', authRequired('admin'), async (req, res) => {
  const u = await User.findById(req.params.userId)
  if (!u) return res.status(404).json({ error: 'User not found' })
  u.kycStatus = 'approved'
  u.kycReviewedAt = new Date()
  await u.save()
  res.json({ user: u })
})

router.post('/kyc/:userId/reject', authRequired('admin'), async (req, res) => {
  const u = await User.findById(req.params.userId)
  if (!u) return res.status(404).json({ error: 'User not found' })
  u.kycStatus = 'rejected'
  u.kycReviewedAt = new Date()
  await u.save()
  res.json({ user: u })
})

// ===============================
// 🛒 Admin product management (minimal)
// ===============================
// Multer storage for product images
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const dir = path.join(process.cwd(), 'public', 'uploads', 'products');
    try {
      fs.mkdirSync(dir, { recursive: true });
    } catch {}
    cb(null, dir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname || '.jpg');
    cb(null, `${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`);
  }
});
const upload = multer({ storage });
// Create a product for a specific vendor
router.post('/vendors/:vendorId/products', authRequired('admin'), upload.single('image'), async (req, res) => {
  try {
    console.log('🔵 [ADMIN] Create product request received');
    const { vendorId } = req.params;
  const { name, description, price, category, quantity, unit, imageUrl, available, prepDurationMins } = req.body || {};
    console.log('➡️ body:', req.body);
    console.log('➡️ file:', req.file?.filename);
    if (!name || price == null || quantity == null) {
      return res.status(400).json({ error: 'Missing required fields: name, price, quantity' });
    }
    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found' });
    const filePath = req.file ? `/uploads/products/${req.file.filename}` : undefined;
    // Normalize tags/sections
    let tags = [];
    if (req.body && req.body.tags !== undefined) {
      if (Array.isArray(req.body.tags)) tags = req.body.tags;
      else if (typeof req.body.tags === 'string' && req.body.tags.trim()) tags = req.body.tags.split(',').map(s => s.trim());
    }
    const p = await Product.create({
      vendorId,
      name,
      description,
      price,
      category,
      quantity,
      unit,
      imageUrl: imageUrl || filePath,
      image: filePath,
      prepDurationMins: prepDurationMins ? Number(prepDurationMins) : undefined,
      available: available !== undefined ? !!available : undefined,
      tags,
    });
    console.log('✅ [ADMIN] Product created:', p._id);
    res.json({ success: true, product: p });
  } catch (error) {
    console.error('💥 Admin create product error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Optional alias: allow POST /api/admin/products with vendorId in body
router.post('/products', authRequired('admin'), upload.single('image'), async (req, res) => {
  try {
    console.log('🔵 [ADMIN] Create product (alias)');
  const { vendorId, name, description, price, category, quantity, unit, imageUrl, available, prepDurationMins } = req.body || {};
    if (!vendorId) return res.status(400).json({ error: 'vendorId is required' });
    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ error: 'Vendor not found' });
    if (!name || price == null || quantity == null) {
      return res.status(400).json({ error: 'Missing required fields: name, price, quantity' });
    }
    const filePath = req.file ? `/uploads/products/${req.file.filename}` : undefined;
    // Normalize tags/sections
    let tags = [];
    if (req.body && req.body.tags !== undefined) {
      if (Array.isArray(req.body.tags)) tags = req.body.tags;
      else if (typeof req.body.tags === 'string' && req.body.tags.trim()) tags = req.body.tags.split(',').map(s => s.trim());
    }
    const p = await Product.create({
      vendorId,
      name,
      description,
      price,
      category,
      quantity,
      unit,
      imageUrl: imageUrl || filePath,
      image: filePath,
      prepDurationMins: prepDurationMins ? Number(prepDurationMins) : undefined,
      available: available !== undefined ? !!available : undefined,
      tags,
    });
    console.log('✅ [ADMIN] Product created (alias):', p._id);
    res.json({ success: true, product: p });
  } catch (error) {
    console.error('💥 Admin create product (alias) error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update a product
router.put('/products/:id', authRequired('admin'), upload.single('image'), async (req, res) => {
  try {
    const { id } = req.params;
    const p = await Product.findById(id);
    if (!p) return res.status(404).json({ error: 'Product not found' });
    const fields = ['name','description','price','category','quantity','unit','imageUrl','available','discountPrice','prepDurationMins'];
    fields.forEach((f) => {
      if (req.body[f] !== undefined) p[f] = req.body[f];
    });
    // Handle tags (string or array)
    if (req.body.tags !== undefined) {
      if (Array.isArray(req.body.tags)) p.tags = req.body.tags;
      else if (typeof req.body.tags === 'string') {
        p.tags = req.body.tags.split(',').map(s => s.trim()).filter(Boolean);
      }
    }
    if (req.file) {
      const filePath = `/uploads/products/${req.file.filename}`;
      p.imageUrl = filePath;
      p.image = filePath;
    }
    await p.save();
    res.json({ success: true, product: p });
  } catch (error) {
    console.error('Admin stock update error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ===============================
// 🚚 Dispatcher Management
// ===============================

// Register a new dispatcher (admin only)
router.post('/dispatchers', authRequired('admin'), async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    // Validate required fields
    if (!name || !email || !password || !phone) {
      return res.status(400).json({ error: 'All fields are required' });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Create dispatcher user
    const dispatcher = await User.create({
      name,
      email,
      password, // Will be hashed by the model pre-save hook
      role: 'dispatcher',
      isVerified: true, // Admin-created dispatchers are pre-verified
      profile: {
        phone
      }
    });

    // Remove password from response
    const dispatcherResponse = dispatcher.toObject();
    delete dispatcherResponse.password;

    res.status(201).json({ 
      success: true, 
      dispatcher: dispatcherResponse,
      message: 'Dispatcher registered successfully'
    });
  } catch (error) {
    console.error('Dispatcher registration error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Update dispatcher status (activate/deactivate)
router.put('/dispatchers/:id', authRequired('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    const dispatcher = await User.findById(id);
    if (!dispatcher || dispatcher.role !== 'dispatcher') {
      return res.status(404).json({ error: 'Dispatcher not found' });
    }

    dispatcher.isActive = isActive;
    await dispatcher.save();

    const dispatcherResponse = dispatcher.toObject();
    delete dispatcherResponse.password;

    res.json({ success: true, dispatcher: dispatcherResponse });
  } catch (error) {
    console.error('Dispatcher update error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Delete a product
router.delete('/products/:id', authRequired('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    await Product.findByIdAndUpdate(id, { isDeleted: true });
    res.json({ success: true });
  } catch (error) {
    console.error('Admin delete product error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Toggle availability
router.patch('/products/:id/availability', authRequired('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    const { available } = req.body || {};
    const p = await Product.findById(id);
    if (!p) return res.status(404).json({ error: 'Product not found' });
    p.available = !!available;
    await p.save();
    res.json({ success: true, product: p });
  } catch (error) {
    console.error('Admin availability error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Adjust stock
router.patch('/products/:id/stock', authRequired('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body || {};
    if (quantity == null || Number.isNaN(Number(quantity))) {
      return res.status(400).json({ error: 'Invalid quantity' });
    }
    const p = await Product.findById(id);
    if (!p) return res.status(404).json({ error: 'Product not found' });
    p.quantity = Number(quantity);
    await p.save();
    res.json({ success: true, product: p });
  } catch (error) {
    console.error('Admin stock update error:', error);
    res.status(500).json({ error: error.message });
  }
});

export default router;
