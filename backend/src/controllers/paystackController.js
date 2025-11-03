// =============================== 
// FILE: backend/src/controllers/paystackController.js
// ===============================
import axios from "axios";
import crypto from "crypto";
import Transaction from "../models/Transaction.js";
import User from "../models/User.js";
import { adjustUserWallet } from "../utils/wallet.js";

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY;

// =====================================
// ✳️ INITIATE WALLET FUNDING
// =====================================
export const initiateWalletFunding = async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) return res.status(400).json({ error: "Invalid amount" });

    const user = req.user;
    const koboAmount = Number(amount) * 100;

    // Create Paystack payment request
    const response = await axios.post(
      "https://api.paystack.co/transaction/initialize",
      {
        email: user.email,
        amount: koboAmount,
        callback_url: `${process.env.APP_BASE_URL}/api/paystack/verify`,
        metadata: {
          userId: user._id.toString(),
          reason: "wallet_funding",
        },
      },
      {
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET}`,
          "Content-Type": "application/json",
        },
      }
    );

    const data = response.data;
    if (!data.status) return res.status(400).json({ error: "Failed to initiate payment" });

    // Create a pending transaction record
    await Transaction.create({
      user: user._id,
      amount,
      type: "credit",
      status: "pending",
      meta: { reason: "wallet_funding", via: "paystack" },
    });

    res.json({
      success: true,
      message: "Paystack payment session created",
      authorization_url: data.data.authorization_url,
      reference: data.data.reference,
    });
  } catch (e) {
    console.error("initiateWalletFunding error", e.response?.data || e.message);
    res.status(500).json({ error: "Payment initiation failed" });
  }
};

// =====================================
// ✳️ VERIFY TRANSACTION MANUALLY (optional endpoint)
// =====================================
export const verifyPayment = async (req, res) => {
  try {
    const { reference } = req.query;
    if (!reference) return res.status(400).json({ error: "Reference required" });

    const response = await axios.get(`https://api.paystack.co/transaction/verify/${reference}`, {
      headers: { Authorization: `Bearer ${PAYSTACK_SECRET}` },
    });

    const data = response.data;
    if (data.data.status !== "success") return res.status(400).json({ error: "Payment not successful" });

    const userId = data.data.metadata.userId;
    const amount = data.data.amount / 100;

    await adjustUserWallet(userId, amount, "credit", {
      reason: "wallet_funding",
      via: "paystack",
      stage: "manual_verify",
    });

    await Transaction.findOneAndUpdate(
      { reference },
      { status: "success" },
      { new: true }
    );

    res.json({ success: true, message: "Wallet credited successfully" });
  } catch (e) {
    console.error("verifyPayment error", e.response?.data || e.message);
    res.status(500).json({ error: "Verification failed" });
  }
};

// =====================================
// ✳️ PAYSTACK WEBHOOK HANDLER (Auto-credit)
// =====================================
export const handlePaystackWebhook = async (req, res) => {
  try {
    const signature = req.headers["x-paystack-signature"];
    const hash = crypto
      .createHmac("sha512", PAYSTACK_SECRET)
      .update(JSON.stringify(req.body))
      .digest("hex");

    if (hash !== signature) {
      console.warn("⚠️ Invalid Paystack signature");
      return res.status(400).json({ error: "Invalid signature" });
    }

    const event = req.body.event;
    const data = req.body.data;

    if (event === "charge.success") {
      const userId = data.metadata.userId;
      const amount = data.amount / 100;

      // Credit wallet if not already done
      await adjustUserWallet(userId, amount, "credit", {
        reason: "wallet_funding",
        via: "paystack_webhook",
        reference: data.reference,
      });

      await Transaction.findOneAndUpdate(
        { reference: data.reference },
        { status: "success" },
        { new: true }
      );

      console.log(`✅ Wallet funded for user ${userId}: ₦${amount}`);
    }

    res.sendStatus(200);
  } catch (e) {
    console.error("handlePaystackWebhook error", e.message);
    res.status(500).json({ error: "Webhook processing failed" });
  }
};    