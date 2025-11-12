// ======================================
// 🌍 MongoDB Connection Setup (QuickServe)
// ======================================
import mongoose from "mongoose";
import dotenv from "dotenv";
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
// Load .env from backend root regardless of current working directory
dotenv.config({ path: join(__dirname, '../../.env') });

const uri = process.env.MONGO_URI;

if (!uri) {
    console.error("❌ Missing MONGO_URI in environment variables");
    process.exit(1);
}

export async function connectToMongoDB() {
    let attempts = 0;

    while (attempts < 5) {
        try {
            console.log("🧭 Connecting to MongoDB Atlas...");
            await mongoose.connect(uri);
            console.log("✅ MongoDB Atlas connected successfully!");
            global.dbConnected = true;
            return;
        } catch (err) {
            attempts++;
            global.dbConnected = false;
            console.error(`❌ Connection attempt ${attempts} failed:`, err.message);
            console.log("🔁 Retrying in 5 seconds...");
            await new Promise((r) => setTimeout(r, 5000));
        }
    }

    console.error("🚫 Could not connect to MongoDB after multiple attempts.");
    process.exit(1);
}
