// backend/utils/dump-vendors.js
import dotenv from "dotenv";
dotenv.config();
import { connectToMongoDB } from "../src/config/db.js";
import Vendor from "../src/models/Vendor.js";

(async () => {
  try {
    await connectToMongoDB();
    const list = await Vendor.find({}, "businessName email phone createdAt status").lean();
    console.log("✅ Registered vendors (safe fields):");
    console.table(list.map(v => ({
      id: String(v._id),
      businessName: v.businessName || v.storeName || v.name || "",
      email: v.email || "",
      phone: v.phone || "",
      status: v.status || "",
      createdAt: v.createdAt ? v.createdAt.toISOString() : ""
    })));
    process.exit(0);
  } catch (err) {
    console.error("❌ Error:", err.message);
    process.exit(1);
  }
})();