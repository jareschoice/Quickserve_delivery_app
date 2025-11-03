// ===============================
// FILE: backend/src/controllers/walletController.js
// ===============================
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import Vendor from "../models/Vendor.js";
import { adjustUserWallet } from "../utils/wallet.js";
import { sendNotification } from "../utils/notify.js";

/**
 * ✅ Get current wallet balance for logged-in user
 */
export const getWalletBalance = async (req, res) => {
  try {
    const role = req.user.role;
    let balance = 0;

    if (role === "vendor") {
      const vendor = await Vendor.findOne({ user: req.user._id });
      balance = vendor?.wallet || 0;
    } else {
      const user = await User.findById(req.user._id);
      balance = user?.wallet || 0;
    }

    const tx = await Transaction.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .limit(10);

    res.json({
      success: true,
      balance,
      currency: "NGN",
      recentTransactions: tx,
    });
  } catch (e) {
    console.error("getWalletBalance error:", e.message);
    res.status(500).json({ error: "Failed to fetch wallet" });
  }
};

/**
 * ✅ Request withdrawal (manual for now)
 */
export const requestWithdrawal = async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0)
      return res.status(400).json({ error: "Invalid amount" });

    // Deduct temporarily and log
    await adjustUserWallet(req.user._id, amount, "debit", {
      reason: "withdrawal_request",
    });

    // Notify admins
    await sendNotification({
      title: "Withdrawal Request",
      message: `${req.user.name} requested ₦${amount} withdrawal.`,
      type: "wallet",
      userId: req.user._id,
      app: req.app,
    });

    // Real-time emit
    req.app.get("io")?.to(`user:${req.user._id}`).emit("wallet:update", {
      userId: req.user._id,
      amountChange: -amount,
      type: "withdrawal_request",
      time: new Date().toISOString(),
    });

    res.json({
      success: true,
      message: "Withdrawal request received and logged",
    });
  } catch (e) {
    console.error("requestWithdrawal error:", e.message);
    res.status(500).json({ error: e.message });
  }
};

/**
 * ✅ Fetch full transaction history
 */
export const getTransactionHistory = async (req, res) => {
  try {
    const tx = await Transaction.find({ user: req.user._id }).sort({
      createdAt: -1,
    });
    res.json({ success: true, transactions: tx });
  } catch (e) {
    console.error("getTransactionHistory error:", e.message);
    res.status(500).json({ error: "Failed to fetch transaction history" });
  }
};
/**
 * ✅ FETCH MY WITHDRAWAL REQUESTS
 * Shows all withdrawal requests made by the logged-in user.
 */
export const getMyWithdrawals = async (req, res) => {
  try {
    const tx = await import("../models/Transaction.js").then((m) =>
      m.default.find({
        user: req.user._id,
        "meta.reason": "withdrawal_request",
      }).sort({ createdAt: -1 })
    );

    res.json({
      success: true,
      count: tx.length,
      withdrawals: tx,
    });
  } catch (err) {
    console.error("getMyWithdrawals error:", err.message);
    res.status(500).json({ error: "Failed to fetch withdrawals" });
  }
};

/**
 * ✅ ADMIN ADJUST WALLET (Manual Credit or Debit)
 * Allows admin to modify user or vendor wallet balance manually.
 */
export const adminAdjustWallet = async (req, res) => {
  try {
    const { userId, amount, type, note } = req.body;
    if (!userId || !amount || !type)
      return res.status(400).json({ error: "userId, amount, and type are required" });

    const user = await import("../models/User.js").then((m) => m.default.findById(userId));
    if (!user) return res.status(404).json({ error: "User not found" });

    // Detect if vendor profile exists for this user
    const vendor = await import("../models/Vendor.js").then((m) => m.default.findOne({ user: userId }));

    if (user.role === "vendor" && vendor) {
      // Vendor wallet adjustment
      const { adjustVendorWallet } = await import("../utils/wallet.js");
      await adjustVendorWallet(userId, Number(amount), type, {
        reason: "admin_manual_adjustment",
        note,
        actor: "admin",
      });
    } else {
      // Regular user adjustment
      const { adjustUserWallet } = await import("../utils/wallet.js");
      await adjustUserWallet(userId, Number(amount), type, {
        reason: "admin_manual_adjustment",
        note,
        actor: "admin",
      });
    }

    res.json({
      success: true,
      message: `Wallet ${type} of ₦${amount} applied successfully.`,
    });
  } catch (err) {
    console.error("adminAdjustWallet error:", err.message);
    res.status(500).json({ error: "Failed to adjust wallet", detail: err.message });
  }
};
import { initiateTransfer } from "../utils/paystack.js";


// ✅ Vendor Automated Withdrawal via Paystack
export const vendorWithdrawPaystack = async (req, res) => {
  try {
    const { amount } = req.body;
    const vendor = await Vendor.findOne({ user: req.user._id });
    if (!vendor) return res.status(404).json({ error: "Vendor not found" });

    if (!vendor.kycVerified)
      return res.status(403).json({ error: "KYC verification required before withdrawal" });

    if (!vendor.paystackRecipientCode)
      return res.status(400).json({ error: "No Paystack recipient configured" });

    if (vendor.wallet < amount)
      return res.status(400).json({ error: "Insufficient balance" });

    // Deduct from wallet first
    vendor.wallet -= amount;
    await vendor.save();

    // Initiate transfer via Paystack
    const transfer = await initiateTransfer(amount, vendor.paystackRecipientCode, "Vendor withdrawal");

    // Log transaction
    await Transaction.create({
      user: req.user._id,
      amount,
      type: "debit",
      status: "pending",
      meta: {
        reason: "vendor_withdrawal",
        paystack_transfer: transfer.data?.transfer_code,
      },
    });

    res.json({
      success: true,
      message: "Withdrawal initiated via Paystack",
      transfer,
    });
  } catch (err) {
    console.error("vendorWithdrawPaystack error:", err.message);
    res.status(500).json({ error: "Withdrawal failed", details: err.message });
  }
};


