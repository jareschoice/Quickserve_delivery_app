// backend/utils/set-temp-passwords.js
import dotenv from "dotenv";
dotenv.config();
import bcrypt from "bcrypt";
import { connectToMongoDB } from "../src/config/db.js";
import Vendor from "../src/models/Vendor.js";

const SALT_ROUNDS = 10;

// USAGE: node set-temp-passwords.js <vendorEmailOrId1> <vendorEmailOrId2> ...
// Example: node set-temp-passwords.js vendor1@example.com 690ddfa...
const args = process.argv.slice(2);
if (!args.length) {
  console.error("Usage: node set-temp-passwords.js <vendorEmailOrId ...>");
  process.exit(1);
}

(async () => {
  try {
    await connectToMongoDB();
    for (const identifier of args) {
      // find by id or email
      let vendor = null;
      if (/^[0-9a-fA-F]{24}$/.test(identifier)) {
        vendor = await Vendor.findById(identifier);
      } else {
        vendor = await Vendor.findOne({ email: identifier });
      }
      if (!vendor) {
        console.warn(`⚠ Vendor not found: ${identifier}`);
        continue;
      }

      // generate a temporary password
      const tempPassword = `QuickServe${Math.floor(1000 + Math.random() * 9000)}`; // e.g. QuickServe4832
      const hash = await bcrypt.hash(tempPassword, SALT_ROUNDS);

      // update vendor password (adjust field name to your model's password field)
      vendor.password = hash; // ensure this matches your model's password field (e.g., vendor.password)
      await vendor.save();

      console.log(`✅ Updated vendor: ${vendor.email || vendor._id}`);
      console.log(`   businessName: ${vendor.businessName || vendor.storeName || ""}`);
      console.log(`   tempPassword: ${tempPassword}`);
      console.log("---------------------------------------------------");
    }
    process.exit(0);
  } catch (err) {
    console.error("❌ Fatal:", err);
    process.exit(1);
  }
})();