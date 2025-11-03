// ===============================
// FILE: backend/src/controllers/withdrawController.js
// ===============================
import WithdrawRequest from "../models/WithdrawRequest.js";
import Transaction from "../models/Transaction.js";
import Vendor from "../models/Vendor.js";
import User from "../models/User.js";
import { adjustUserWallet, adjustVendorWallet } from "../utils/wallet.js";

// =====================================
// ✳️ VENDOR OR RIDER CREATES WITHDRAW REQUEST
// =====================================
export const createWithdrawRequest = async (req, res) => {
  try {
    const { amount, bankDetails } = req.body;
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid amount" });
    }

    const role = req.user.role;
    if (!["vendor", "rider"].includes(role)) {
      return res.status(403).json({ error: "Only vendors or riders can withdraw" });
    }

    // Check available balance
    let balance = 0;
    if (role === "vendor") {
      const vendor = await Vendor.findOne({ user: req.user._id });
      if (!vendor) return res.status(404).json({ error: "Vendor profile not found" });
      balance = vendor.wallet;
    } else {
      const rider = await User.findById(req.user._id);
      balance = rider.wallet;
    }

    if (amount > balance) {
      return res.status(400).json({ error: "Insufficient wallet balance" });
    }

    // Deduct amount temporarily
    if (role === "vendor") {
      await adjustVendorWallet(req.user._id, amount, "debit", { reason: "withdrawal_request" });
    } else {
      await adjustUserWallet(req.user._id, amount, "debit", { reason: "withdrawal_request" });
    }

    const request = await WithdrawRequest.create({
      user: req.user._id,
      amount,
      role,
      bankDetails,
      status: "pending",
    });

    res.status(201).json({ success: true, message: "Withdrawal request submitted", request });
  } catch (e) {
    console.error("createWithdrawRequest error", e);
    res.status(500).json({ error: "Failed to submit withdrawal request" });
  }
};

// =====================================
// ✳️ ADMIN APPROVES OR REJECTS REQUEST
// =====================================
export const updateWithdrawStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;

    if (!["approved", "rejected", "paid"].includes(status)) {
      return res.status(400).json({ error: "Invalid status" });
    }

    const request = await WithdrawRequest.findById(id);
    if (!request) return res.status(404).json({ error: "Request not found" });

    request.status = status;
    request.notes = notes || request.notes;
    request.approvedBy = req.user._id;
    request.approvedAt = new Date();

    // Log to transactions if paid
    if (status === "paid") {
      request.paidAt = new Date();
      await Transaction.create({
        user: request.user,
        amount: request.amount,
        type: "debit",
        meta: {
          reason: "withdrawal_payout",
          actor: request.role,
          via: "admin",
          stage: "withdrawal_completed",
        },
      });
    }

    await request.save();
    res.json({ success: true, message: `Request marked as ${status}`, request });
  } catch (e) {
    console.error("updateWithdrawStatus error", e);
    res.status(500).json({ error: "Failed to update withdrawal status" });
  }
};

// =====================================
// ✳️ ADMIN FETCH ALL REQUESTS
// =====================================
export const getAllWithdrawRequests = async (req, res) => {
  try {
    const requests = await WithdrawRequest.find({})
      .sort({ createdAt: -1 })
      .populate("user", "name email role");
    res.json({ success: true, requests });
  } catch (e) {
    console.error("getAllWithdrawRequests error", e);
    res.status(500).json({ error: "Failed to fetch withdrawal requests" });
  }
};

// =====================================
// ✳️ VENDOR/RIDER FETCH THEIR OWN REQUESTS
// =====================================
export const getMyWithdrawRequests = async (req, res) => {
  try {
    const requests = await WithdrawRequest.find({ user: req.user._id })
      .sort({ createdAt: -1 });
    res.json({ success: true, requests });
  } catch (e) {
    console.error("getMyWithdrawRequests error", e);
    res.status(500).json({ error: "Failed to fetch your withdrawal requests" });
  }
};
