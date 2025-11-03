// ===============================
// FILE: backend/src/controllers/walletActionController.js
// ===============================
import User from "../models/User.js";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import { adjustUserWallet, adjustVendorWallet } from "../utils/wallet.js";

// =====================================
// ✳️ ADMIN MANUALLY TOP UP ANY USER/VENDOR WALLET
// =====================================
export const adminTopUpWallet = async (req, res) => {
  try {
    const { userId, role, amount, reason } = req.body;
    if (!userId || !amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid user or amount" });
    }

    if (role === "vendor") {
      await adjustVendorWallet(userId, amount, "credit", {
        reason: reason || "admin_topup",
        via: "admin_panel",
        stage: "manual_funding",
      });
    } else {
      await adjustUserWallet(userId, amount, "credit", {
        reason: reason || "admin_topup",
        via: "admin_panel",
        stage: "manual_funding",
      });
    }

    res.json({ success: true, message: `₦${amount} added to ${role}'s wallet` });
  } catch (e) {
    console.error("adminTopUpWallet error", e);
    res.status(500).json({ error: "Failed to top up wallet" });
  }
};

// =====================================
// ✳️ USER TRANSFERS FUNDS TO ANOTHER USER (Wallet-to-Wallet)
// =====================================
export const transferFunds = async (req, res) => {
  try {
    const { receiverEmail, amount } = req.body;
    if (!receiverEmail || !amount || amount <= 0) {
      return res.status(400).json({ error: "Invalid input" });
    }

    // Sender (from token)
    const sender = await User.findById(req.user._id);
    if (!sender) return res.status(404).json({ error: "Sender not found" });

    const receiver = await User.findOne({ email: receiverEmail });
    if (!receiver) return res.status(404).json({ error: "Receiver not found" });

    if (sender._id.equals(receiver._id)) {
      return res.status(400).json({ error: "Cannot transfer to yourself" });
    }

    if (sender.wallet < amount) {
      return res.status(400).json({ error: "Insufficient balance" });
    }

    // Debit sender and credit receiver
    await adjustUserWallet(sender._id, amount, "debit", {
      reason: "wallet_transfer",
      via: "user_wallet",
      stage: "transfer_out",
      to: receiver.email,
    });

    await adjustUserWallet(receiver._id, amount, "credit", {
      reason: "wallet_transfer",
      via: "user_wallet",
      stage: "transfer_in",
      from: sender.email,
    });

    res.json({
      success: true,
      message: `₦${amount} transferred successfully to ${receiver.email}`,
    });
  } catch (e) {
    console.error("transferFunds error", e);
    res.status(500).json({ error: "Failed to process transfer" });
  }
};

// =====================================
// ✳️ ADMIN CHECK USER BALANCE QUICKLY
// =====================================
export const adminCheckWallet = async (req, res) => {
  try {
    const { email } = req.query;
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ error: "User not found" });

    res.json({ success: true, wallet: user.wallet, role: user.role });
  } catch (e) {
    res.status(500).json({ error: "Failed to fetch wallet" });
  }
};
