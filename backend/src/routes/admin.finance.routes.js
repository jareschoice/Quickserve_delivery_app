// ===============================
// FILE: backend/src/routes/admin.finance.routes.js
// ===============================
import express from "express";
import {
  getFinanceSummary,
  getTransactionBreakdown,
  getRecentTransactions,
} from "../controllers/adminFinanceController.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// ✅ Only Admin can access these routes
router.get("/summary", authRequired("admin"), getFinanceSummary);
router.get("/breakdown", authRequired("admin"), getTransactionBreakdown);
router.get("/transactions", authRequired("admin"), getRecentTransactions);

export default router;
