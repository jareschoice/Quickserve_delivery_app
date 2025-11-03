// ===============================
// FILE: backend/src/routes/wallet.action.routes.js
// ===============================
import express from "express";
import {
  adminTopUpWallet,
  transferFunds,
  adminCheckWallet,
} from "../controllers/walletActionController.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// ✅ Admin funds user/vendor
router.post("/admin/topup", authRequired("admin"), adminTopUpWallet);

// ✅ Admin checks user wallet balance
router.get("/admin/check", authRequired("admin"), adminCheckWallet);

// ✅ Logged-in user transfers to another wallet
router.post("/transfer", authRequired(), transferFunds);

export default router;
