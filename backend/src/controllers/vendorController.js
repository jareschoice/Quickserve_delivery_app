// ===============================
// FILE: controllers/vendorController.js
// ===============================

import Product from '../models/Product.js'
import Order from '../models/Order.js'
import Transaction from '../models/Transaction.js'
import Vendor from '../models/Vendor.js'
import User from '../models/User.js'

// =====================================
// ✳️ CREATE PRODUCT
// =====================================
export const createProduct = async (req, res) => {
  try {
    const { name, price, quantity, description, prepDurationMins } = req.body
    if (!name || !price || !quantity)
      return res.status(400).json({ error: 'Missing required fields' })

    const imageUrl = req.file ? `/uploads/${req.file.filename}` : req.body.imageUrl

    const product = await Product.create({
      vendorId: req.user._id,
      name,
      price: Number(price),
      quantity: Number(quantity),
      description,
      ...(prepDurationMins ? { prepDurationMins: Number(prepDurationMins) } : {}),
      imageUrl,
    })

    res.json({ success: true, product })
  } catch (e) {
    console.error('createProduct error', e)
    res.status(500).json({ error: 'Failed to create product' })
  }
}

// =====================================
// ✳️ LIST VENDOR PRODUCTS
// =====================================
export const listProducts = async (req, res) => {
  try {
    const products = await Product.find({ vendorId: req.user._id }).sort('-createdAt')
    res.json({ success: true, products })
  } catch (e) {
    console.error('listProducts error', e)
    res.status(500).json({ error: 'Failed to fetch products' })
  }
}

// =====================================
// ✳️ PACK ORDER & APPLY SERVICE FEE
// =====================================
export const packOrder = async (req, res) => {
  try {
    const { id } = req.params
    const order = await Order.findOne({ _id: id, vendorId: req.user._id })
    if (!order) return res.status(404).json({ error: 'Order not found' })

    order.status = 'ready'
    await order.save()

    // ₦50 service fee (adjustable via .env)
    const fee = Number(process.env.PACKING_FEE || 50)
    await Transaction.create({
      user: null,
      order: order._id,
      amount: fee,
      type: 'credit',
      meta: { reason: 'packing_fee' }
    })

    res.json({ success: true, order })
  } catch (e) {
    console.error('packOrder error', e)
    res.status(500).json({ error: 'Failed to mark order as packed' })
  }
}

// =====================================
// ✳️ GET WALLET BALANCE
// =====================================
export const getWallet = async (req, res) => {
  try {
    const tx = await Transaction.aggregate([
      { $match: { user: req.user._id, type: 'credit' } },
      { $group: { _id: null, total: { $sum: '$amount' } } }
    ])
    const balance = tx[0]?.total || 0

    const now = new Date()
    const nextWithdrawAt = new Date(now.getTime() + 6 * 24 * 60 * 60 * 1000)

    res.json({ success: true, balance, currency: 'NGN', nextWithdrawAt })
  } catch (e) {
    console.error('getWallet error', e)
    res.status(500).json({ error: 'Failed to fetch wallet info' })
  }
}

// =====================================
// ✳️ REQUEST WITHDRAWAL
// =====================================
export const requestWithdraw = async (req, res) => {
  try {
    // Placeholder logic — can later connect to Payment Gateway
    res.json({ success: true, scheduled: true, message: 'Withdrawal request submitted' })
  } catch (e) {
    console.error('requestWithdraw error', e)
    res.status(500).json({ error: 'Failed to submit withdrawal request' })
  }
}

// =====================================
// ✳️ SET NOTIFICATION PREFERENCES
// =====================================
export const setNotificationPref = async (req, res) => {
  try {
    const { incomingOrderAlerts } = req.body
    req.user.profile = req.user.profile || {}
    req.user.profile.incomingOrderAlerts = Boolean(incomingOrderAlerts)
    await req.user.save()
    res.json({ success: true, profile: req.user.profile })
  } catch (e) {
    console.error('setNotificationPref error', e)
    res.status(500).json({ error: 'Failed to update notification preferences' })
  }
}

