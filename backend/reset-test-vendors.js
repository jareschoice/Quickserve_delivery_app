// Reset and create test vendors for multi-vendor testing
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

// Connect to MongoDB
await mongoose.connect(process.env.MONGO_URI);
console.log('✅ Connected to MongoDB\n');

// Define schemas
const UserSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  role: String,
  isVerified: Boolean,
  profile: Object,
}, { timestamps: true });

const VendorSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  businessName: String,
  businessAddress: String,
  businessPhone: String,
  isActive: Boolean,
}, { timestamps: true });

const ProductSchema = new mongoose.Schema({
  name: String,
  description: String,
  price: Number,
  category: String,
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor' },
  isAvailable: Boolean,
}, { timestamps: true });

const User = mongoose.model('User', UserSchema);
const Vendor = mongoose.model('Vendor', VendorSchema);
const Product = mongoose.model('Product', ProductSchema);

// Test vendors to create
const testVendors = [
  {
    email: 'mamas.kitchen@quickserve.test',
    name: "Mama's Kitchen",
    businessName: "Mama's Kitchen",
    businessAddress: 'Stall A12, AutofestXTradeExpo',
    businessPhone: '08012345671',
    products: [
      { name: 'Jollof Rice & Chicken', price: 2500, category: 'Main Course' },
      { name: 'Fried Rice', price: 2000, category: 'Main Course' },
      { name: 'Pounded Yam & Egusi', price: 3000, category: 'Main Course' }
    ]
  },
  {
    email: 'campus.bites@quickserve.test',
    name: 'Campus Bites',
    businessName: 'Campus Bites',
    businessAddress: 'Stall B05, AutofestXTradeExpo',
    businessPhone: '08012345672',
    products: [
      { name: 'Shawarma', price: 1500, category: 'Fast Food' },
      { name: 'Pepsi 50cl', price: 300, category: 'Drinks' },
      { name: 'Burger & Fries', price: 2000, category: 'Fast Food' }
    ]
  },
  {
    email: 'quick.snacks@quickserve.test',
    name: 'Quick Snacks Hub',
    businessName: 'Quick Snacks Hub',
    businessAddress: 'Stall C15, AutofestXTradeExpo',
    businessPhone: '08012345673',
    products: [
      { name: 'Meat Pie', price: 400, category: 'Snacks' },
      { name: 'Bottled Water', price: 100, category: 'Drinks' },
      { name: 'Chin Chin Pack', price: 500, category: 'Snacks' }
    ]
  }
];

console.log('🗑️  Deleting existing test vendors...');

// Delete existing test vendors and their products
for (const testVendor of testVendors) {
  const existingUser = await User.findOne({ email: testVendor.email });
  if (existingUser) {
    const existingVendor = await Vendor.findOne({ user: existingUser._id });
    if (existingVendor) {
      await Product.deleteMany({ vendorId: existingVendor._id });
      await Vendor.deleteOne({ _id: existingVendor._id });
    }
    await User.deleteOne({ _id: existingUser._id });
    console.log(`   ❌ Deleted: ${testVendor.email}`);
  }
}

console.log('\n🆕 Creating fresh test vendors...\n');

// Create fresh vendors
const password = 'password123';
const hashedPassword = await bcrypt.hash(password, 10);

for (const testVendor of testVendors) {
  // Create User
  const user = await User.create({
    name: testVendor.name,
    email: testVendor.email,
    password: hashedPassword,
    role: 'vendor',
    isVerified: true,
    profile: {
      phone: testVendor.businessPhone,
      businessName: testVendor.businessName,
      businessAddress: testVendor.businessAddress,
    }
  });

  // Create Vendor
  const vendor = await Vendor.create({
    user: user._id,
    businessName: testVendor.businessName,
    businessAddress: testVendor.businessAddress,
    businessPhone: testVendor.businessPhone,
    isActive: true
  });

  // Create Products
  for (const prod of testVendor.products) {
    await Product.create({
      name: prod.name,
      description: `Delicious ${prod.name} from ${testVendor.businessName}`,
      price: prod.price,
      category: prod.category,
      vendorId: vendor._id,
      isAvailable: true
    });
  }

  console.log(`✅ Created: ${testVendor.businessName}`);
  console.log(`   Email: ${testVendor.email}`);
  console.log(`   Password: ${password}`);
  console.log(`   Products: ${testVendor.products.length} items`);
  console.log('');
}

console.log('=' .repeat(60));
console.log('✅ VENDOR RESET COMPLETE!\n');
console.log('📋 LOGIN CREDENTIALS:');
console.log('=' .repeat(60));
console.log('\n🏪 VENDOR #1: Mama\'s Kitchen');
console.log('   Email: mamas.kitchen@quickserve.test');
console.log('   Password: password123');
console.log('   URL: http://localhost:5555/event-frontend/vendor-dashboard.html\n');

console.log('🏪 VENDOR #2: Campus Bites');
console.log('   Email: campus.bites@quickserve.test');
console.log('   Password: password123');
console.log('   URL: http://localhost:5555/event-frontend/vendor-dashboard.html\n');

console.log('🏪 VENDOR #3: Quick Snacks Hub');
console.log('   Email: quick.snacks@quickserve.test');
console.log('   Password: password123');
console.log('   URL: http://localhost:5555/event-frontend/vendor-dashboard.html\n');

console.log('=' .repeat(60));
console.log('🚀 Ready to test! Login with these credentials.');
console.log('=' .repeat(60));

await mongoose.disconnect();
process.exit(0);
