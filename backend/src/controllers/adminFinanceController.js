// ===============================
// FILE: backend/src/controllers/adminFinanceController.js
// ===============================

import Transaction from "../models/Transaction.js";
import Vendor from "../models/Vendor.js";
import User from "../models/User.js";
import Order from "../models/Order.js";

// =====================================
// ✳️ GET FINANCIAL SUMMARY
// =====================================
export const getFinanceSummary = async (req, res) => {
  try {
    const [totalRevenue, totalPayouts, totalFees] = await Promise.all([
      // Total delivered order revenue
      Order.aggregate([
        { $match: { status: "delivered" } },
        { $group: { _id: null, total: { $sum: "$subtotal" } } },
      ]),
      // Total vendor payouts
      Transaction.aggregate([
        { $match: { "meta.reason": "vendor_wallet_adjustment", type: "credit" } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
      // Platform service fees
      Transaction.aggregate([
        { $match: { "meta.reason": "admin_fee" } },
        { $group: { _id: null, total: { $sum: "$amount" } } },
      ]),
    ]);

    const totalVendors = await Vendor.countDocuments();
    const totalCustomers = await User.countDocuments({ role: "customer" });
    const totalRiders = await User.countDocuments({ role: "rider" });

    const activeVendorWallets = await Vendor.aggregate([
      { $group: { _id: null, balance: { $sum: "$wallet" } } },
    ]);

    res.json({
      success: true,
      summary: {
        totalRevenue: totalRevenue[0]?.total || 0,
        totalVendorPayouts: totalPayouts[0]?.total || 0,
        totalServiceFees: totalFees[0]?.total || 0,
        totalVendors,
        totalCustomers,
        totalRiders,
        totalWalletBalance: activeVendorWallets[0]?.balance || 0,
      },
    });
  } catch (e) {
    console.error("getFinanceSummary error", e);
    res.status(500).json({ error: "Failed to fetch finance summary" });
  }
};

// =====================================
// ✳️ GET TRANSACTION BREAKDOWN BY ROLE
// =====================================
export const getTransactionBreakdown = async (req, res) => {
  try {
    const roleGroups = await Transaction.aggregate([
      {
        $lookup: {
          from: "users",
          localField: "user",
          foreignField: "_id",
          as: "user",
        },
      },
      { $unwind: "$user" },
      {
        $group: {
          _id: "$user.role",
          totalCredits: {
            $sum: {
              $cond: [{ $eq: ["$type", "credit"] }, "$amount", 0],
            },
          },
          totalDebits: {
            $sum: {
              $cond: [{ $eq: ["$type", "debit"] }, "$amount", 0],
            },
          },
          count: { $sum: 1 },
        },
      },
    ]);

    res.json({ success: true, breakdown: roleGroups });
  } catch (e) {
    console.error("getTransactionBreakdown error", e);
    res.status(500).json({ error: "Failed to fetch transaction breakdown" });
  }
};

// =====================================
// ✳️ GET RECENT TRANSACTIONS (ADMIN VIEW)
// =====================================
export const getRecentTransactions = async (req, res) => {
  try {
    const transactions = await Transaction.find({})
      .sort({ createdAt: -1 })
      .limit(20)
      .populate("user", "name email role");

    res.json({ success: true, transactions });
  } catch (e) {
    res.status(500).json({ error: "Failed to fetch recent transactions" });
  }
};