// =====================================
// ✳️ CREATE VENDOR ACCOUNT (Admin use)
// =====================================
export const createVendor = async (req, res) => {
  try {
    console.log('🔥 createVendor called with body:', req.body);
    
    const { 
      businessName, 
      contactPerson, 
      email, 
      phone, 
      password, 
      category, 
      minimumOrder, 
      address, 
      location, 
      description,
      // Legacy support
      storeName, 
      userId 
    } = req.body;

    // NEW: Admin registration with complete user creation
    if (businessName && email && password) {
      console.log('📝 Creating new vendor user and profile...');
      
      // Check if user exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(409).json({ error: 'Email already in use' });
      }

      // Create User account
      const user = await User.create({
        role: 'vendor',
        name: contactPerson || businessName,
        email,
        password, // Will be hashed by User model pre-save hook
        isVerified: true, // Admin-created vendors are auto-verified
        phone,
        profile: {
          businessName,
          phone,
          address,
          location
        }
      });

      console.log('✅ User created:', user._id);

      // Create Vendor profile
      const vendor = await Vendor.create({
        user: user._id,
        storeName: businessName,
        description: description || '',
        category: category || 'General',
        businessAddress: address,
        phone: phone,
        minimumOrder: minimumOrder || 0,
        location: location
      });

      console.log('✅ Vendor profile created:', vendor._id);

      return res.status(201).json({ 
        success: true, 
        message: 'Vendor registered successfully',
        vendor,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role
        }
      });
    }

    // LEGACY: Support old format (userId + storeName)
    if (userId && storeName) {
      console.log('📝 Using legacy format: userId + storeName');
      const u = await User.findById(userId);
      if (!u) return res.status(404).json({ error: 'User not found' });

      const existing = await Vendor.findOne({ user: u._id });
      if (existing) return res.status(409).json({ error: 'Vendor already exists' });

      const v = await Vendor.create({ user: u._id, storeName });
      return res.json({ success: true, vendor: v });
    }

    return res.status(400).json({ error: 'Missing required fields' });
    
  } catch (e) {
    console.error('❌ createVendor error:', e);
    res.status(500).json({ error: 'Failed to create vendor account', detail: e.message });
  }
}

// =====================================
// ✳️ REGISTER / UPDATE BUSINESS PROFILE
// =====================================
console.log("🧭 vendorController.js has been loaded successfully");
export const registerBusiness = async (req, res) => {
  try {
    console.log("🔥 registerBusiness endpoint hit")
    console.log("Headers:", req.headers)
    console.log("User from auth middleware:", req.user)

    if (!req.user || !req.user._id) {
      console.log("❌ No valid user in request")
      return res.status(401).json({ error: "Unauthorized or invalid token" })
    }

    console.log("📩 Incoming register-business request:", req.user._id)
    console.log("✅ Vendor registration request received")

    const { storeName, description, category, businessAddress, logoUrl, phone, bannerUrl } = req.body
    console.log("📦 Request body:", req.body)

    const user = await User.findById(req.user._id)
    if (!user) {
      console.log("❌ User not found in DB")
      return res.status(404).json({ error: "User not found" })
    }

    if (user.role !== "vendor")
      return res.status(403).json({ error: "Only vendors can register business" })

    console.log("🧾 User found:", user.email)

    let vendor = await Vendor.findOne({ user: user._id })
    console.log("🔎 Vendor lookup result:", vendor ? "Found existing" : "No vendor found, creating new")

    if (vendor) {
      vendor.storeName = storeName || vendor.storeName
      vendor.description = description || vendor.description
      vendor.category = category || vendor.category
      vendor.businessAddress = businessAddress || vendor.businessAddress
      vendor.logoUrl = logoUrl || vendor.logoUrl
      vendor.phone = phone || vendor.phone
      vendor.bannerUrl = bannerUrl || vendor.bannerUrl
      await vendor.save()
      console.log("✅ Vendor updated:", vendor._id)
    } else {
      vendor = await Vendor.create({
        user: user._id,
        storeName,
        description,
        category,
        businessAddress,
        logoUrl,
        phone,
        bannerUrl,
      })
      console.log("✅ Vendor created:", vendor._id)
    }

    // 🧩 Send only ONE final response here
    return res.json({
      success: true,
      message: vendor ? "Business profile updated successfully" : "Business registered successfully",
      vendor,
    })

  } catch (e) {
    console.error("❌ registerBusiness error:", e)
    if (!res.headersSent) {
      return res.status(500).json({
        error: "Failed to register or update business",
        detail: e.message,
      })
    }
  }
}



// =====================================
// ✳️ GET VENDOR BUSINESS PROFILE
// =====================================
export const getBusiness = async (req, res) => {
  try {
    const vendor = await Vendor.findOne({ user: req.user._id })
    if (!vendor) return res.status(404).json({ error: 'Business not found' })
    res.json({ success: true, vendor })
  } catch (e) {
    console.error('getBusiness error', e)
    res.status(500).json({ error: 'Failed to fetch business profile' })
  }
}

// =====================================
// ✳️ FUTURE PLACEHOLDERS (for scaling)
// =====================================

// Update store status (open/close)
export const setStoreStatus = async (req, res) => {
  res.json({ success: true, message: 'Store status toggle placeholder' })
}

// Get analytics summary (orders, sales, rating)
export const getVendorAnalytics = async (req, res) => {
  res.json({ success: true, message: 'Analytics placeholder' })
}
