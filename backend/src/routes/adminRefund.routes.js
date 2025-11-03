// ===============================
// FILE: backend/src/routes/adminRefund.routes.js
// ===============================
import express from "express";
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

/**
 * @desc Admin Refunds Overview
 * @route GET /api/admin/refunds
 * @access Private (Admin)
 */
router.get("/", authRequired("admin"), async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;

    // ✅ Filter refunds by keyword (email, name, orderId)
    const search = req.query.search || "";
    const query = {
      "meta.reason": "refund",
    };

    // Dynamic filter by keyword
    if (search) {
      query.$or = [
        { "meta.order": { $regex: search, $options: "i" } },
        { "meta.metaReason": { $regex: search, $options: "i" } },
      ];
    }

    // Fetch refund transactions
    const refunds = await Transaction.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate("user", "name email role");

    const totalCount = await Transaction.countDocuments(query);

    // ✅ Calculate summary totals
    const totalRefunds = await Transaction.aggregate([
      { $match: { "meta.reason": "refund" } },
      { $group: { _id: null, total: { $sum: "$amount" } } },
    ]);

    res.json({
      success: true,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(totalCount / limit),
        totalCount,
      },
      summary: {
        totalRefundAmount: totalRefunds[0]?.total || 0,
      },
      refunds: refunds.map((r) => ({
        id: r._id,
        user: {
          name: r.user?.name || "N/A",
          email: r.user?.email || "N/A",
          role: r.user?.role || "N/A",
        },
        amount: r.amount,
        date: r.createdAt,
        orderId: r.meta?.order,
        reason: r.meta?.metaReason || "Order refund",
        via: r.meta?.via || "system_auto",
        status: r.status,
      })),
    });
  } catch (e) {
    console.error("adminRefunds error:", e);
    res.status(500).json({ error: "Failed to fetch refunds" });
  }
});

export default router;
