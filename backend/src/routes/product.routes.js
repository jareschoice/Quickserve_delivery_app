import express from "express";
import Product from "../models/Product.js";
import Vendor from "../models/Vendor.js";
import { authRequired } from "../middleware/auth.js";

const router = express.Router();

// Vendor add product
router.post("/", authRequired("vendor"), async (req, res) => {
  try {
    const v = await Vendor.findOne({ user: req.user.id });
    if (!v) return res.status(400).json({ error: "Vendor profile not found" });
    const { name, description, price, imageUrl, category, quantity, prepDurationMins } = req.body;
    const p = await Product.create({
      vendorId: v._id,
      name,
      description,
      price,
      imageUrl,
      category,
      quantity: quantity || 0,
      prepDurationMins: prepDurationMins ? Number(prepDurationMins) : undefined,
    });
    res.json({ product: p });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Vendor update product
router.put("/:id", authRequired("vendor"), async (req, res) => {
  try {
    const v = await Vendor.findOne({ user: req.user.id });
    const p = await Product.findOne({ _id: req.params.id, vendorId: v._id });
    if (!p) return res.status(404).json({ error: "Not found" });
    Object.assign(p, req.body);
    await p.save();
    res.json({ product: p });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Vendor delete product
router.delete("/:id", authRequired("vendor"), async (req, res) => {
  try {
    const v = await Vendor.findOne({ user: req.user.id });
    await Product.deleteOne({ _id: req.params.id, vendorId: v._id });
    res.json({ ok: true });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Public list products (with optional vendor filter)
router.get("/", async (req, res) => {
  const { vendorId } = req.query;
  const q = vendorId ? { vendorId } : {};
  const items = await Product.find(q).sort({ createdAt: -1 });
  res.json({ items });
});

// Authenticated vendor's products
router.get("/mine", authRequired("vendor"), async (req, res) => {
  try {
    const v = await Vendor.findOne({ user: req.user.id });
    if (!v) return res.status(400).json({ error: "Vendor profile not found" });
    const items = await Product.find({ vendorId: v._id }).sort({ createdAt: -1 });
    res.json({ items });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

export default router;
