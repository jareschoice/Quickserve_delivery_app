// Seed Showcase Vendors and Section-Tagged Products
// Run: node seed-showcase-vendors.js

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';

dotenv.config();

// Connect
await mongoose.connect(process.env.MONGO_URI);
console.log('✅ Connected to MongoDB');

// Minimal schemas (avoid importing app modules to keep script standalone)
const UserSchema = new mongoose.Schema({
  name: String,
  email: { type: String, unique: true },
  password: String,
  role: { type: String, enum: ['customer','vendor','rider','admin'], default: 'customer' },
  isVerified: { type: Boolean, default: true },
});
const VendorSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  storeName: String,
  businessName: String,
  businessAddress: String,
  businessPhone: String,
  category: String,
  isActive: { type: Boolean, default: true },
  availabilityStatus: { type: String, default: 'online' },
  tags: [String],
}, { timestamps: true });
const ProductSchema = new mongoose.Schema({
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor', required: true },
  name: String,
  description: String,
  price: Number,
  category: String,
  quantity: Number,
  imageUrl: String,
  image: String,
  available: { type: Boolean, default: true },
  tags: [String],
}, { timestamps: true });

const User = mongoose.model('User', UserSchema);
const Vendor = mongoose.model('Vendor', VendorSchema);
const Product = mongoose.model('Product', ProductSchema);

const GROUPS = [
  { label: 'Explore', count: 5 },
  { label: 'Featured', count: 5 },
  { label: 'FoodCourt', count: 5 },
];

const BASE_PRODUCTS = [
  { name: 'Jollof Combo', description: 'Jollof rice with chicken', price: 1800, category: 'Meals' },
  { name: 'Burger & Fries', description: 'Beef burger with fries', price: 2200, category: 'FastFood' },
  { name: 'Chicken Shawarma', description: 'Grilled chicken wrap', price: 1500, category: 'FastFood' },
  { name: 'Smoothie', description: 'Mixed fruit smoothie', price: 1000, category: 'Drinks' },
];

const shouldReplace = process.argv.includes('--replace');

if (shouldReplace) {
  console.log('⚠️  --replace specified: Deactivating all existing vendors (isActive=false).');
  await Vendor.updateMany({}, { $set: { isActive: false } });
}

async function ensureVendor(name, groupLabel, idx) {
  const email = `showcase.${groupLabel.toLowerCase()}${idx}@quickserve.local`;
  let user = await User.findOne({ email });
  if (!user) {
    user = await User.create({
      name,
      email,
      password: await bcrypt.hash('vendor123', 10),
      role: 'vendor',
      isVerified: true
    });
    console.log('👤 Created user:', email);
  }
  let v = await Vendor.findOne({ user: user._id });
  if (!v) {
    v = await Vendor.create({
      user: user._id,
      storeName: name,
      businessName: name,
      businessAddress: 'Event Arena, Main Stand',
      businessPhone: `080${Math.floor(10000000 + Math.random()*89999999)}`,
      category: groupLabel === 'FoodCourt' ? 'Restaurant' : (groupLabel === 'Featured' ? 'FastFood' : 'Other'),
      isActive: true,
      tags: [groupLabel]
    });
    console.log('🏪 Created vendor:', name);
  } else {
    // Reactivate and tag
    v.isActive = true;
    v.tags = Array.from(new Set([...(v.tags||[]), groupLabel]));
    await v.save();
  }
  return v;
}

async function ensureTaggedProducts(vendor, groupLabel) {
  const count = await Product.countDocuments({ vendorId: vendor._id });
  if (count >= 2) {
    // Make sure at least some items have the tag
    await Product.updateMany({ vendorId: vendor._id, tags: { $ne: groupLabel } }, { $addToSet: { tags: groupLabel } });
    return;
  }
  const payloads = BASE_PRODUCTS.slice(0, 2).map(p => ({
    ...p,
    vendorId: vendor._id,
    quantity: 50,
    available: true,
    tags: [groupLabel],
  }));
  await Product.insertMany(payloads);
  console.log(`🍱 Seeded ${payloads.length} products for ${vendor.businessName} [${groupLabel}]`);
}

for (const g of GROUPS) {
  console.log(`\n➡️ Ensuring ${g.count} vendors for ${g.label}...`);
  for (let i=1; i<=g.count; i++) {
    const name = `Showcase ${g.label} ${i}`;
    const v = await ensureVendor(name, g.label, i);
    await ensureTaggedProducts(v, g.label);
  }
}

console.log('\n🎉 Showcase seeding complete.');
await mongoose.connection.close();
console.log('🔌 Disconnected.');
