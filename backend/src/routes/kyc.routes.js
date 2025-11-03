// ===============================
// FILE: backend/src/routes/kyc.routes.js
// ===============================
import express from "express";
import {
  submitKyc,
  getKycStatus,
  verifyVendorKYC, // ✅ Added this
} from "../controllers/kycController.js";
import { authRequired } from "../middleware/auth.js"; // ✅ Keep only one import

const router = express.Router();

// ===============================
// ✳️ KYC SUBMISSION (Vendor or Rider)
// ===============================
router.post("/submit", authRequired("vendor", "rider"), submitKyc);

// ===============================
// ✳️ FETCH KYC STATUS
// ===============================
router.get("/status", authRequired(), getKycStatus);

// ===============================
// ✳️ ADMIN VERIFY VENDOR KYC
// ===============================
// 📍 ADD THIS AT THE BOTTOM OF THE FILE
router.post("/verify", authRequired("admin"), verifyVendorKYC);

// ✅ Always export the router at the end
export default router;
