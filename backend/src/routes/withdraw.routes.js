// ===============================
// FILE: backend/src/routes/withdraw.routes.js
// ===============================
import express from "express";
import {
  createWithdrawRequest,
  updateWithdrawStatus,
  getAllWithdrawRequests,
  getMyWithdrawRequests
} from "../controllers/withdrawController.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// ✅ Vendor or Rider requests withdrawal
router.post("/", authRequired(), createWithdrawRequest);

// ✅ Vendor or Rider views their past withdrawals
router.get("/mine", authRequired(), getMyWithdrawRequests);

// ✅ Admin views all withdrawal requests
router.get("/admin/all", authRequired("admin"), getAllWithdrawRequests);

// ✅ Admin approves/rejects/marks paid
router.put("/:id/status", authRequired("admin"), updateWithdrawStatus);

export default router;
