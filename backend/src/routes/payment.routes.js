import express from "express";
import { paystack } from "../lib/paystack.js";
import Order from "../models/Order.js";

const router = express.Router();

// Initialize transaction (amount in Naira; convert to kobo)
router.post("/init", async (req, res) => {
  try {
    const { email, amount, orderId, type = 'order', subscriptionId } = req.body;
    if (!email || !amount) return res.status(400).json({ error: "Missing email/amount" });
    const kobo = Math.round(Number(amount) * 100);
    const ref = `QS_${orderId || ""}_${Date.now()}`;

    const { data } = await paystack.post("/transaction/initialize", {
      email,
      amount: kobo,
      reference: ref,
      callback_url: `${process.env.APP_BASE_URL}/payments/verify`,
      metadata: { orderId, type, subscriptionId },
    });

    // store reference on order
    if (orderId) {
      const o = await Order.findById(orderId);
      if (o) {
        o.payment = { reference: ref, paid: false };
        await o.save();
      }
    }

    res.json({ authorization_url: data.data.authorization_url, reference: data.data.reference });
  } catch (e) {
    res.status(500).json({ error: e.response?.data || e.message });
  }
});

export default router;
