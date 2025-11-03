// ===============================
// FILE: backend/src/routes/adminWallet.routes.js
// ===============================

import express from "express";
import User from "../models/User.js";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import { authRequired } from "../middleware/auth.js";
import { adjustUserWallet, adjustVendorWallet } from "../utils/wallet.js";
import { sendEmail } from "../utils/emailClient.js";

const router = express.Router();

// ===============================
// ✳️ ADMIN: MANUAL WALLET ADJUSTMENT
// ===============================
router.post("/adjust", authRequired("admin"), async (req, res) => {
  try {
    const { userId, amount, type, note } = req.body;

    if (!userId || !amount || !type)
      return res.status(400).json({ error: "userId, amount, and type are required" });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: "User not found" });

    let newBalance = 0;
    const value = Number(amount);

    if (user.role === "vendor") {
      newBalance = await adjustVendorWallet(user._id, value, type, {
        reason: "admin_manual_adjustment",
        note: note || "Wallet adjustment by admin",
      });
    } else {
      newBalance = await adjustUserWallet(user._id, value, type, {
        reason: "admin_manual_adjustment",
        note: note || "Wallet adjustment by admin",
      });
    }

    // ✅ Send email notification
    try {
      const html = `
        <div style="font-family:Arial,sans-serif;max-width:600px;margin:auto;padding:20px;">
          <h2 style="color:#16a34a;">QuickServe Wallet Update</h2>
          <p>Hi <b>${user.name}</b>,</p>
          <p>Your wallet has been <b>${type === "credit" ? "credited" : "debited"}</b> with:</p>
          <h3 style="color:#f97316;">₦${Number(value).toLocaleString()}</h3>
          <p>New Wallet Balance: <b>₦${newBalance.toLocaleString()}</b></p>
          <p><i>${note || "Admin adjustment"}</i></p>
          <hr/>
          <small>QuickServe • getquickserves.com</small>
        </div>
      `;
      await sendEmail({
        to: user.email,
        subject: `Wallet ${type === "credit" ? "Credit" : "Debit"} Notification`,
        html,
      });
    } catch (err) {
      console.warn("⚠️ Email failed to send:", err.message);
    }

    res.json({
      success: true,
      message: `Wallet ${type === "credit" ? "credited" : "debited"} successfully`,
      user: {
        name: user.name,
        email: user.email,
        role: user.role,
        wallet: newBalance,
      },
    });
  } catch (err) {
    console.error("adminWallet.adjust error:", err);
    res.status(500).json({ error: "Failed to adjust wallet" });
  }
});

// ===============================
// ✳️ ADMIN: FETCH WALLET LOGS
// ===============================
router.get("/transactions", authRequired("admin"), async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    const tx = await Transaction.find({ "meta.reason": "admin_manual_adjustment" })
      .populate("user", "name email role")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const totalCount = await Transaction.countDocuments({
      "meta.reason": "admin_manual_adjustment",
    });

    res.json({
      success: true,
      pagination: {
        page,
        totalPages: Math.ceil(totalCount / limit),
        totalCount,
      },
      data: tx,
    });
  } catch (err) {
    console.error("adminWallet.transactions error:", err);
    res.status(500).json({ error: "Failed to fetch wallet transactions" });
  }
});

export default router;
