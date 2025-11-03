// ===============================
// FILE: backend/src/routes/wallet.routes.js
// ===============================
import express from "express";
import {
  getWalletBalance,
  requestWithdrawal,
  getTransactionHistory,
  getMyWithdrawals,       // ✅ Added
  adminAdjustWallet       // ✅ Added
} from "../controllers/walletController.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// ✅ Get wallet balance and latest transactions
router.get("/", authRequired(), getWalletBalance);

// ✅ Request withdrawal
router.post("/withdraw", authRequired(), requestWithdrawal);

// ✅ View full transaction history
router.get("/history", authRequired(), getTransactionHistory);

// ✅ View withdrawal history (new)
router.get("/withdrawals", authRequired(), getMyWithdrawals);

// ✅ Admin manual credit/debit (new)
router.post("/adjust", authRequired("admin"), adminAdjustWallet);

// ✅ Always keep export at the very end
export default router;
