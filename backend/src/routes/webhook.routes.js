import express from "express";
import crypto from "crypto";
import Order from "../models/Order.js";
import Subscription from "../models/Subscription.js";
import User from "../models/User.js";
import { adjustUserWallet } from "../utils/wallet.js";

const router = express.Router();

router.post("/webhook", express.json({ type: "*/*" }), async (req, res) => {
  const secret = process.env.PAYSTACK_SECRET_KEY;
  const signature = req.headers["x-paystack-signature"];
  const hash = crypto.createHmac("sha512", secret).update(JSON.stringify(req.body)).digest("hex");
  if (hash !== signature) return res.status(401).send("Invalid signature");

  const event = req.body;
  try {
    if (event.event === "charge.success") {
      const reference = event.data.reference;
      const orderId = event.data.metadata?.orderId;
      const type = event.data.metadata?.type;
      const subscriptionId = event.data.metadata?.subscriptionId;
      const o = await Order.findById(orderId);
      if (o) {
        o.payment = {
          reference,
          paid: true,
          channel: event.data.channel,
          verifiedAt: new Date(),
        };
        await o.save();

        // Consumer service charge ₦50 at checkout: debit consumer wallet, credit admin wallet
        const admin = await User.findOne({ role: 'admin' });
        if (admin) await adjustUserWallet(admin._id, 50, 'credit', { kind: 'admin_fee', stage: 'consumer_checkout', order: o._id });
        await adjustUserWallet(o.consumerId, 50, 'debit', { kind: 'service_charge', stage: 'consumer_checkout', order: o._id });
      }

      // Subscription activation
      if (type === 'subscription' && subscriptionId) {
        const s = await Subscription.findById(subscriptionId)
        if (s) {
          const now = new Date()
          const end = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000)
          s.status = 'active'
          s.paymentRef = reference
          s.periodStart = now
          s.periodEnd = end
          await s.save()
        }
      }
    }
    res.sendStatus(200);
  } catch (e) {
    console.error("Webhook error:", e.message);
    res.sendStatus(500);
  }
});

export default router;
