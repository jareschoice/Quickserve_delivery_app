// utils/list-vendors.js
import mongoose from "mongoose";
import dotenv from "dotenv";
import { connectToMongoDB } from "../src/config/db.js";
import Vendor from "../src/models/Vendor.js";

dotenv.config();

(async () => {
  try {
    await connectToMongoDB();
    const vendors = await Vendor.find({}, "businessName email phone createdAt status").lean();
    console.log("✅ Registered Vendors:");
    console.table(vendors);
    process.exit(0);
  } catch (err) {
    console.error("❌ Error fetching vendors:", err.message);
    process.exit(1);
  }
})();