const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');

// Define schemas inline
const orderSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor', required: true },
  items: [{ name: String, qty: Number, price: Number }],
  subtotal: Number,
  deliveryFee: Number,
  total: Number,
  deliveryAddress: String,
  phoneNumber: String,
  status: { type: String, default: 'placed' },
  payment: {
    paid: Boolean,
    method: String,
    reference: String
  },
  isMultiVendor: { type: Boolean, default: false },
  orderGroupId: String,
  pickupPosition: Number
}, { timestamps: true });

const userSchema = new mongoose.Schema({
  email: String,
  password: String,
  role: String,
  isVerified: { type: Boolean, default: false }
}, { timestamps: true });

const vendorSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  vendorId: String,
  businessName: String,
  storeName: String,
  businessAddress: String,
  phoneNumber: String,
  isActive: { type: Boolean, default: true },
  availabilityStatus: { type: String, enum: ['online', 'offline', 'busy'], default: 'online' }
}, { timestamps: true });

const Order = mongoose.model('Order', orderSchema);
const User = mongoose.model('User', userSchema);
const Vendor = mongoose.model('Vendor', vendorSchema);

async function createTestOrder() {
  try {
    console.log('🧭 Connecting to MongoDB...');
    const uri = process.env.MONGO_URI;
    if (!uri) {
      console.error('❌ Missing MONGO_URI');
      process.exit(1);
    }
    await mongoose.connect(uri);
    console.log('✅ Connected!\n');

    // Find our 3 test vendors
    const vendors = await Vendor.find({
      businessName: { $in: ["Mama's Kitchen", "Campus Bites", "Quick Snacks Hub"] }
    }).populate('user');

    if (vendors.length !== 3) {
      console.error('❌ Expected 3 vendors, found:', vendors.length);
      vendors.forEach(v => console.log(`  - ${v.businessName}`));
      process.exit(1);
    }

    console.log('✅ Found 3 test vendors:');
    vendors.forEach(v => {
      console.log(`  - ${v.businessName} (vendorId: ${v.vendorId})`);
      console.log(`    Vendor._id: ${v._id}`);
      console.log(`    User._id: ${v.user}`);
    });

    // Generate orderGroupId
    const orderGroupId = `OG-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    console.log(`\n🔗 Generated orderGroupId: ${orderGroupId}\n`);

    // Create 3 orders (one for each vendor)
    const orders = [];

    // Order 1: Mama's Kitchen - Jollof Rice
    orders.push({
      vendorId: vendors.find(v => v.businessName === "Mama's Kitchen").user._id,
      items: [
        { name: 'Jollof Rice with Chicken', qty: 1, price: 2500 }
      ],
      subtotal: 2500,
      deliveryFee: 70,
      total: 2570,
      deliveryAddress: 'University Hostel Block C, Room 204',
      phoneNumber: '+234 800 000 0001',
      status: 'placed',
      payment: {
        paid: true,
        method: 'demo',
        reference: `DEMO-${Date.now()}`
      },
      isMultiVendor: true,
      orderGroupId: orderGroupId,
      pickupPosition: null
    });

    // Order 2: Campus Bites - Shawarma
    orders.push({
      vendorId: vendors.find(v => v.businessName === "Campus Bites").user._id,
      items: [
        { name: 'Shawarma Wrap', qty: 1, price: 1500 }
      ],
      subtotal: 1500,
      deliveryFee: 70,
      total: 1570,
      deliveryAddress: 'University Hostel Block C, Room 204',
      phoneNumber: '+234 800 000 0001',
      status: 'placed',
      payment: {
        paid: true,
        method: 'demo',
        reference: `DEMO-${Date.now()}`
      },
      isMultiVendor: true,
      orderGroupId: orderGroupId,
      pickupPosition: null
    });

    // Order 3: Quick Snacks Hub - Meat Pie + Water
    orders.push({
      vendorId: vendors.find(v => v.businessName === "Quick Snacks Hub").user._id,
      items: [
        { name: 'Meat Pie', qty: 1, price: 400 },
        { name: 'Bottled Water', qty: 1, price: 100 }
      ],
      subtotal: 500,
      deliveryFee: 70,
      total: 570,
      deliveryAddress: 'University Hostel Block C, Room 204',
      phoneNumber: '+234 800 000 0001',
      status: 'placed',
      payment: {
        paid: true,
        method: 'demo',
        reference: `DEMO-${Date.now()}`
      },
      isMultiVendor: true,
      orderGroupId: orderGroupId,
      pickupPosition: null
    });

    // Create all orders
    for (const orderData of orders) {
      console.log('Creating order with vendorId:', orderData.vendorId);
      const order = await Order.create(orderData);
      const vendor = vendors.find(v => {
        console.log(`  Checking vendor ${v.businessName}: ${v.user._id.toString()} === ${orderData.vendorId.toString()}`);
        return v.user._id.toString() === orderData.vendorId.toString();
      });
      if (!vendor) {
        console.error('❌ Could not find vendor for order!');
        continue;
      }
      console.log(`✅ Created order for ${vendor.businessName}`);
      console.log(`   Order ID: ${order._id}`);
      console.log(`   Items: ${order.items.map(i => i.name).join(', ')}`);
      console.log(`   Total: ₦${order.total}`);
      console.log('');
    }

    console.log('🎉 All orders created successfully!');
    console.log(`\n📱 Refresh your vendor dashboards to see the orders!`);
    console.log(`🔗 Group Order ID: ${orderGroupId}`);
    console.log(`\nAll 3 vendors should see:`);
    console.log(`  - 🛒 Multi-vendor badge`);
    console.log(`  - Same orderGroupId: ${orderGroupId}`);
    console.log(`  - Group status: "0/3 vendors ready"`);

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    await mongoose.connection.close();
    process.exit(1);
  }
}

createTestOrder();
