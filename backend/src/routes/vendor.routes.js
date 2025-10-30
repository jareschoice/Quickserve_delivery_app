import express from "express";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// Create/Update vendor profile (minimal fields per schema)
router.post("/profile", authRequired("vendor"), async (req, res) => {
  try {
    const user = req.user.id;
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
  const v = await Vendor.findOne({ user: req.user.id });
  res.json({ vendor: v });
});

// Vendor wallet with weekly hold
router.get("/wallet", authRequired("vendor"), async (req, res) => {
  const v = await Vendor.findOne({ user: req.user.id });
  if (!v) return res.status(400).json({ error: "Vendor profile not found" });
  const last = v.lastWithdrawAt ? new Date(v.lastWithdrawAt) : null;
  const now = new Date();
  const nextEligibleAt = last ? new Date(last.getTime() + 7 * 24 * 60 * 60 * 1000) : now; // if never withdrawn, allow now
  const canWithdraw = !last || now >= nextEligibleAt;

  // Optional: derive balance from transactions in future; for now use stored wallet
  res.json({
    balance: v.wallet || 0,
    lastWithdrawAt: v.lastWithdrawAt || null,
    nextEligibleAt,
    canWithdraw,
  });
});

router.post("/wallet/withdraw", authRequired("vendor"), async (req, res) => {
  const { amount } = req.body;
  const v = await Vendor.findOne({ user: req.user.id });
  if (!v) return res.status(400).json({ error: "Vendor profile not found" });
  const now = new Date();
  const last = v.lastWithdrawAt ? new Date(v.lastWithdrawAt) : null;
  const nextEligibleAt = last ? new Date(last.getTime() + 7 * 24 * 60 * 60 * 1000) : now;
  if (last && now < nextEligibleAt) {
    return res.status(400).json({ error: `Withdrawal not yet eligible. Try after ${nextEligibleAt.toISOString()}` });
  }
  const amt = Number(amount || 0);
  if (amt <= 0) return res.status(400).json({ error: "Invalid amount" });
  if ((v.wallet || 0) < amt) return res.status(400).json({ error: "Insufficient balance" });

  v.wallet = (v.wallet || 0) - amt;
  v.lastWithdrawAt = now;
  await v.save();

  // Record transaction (debit)
  await Transaction.create({ user: req.user.id, amount: amt, type: 'debit', meta: { kind: 'vendor_withdrawal' } });
  res.json({ ok: true, balance: v.wallet, lastWithdrawAt: v.lastWithdrawAt });
});

export default router;
