require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// Define schemas inline
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['customer', 'vendor', 'dispatcher', 'admin'], default: 'customer' },
  isVerified: { type: Boolean, default: false }
});

const vendorSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  businessName: { type: String, required: true },
  businessAddress: { type: String },
  phoneNumber: { type: String },
  isActive: { type: Boolean, default: true },
  availabilityStatus: { type: String, enum: ['online', 'offline', 'busy'], default: 'online' },
  rating: { type: Number, default: 0 },
  totalOrders: { type: Number, default: 0 }
});

const productSchema = new mongoose.Schema({
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor', required: true },
  name: { type: String, required: true },
  description: { type: String },
  price: { type: Number, required: true },
  category: { type: String },
  imageUrl: { type: String },
  isAvailable: { type: Boolean, default: true }
});

const User = mongoose.model('User', userSchema);
const Vendor = mongoose.model('Vendor', vendorSchema);
const Product = mongoose.model('Product', productSchema);

const testVendors = [
  {
    email: 'mamas.kitchen@quickserve.test',
    password: 'password123',
    businessName: "Mama's Kitchen",
    businessAddress: "Block A, Student Housing, University Campus",
    phoneNumber: "+234 801 234 5678",
    products: [
      { name: 'Jollof Rice with Chicken', description: 'Delicious Nigerian jollof rice with grilled chicken', price: 2500, category: 'Main Dishes' },
      { name: 'Fried Rice Special', description: 'Fried rice with mixed vegetables and beef', price: 2000, category: 'Main Dishes' },
      { name: 'Pounded Yam with Egusi Soup', description: 'Traditional pounded yam with rich egusi soup', price: 3000, category: 'Main Dishes' }
    ]
  },
  {
    email: 'campus.bites@quickserve.test',
    password: 'password123',
    businessName: 'Campus Bites',
    businessAddress: "Near Main Gate, University Campus",
    phoneNumber: "+234 802 345 6789",
    products: [
      { name: 'Shawarma Wrap', description: 'Chicken shawarma with special sauce', price: 1500, category: 'Fast Food' },
      { name: 'Pepsi (50cl)', description: 'Cold soft drink', price: 300, category: 'Beverages' },
      { name: 'Burger & Fries Combo', description: 'Beef burger with crispy fries', price: 2000, category: 'Fast Food' }
    ]
  },
  {
    email: 'quick.snacks@quickserve.test',
    password: 'password123',
    businessName: 'Quick Snacks Hub',
    businessAddress: "Faculty of Science Building, University Campus",
    phoneNumber: "+234 803 456 7890",
    products: [
      { name: 'Meat Pie', description: 'Freshly baked meat pie', price: 400, category: 'Snacks' },
      { name: 'Bottled Water', description: 'Pure table water (75cl)', price: 100, category: 'Beverages' },
      { name: 'Chin Chin (Pack)', description: 'Crunchy Nigerian snack', price: 500, category: 'Snacks' }
    ]
  }
];

async function resetVendors() {
  try {
    console.log('🧭 Connecting to MongoDB Atlas...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    console.log('🗑️ Deleting existing test vendors...');
    
    for (const testVendor of testVendors) {
      const existingUser = await User.findOne({ email: testVendor.email });
      if (existingUser) {
        const existingVendor = await Vendor.findOne({ user: existingUser._id });
        if (existingVendor) {
          await Product.deleteMany({ vendorId: existingVendor._id });
          await Vendor.deleteOne({ _id: existingVendor._id });
        }
        await User.deleteOne({ _id: existingUser._id });
        console.log(`   Deleted: ${testVendor.email}`);
      }
    }

    console.log('\n🔨 Creating fresh test vendors...\n');

    for (const testVendor of testVendors) {
      // Create user
      const hashedPassword = await bcrypt.hash(testVendor.password, 10);
      const user = await User.create({
        email: testVendor.email,
        password: hashedPassword,
        role: 'vendor',
        isVerified: true
      });

      // Create vendor profile
      const vendor = await Vendor.create({
        user: user._id,
        businessName: testVendor.businessName,
        businessAddress: testVendor.businessAddress,
        phoneNumber: testVendor.phoneNumber,
        isActive: true,
        availabilityStatus: 'online'
      });

      // Create products
      for (const productData of testVendor.products) {
        await Product.create({
          vendorId: vendor._id,
          name: productData.name,
          description: productData.description,
          price: productData.price,
          category: productData.category,
          imageUrl: '/images/placeholder.jpg',
          isAvailable: true
        });
      }

      console.log(`✅ Created: ${testVendor.businessName}`);
      console.log(`   Email: ${testVendor.email}`);
      console.log(`   Password: ${testVendor.password}`);
      console.log(`   Products: ${testVendor.products.length} items`);
      console.log('');
    }

    console.log('🎉 All test vendors reset successfully!\n');
    console.log('📝 Login credentials for testing:');
    console.log('─────────────────────────────────────');
    testVendors.forEach(v => {
      console.log(`${v.businessName}: ${v.email} / ${v.password}`);
    });

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    await mongoose.connection.close();
    process.exit(1);
  }
}

resetVendors();
