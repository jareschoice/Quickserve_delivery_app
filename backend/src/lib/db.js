import mongoose from "mongoose";

export const connectDB = async () => {
  const uri = process.env.MONGO_URI;
  if (!uri) throw new Error("MONGO_URI missing in .env");
  mongoose.set("strictQuery", true);
  await mongoose.connect(uri, { dbName: "quickserve" });
  console.log("✅ MongoDB connected");
};
