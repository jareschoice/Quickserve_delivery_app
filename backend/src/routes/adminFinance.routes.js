// ===============================
// FILE: backend/src/routes/adminFinance.routes.js
// ===============================
import express from "express";
import Order from "../models/Order.js";
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import Vendor from "../models/Vendor.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

/**
 * @desc Admin Finance Overview
 * @route GET /api/admin/finance/overview
 * @access Private (Admin)
 */
router.get("/overview", authRequired("admin"), async (req, res) => {
  try {
    // ✅ Total number of orders
    const totalOrders = await Order.countDocuments();

    // ✅ Delivered orders = Completed revenue
    const deliveredOrders = await Order.countDocuments({ status: "delivered" });

    // ✅ Cancelled orders
    const cancelledOrders = await Order.countDocuments({ status: "cancelled" });

    // ✅ Total refund value
    const totalRefunds = await Transaction.aggregate([
      { $match: { "meta.reason": "refund" } },
      { $group: { _id: null, amount: { $sum: "$amount" } } },
    ]);

    // ✅ Total admin commission (from service fees)
    const totalAdminCommission = await Transaction.aggregate([
      { $match: { "meta.kind": "admin_fee" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    // ✅ Total vendor earnings (delivered)
    const totalVendorEarnings = await Transaction.aggregate([
      { $match: { "meta.kind": "vendor_earning" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    // ✅ Total wallet balance across users
    const totalWallets = await User.aggregate([
      { $group: { _id: null, sum: { $sum: "$wallet" } } },
    ]);

    // ✅ Total vendors & riders
    const totalVendors = await User.countDocuments({ role: "vendor" });
    const totalRiders = await User.countDocuments({ role: "rider" });
    const totalCustomers = await User.countDocuments({ role: "customer" });

    // ✅ Monthly revenue trend (last 6 months)
    const revenueTrend = await Order.aggregate([
      { $match: { status: "delivered" } },
      {
        $group: {
          _id: { $substr: ["$createdAt", 0, 7] },
          revenue: { $sum: "$subtotal" },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    res.json({
      success: true,
      finance: {
        totals: {
          totalOrders,
          deliveredOrders,
          cancelledOrders,
          totalRefunds: totalRefunds[0]?.amount || 0,
          totalAdminCommission: totalAdminCommission[0]?.total || 0,
          totalVendorEarnings: totalVendorEarnings[0]?.total || 0,
          totalWalletBalance: totalWallets[0]?.sum || 0,
        },
        users: {
          totalVendors,
          totalRiders,
          totalCustomers,
        },
        revenueTrend,
      },
    });
  } catch (err) {
    console.error("Admin Finance Overview Error:", err);
    res.status(500).json({ error: "Failed to fetch finance overview" });
  }
});

/**
 * @desc Get Admin Commission Logs
 * @route GET /api/admin/finance/commissions
 * @access Private (Admin)
 */
router.get("/commissions", authRequired("admin"), async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const commissions = await Transaction.find({ "meta.kind": "admin_fee" })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate("user", "name email role");

    const totalCount = await Transaction.countDocuments({ "meta.kind": "admin_fee" });

    res.json({
      success: true,
      pagination: {
        page,
        totalPages: Math.ceil(totalCount / limit),
        totalCount,
      },
      commissions,
    });
  } catch (err) {
    console.error("Admin Commission Fetch Error:", err);
    res.status(500).json({ error: "Failed to fetch commission logs" });
  }
});

/**
 * @desc Get Wallet Leaderboard (Top 10 Richest Users)
 * @route GET /api/admin/finance/wallet-leaderboard
 * @access Private (Admin)
 */
router.get("/wallet-leaderboard", authRequired("admin"), async (req, res) => {
  try {
    const users = await User.find({}, "name email role wallet")
      .sort({ wallet: -1 })
      .limit(10);

    res.json({ success: true, leaderboard: users });
  } catch (err) {
    console.error("Wallet Leaderboard Error:", err);
    res.status(500).json({ error: "Failed to fetch wallet leaderboard" });
  }
});

export default router;
