// ===============================
// FILE: backend/src/controllers/riderController.js
// ===============================

import Order from "../models/Order.js";
import User from "../models/User.js";
import Transaction from "../models/Transaction.js";
import { adjustUserWallet } from "../utils/wallet.js";
import { sendNotification } from "../utils/notify.js";
import { calculateDeliveryFee } from "../utils/fare.js";

/**
 * Rider accepts assigned order
 */
export const acceptDelivery = async (req, res) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findById(orderId);
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (order.riderId && String(order.riderId) !== String(req.user._id))
      return res.status(403).json({ error: "Unauthorized" });

    order.status = "in_transit";
    order.pickedAt = new Date();
    await order.save();

    await sendNotification({
      userId: order.consumerId,
      title: "Order On The Way 🚴‍♂️",
      message: "Your order has been picked up and is on the way.",
      type: "order",
      app: req.app,
    });

    res.json({ success: true, message: "Delivery accepted", order });
  } catch (err) {
    console.error("acceptDelivery error:", err);
    res.status(500).json({ error: "Failed to accept delivery" });
  }
};

/**
 * Rider updates delivery status
 */
export const updateDeliveryStatus = async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;
    const validStatuses = ["arrived_customer", "delivered"];
    if (!validStatuses.includes(status))
      return res.status(400).json({ error: "Invalid status" });

    const order = await Order.findById(orderId);
    if (!order) return res.status(404).json({ error: "Order not found" });
    if (String(order.riderId) !== String(req.user._id))
      return res.status(403).json({ error: "Unauthorized" });

    order.status = status;
    if (status === "arrived_customer") order.arrivedAt = new Date();
    if (status === "delivered") {
      order.deliveredAt = new Date();

      // ✅ Rider gets delivery fee payout
      const riderPay = order.deliveryFee * 0.9; // 90% to rider, 10% platform fee
      await adjustUserWallet(req.user._id, riderPay, "credit", {
        reason: "delivery_completed",
        order: order._id,
      });

      await Transaction.create({
        user: req.user._id,
        amount: riderPay,
        type: "credit",
        meta: {
          reason: "rider_earning",
          order: order._id,
          deliveryFee: order.deliveryFee,
        },
      });

      // Notify all parties
      await sendNotification({
        userId: order.consumerId,
        title: "Order Delivered ✔️",
        message: "Your delivery has been completed successfully.",
        type: "order",
        app: req.app,
      });

      await sendNotification({
        userId: order.vendorId,
        title: "Delivery Completed ✅",
        message: "Your customer's order has been successfully delivered.",
        type: "order",
        app: req.app,
      });
    }

    await order.save();
    res.json({ success: true, order });
  } catch (err) {
    console.error("updateDeliveryStatus error:", err);
    res.status(500).json({ error: "Failed to update status" });
  }
};

/**
 * Rider gets nearby delivery requests (mock for now)
 */
export const getAvailableDeliveries = async (req, res) => {
  try {
    const orders = await Order.find({
      status: "waiting_pickup",
      riderId: { $exists: false },
    })
      .sort({ createdAt: -1 })
      .limit(10)
      .populate("vendorId", "name profile.businessAddress");

    res.json({ success: true, orders });
  } catch (err) {
    console.error("getAvailableDeliveries error:", err);
    res.status(500).json({ error: "Failed to fetch available deliveries" });
  }
};
