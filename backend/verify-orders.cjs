const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  vendorId: mongoose.Schema.Types.ObjectId,
  items: Array,
  subtotal: Number,
  total: Number,
  status: String,
  isMultiVendor: Boolean,
  orderGroupId: String
}, { timestamps: true });

const Order = mongoose.model('Order', orderSchema);

async function verifyOrders() {
  try {
    const uri = process.env.MONGO_URI;
    await mongoose.connect(uri);
    console.log('✅ Connected to MongoDB\n');

    // Find all orders with the latest orderGroupId
    const orders = await Order.find({ orderGroupId: /^OG-/ }).sort({ createdAt: -1 }).limit(3);

    console.log(`Found ${orders.length} orders:\n`);
    orders.forEach((order, i) => {
      console.log(`Order ${i + 1}:`);
      console.log(`  vendorId: ${order.vendorId}`);
      console.log(`  orderGroupId: ${order.orderGroupId}`);
      console.log(`  status: ${order.status}`);
      console.log(`  items: ${order.items.map(i => i.name).join(', ')}`);
      console.log(`  total: ₦${order.total}`);
      console.log(`  isMultiVendor: ${order.isMultiVendor}`);
      console.log('');
    });

    // Check which vendors match
    console.log('\nExpected vendor User IDs:');
    console.log('  Mama\'s Kitchen: 690b3a37405714d550af81af');
    console.log('  Campus Bites: 690b3a38405714d550af81b9');
    console.log('  Quick Snacks Hub: 690b3a3a405714d550af81c3');

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    await mongoose.connection.close();
    process.exit(1);
  }
}

verifyOrders();
