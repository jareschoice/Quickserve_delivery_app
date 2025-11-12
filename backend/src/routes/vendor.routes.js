import express from "express";
import mongoose from "mongoose";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// Public: list vendors (minimal info for home page)
router.get('/', async (req, res) => {
  try {
    const vendors = await Vendor.find({ isActive: { $ne: false } })
      .select('storeName category wallet businessAddress user')
      .sort({ createdAt: -1 });
    // Back-compat shape for frontend expecting businessName
    const shaped = vendors.map(v => ({
      _id: v._id,
      userId: v.user,
      businessName: v.storeName || 'Vendor',
      category: v.category || 'General',
      minimumOrder: 1000,
      address: v.businessAddress || '',
    }));
    res.json({ vendors: shaped });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Create/Update vendor profile (minimal fields per schema)
router.post("/profile", authRequired("vendor"), async (req, res) => {
  try {
    const user = req.user._id || req.user.id; // Support both _id and id
    const { storeName } = req.body;
    let v = await Vendor.findOne({ user });
    if (!v) {
      v = await Vendor.create({ user, storeName });
    } else {
      if (storeName) v.storeName = storeName;
      await v.save();
    }
    res.json({ vendor: v });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Get my vendor profile
router.get("/me", authRequired("vendor"), async (req, res) => {
  const v = await Vendor.findOne({ user: req.user._id || req.user.id });
  res.json({ vendor: v });
});

// Get vendor profile (alias endpoint for frontend compatibility)
router.get("/profile", authRequired("vendor"), async (req, res) => {
  try {
    const userId = req.user._id || req.user.id;
    let v = await Vendor.findOne({ user: userId }).populate('user', 'name email');
    
    if (!v) {
      // Auto-create vendor profile if doesn't exist
      const User = mongoose.model('User');
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ error: "User not found" });
      }
      
      v = await Vendor.create({ 
        user: userId,
        storeName: user.name + "'s Store",
        ownerName: user.name,
        category: 'Restaurant'
      });
      v = await Vendor.findById(v._id).populate('user', 'name email');
    }
    
    res.json({ 
      vendor: v,
      vendorId: v.vendorId || 'VEN-000',
      businessName: v.businessName || v.storeName || 'My Business',
      ownerName: v.ownerName || v.user?.name || 'Vendor Owner',
      category: v.category || 'Restaurant',
      phone: v.phone || '',
      address: v.businessAddress || '',
      email: v.user?.email || '',
      availabilityStatus: v.availabilityStatus || 'online',
      isActive: v.isActive !== false
    });
  } catch (e) {
    console.error('Vendor profile error:', e);
    res.status(500).json({ error: e.message });
  }
});

// Vendor wallet - READ ONLY (for transparency, no withdrawal)
// Shows total sales for record-keeping. Admin pays manually after event.
router.get("/wallet", authRequired("vendor"), async (req, res) => {
  try {
    // JWT token contains _id field, not id
    const userId = req.user._id || req.user.id;
    console.log('🔍 [WALLET] Looking for vendor with user:', userId);
    const v = await Vendor.findOne({ user: userId });
    console.log('🔍 [WALLET] Found vendor:', v ? `✅ ${v.businessName}` : '❌ Not found');
    if (!v) return res.status(400).json({ error: "Vendor profile not found" });
    
    // Import Order model to calculate real earnings
    const Order = mongoose.model('Order');
    // Orders have vendorId field at top level (references User._id not Vendor._id)
    const orders = await Order.find({ 
      vendorId: userId,  // Use User._id from JWT token
      status: { $nin: ['cancelled'] } // Exclude cancelled orders
    });

    // Calculate total sales from all orders (delivered and in-progress)
    let totalSales = 0;
    let completedSales = 0;
    orders.forEach(order => {
      // Sum up all items in the order (order.total is already calculated)
      const orderTotal = order.total || 0;
      totalSales += orderTotal;
      if (order.status === 'delivered' || order.status === 'completed') {
        completedSales += orderTotal;
      }
    });

    res.json({
      totalSales,           // Total from all orders
      completedSales,       // Only from delivered orders
      pendingSales: totalSales - completedSales,
      ordersCount: orders.length,
      completedOrdersCount: orders.filter(o => o.status === 'delivered' || o.status === 'completed').length,
      readOnly: true,       // Flag for frontend to hide withdrawal options
      message: "Sales record only. Admin will process payout after event."
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// WITHDRAWAL DISABLED - Vendors cannot withdraw
// Admin processes payouts manually after event
router.post("/wallet/withdraw", authRequired("vendor"), async (req, res) => {
  res.status(403).json({ 
    error: "Withdrawal not available. Admin will process payouts after the event ends.",
    readOnly: true
  });
});

export default router;
