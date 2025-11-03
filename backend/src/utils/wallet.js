// ===============================
// FILE: backend/src/utils/wallet.js
// ===============================
import User from "../models/User.js";
import Vendor from "../models/Vendor.js";
import Transaction from "../models/Transaction.js";
import { sendNotification } from "./notify.js";

/**
 * ✅ Helper to emit wallet update events in real-time
 */
const emitWalletUpdate = (app, userId, payload = {}) => {
  try {
    const io = app?.get("io");
    if (io) {
      io.to(`user:${userId}`).emit("wallet:update", {
        userId,
        time: new Date().toISOString(),
        ...payload,
      });
    }
  } catch (e) {
    console.warn("⚠️ Wallet emit failed:", e.message);
  }
};

/**
 * ✅ Adjust wallet for a user (customer, rider, or admin)
 */
export const adjustUserWallet = async (
  userId,
  amount,
  type = "credit",
  meta = {},
  app = null
) => {
  const user = await User.findById(userId);
  if (!user) throw new Error("User not found");

  const amt = Number(amount) || 0;
  if (amt <= 0) throw new Error("Invalid amount");

  if (type === "debit" && (user.wallet || 0) < amt)
    throw new Error("Insufficient wallet balance");

  user.wallet =
    type === "credit"
      ? (user.wallet || 0) + amt
      : Math.max(0, (user.wallet || 0) - amt);

  await user.save();

  const txn = await Transaction.create({
    user: user._id,
    amount: amt,
    type,
    balanceAfter: user.wallet,
    meta: {
      ...meta,
      actor: "user",
      reason: meta.reason || "wallet_adjustment",
      stage: meta.stage || "manual",
      via: meta.via || "system",
    },
    status: "success",
  });

  // 🔔 Optional in-app + email notification
  try {
    await sendNotification({
      userId,
      title:
        type === "credit"
          ? "Wallet Credited 💰"
          : "Wallet Debited 💸",
      message:
        type === "credit"
          ? `₦${amt} has been added to your wallet.`
          : `₦${amt} has been deducted from your wallet.`,
      type: "wallet",
      meta: txn,
      app,
    });
  } catch (e) {
    console.warn("⚠️ Wallet notify failed:", e.message);
  }

  // 📡 Real-time socket update
  emitWalletUpdate(app, userId, {
    newBalance: user.wallet,
    amountChange: type === "credit" ? amt : -amt,
    meta,
  });

  return user.wallet;
};

/**
 * ✅ Adjust wallet for vendor (linked to Vendor entity)
 */
export const adjustVendorWallet = async (
  userId,
  amount,
  type = "credit",
  meta = {},
  app = null
) => {
  const vendor = await Vendor.findOne({ user: userId });
  if (!vendor) throw new Error("Vendor profile not found");

  const amt = Number(amount) || 0;
  if (amt <= 0) throw new Error("Invalid amount");

  if (type === "debit" && (vendor.wallet || 0) < amt)
    throw new Error("Insufficient vendor wallet balance");

  vendor.wallet =
    type === "credit"
      ? (vendor.wallet || 0) + amt
      : Math.max(0, (vendor.wallet || 0) - amt);

  await vendor.save();

  const txn = await Transaction.create({
    user: userId,
    amount: amt,
    type,
    balanceAfter: vendor.wallet,
    meta: {
      ...meta,
      actor: "vendor",
      reason: meta.reason || "vendor_wallet_adjustment",
      stage: meta.stage || "manual",
      via: meta.via || "system",
    },
    status: "success",
  });

  // 🔔 Vendor notification
  try {
    await sendNotification({
      userId,
      title:
        type === "credit"
          ? "Vendor Wallet Credited ✅"
          : "Vendor Wallet Debited ⚠️",
      message:
        type === "credit"
          ? `₦${amt} has been added to your business wallet.`
          : `₦${amt} has been deducted from your business wallet.`,
      type: "wallet",
      meta: txn,
      app,
    });
  } catch (e) {
    console.warn("⚠️ Vendor notify failed:", e.message);
  }

  // 📡 Emit real-time update
  emitWalletUpdate(app, userId, {
    newBalance: vendor.wallet,
    amountChange: type === "credit" ? amt : -amt,
    meta,
  });

  return vendor.wallet;
};

/**
 * ✅ Adjust wallet for rider (future extension)
 */
export const adjustRiderWallet = async (
  riderId,
  amount,
  type = "credit",
  meta = {},
  app = null
) => {
  const rider = await User.findById(riderId);
  if (!rider || rider.role !== "rider")
    throw new Error("Rider not found");

  const amt = Number(amount) || 0;
  if (amt <= 0) throw new Error("Invalid amount");

  if (type === "debit" && (rider.wallet || 0) < amt)
    throw new Error("Insufficient rider wallet balance");

  rider.wallet =
    type === "credit"
      ? (rider.wallet || 0) + amt
      : Math.max(0, (rider.wallet || 0) - amt);

  await rider.save();

  const txn = await Transaction.create({
    user: riderId,
    amount: amt,
    type,
    balanceAfter: rider.wallet,
    meta: {
      ...meta,
      actor: "rider",
      reason: meta.reason || "rider_wallet_adjustment",
      stage: meta.stage || "manual",
      via: meta.via || "system",
    },
    status: "success",
  });

  try {
    await sendNotification({
      userId: riderId,
      title:
        type === "credit"
          ? "Rider Wallet Credited 🚴"
          : "Rider Wallet Debited ⚠️",
      message:
        type === "credit"
          ? `₦${amt} has been added to your rider wallet.`
          : `₦${amt} has been deducted from your wallet.`,
      type: "wallet",
      meta: txn,
      app,
    });
  } catch (e) {
    console.warn("⚠️ Rider notify failed:", e.message);
  }

  emitWalletUpdate(app, riderId, {
    newBalance: rider.wallet,
    amountChange: type === "credit" ? amt : -amt,
    meta,
  });

  return rider.wallet;
};
