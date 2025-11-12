const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  vendorId: mongoose.Schema.Types.ObjectId,
  items: Array,
  status: String,
  isMultiVendor: Boolean,
  orderGroupId: String
}, { timestamps: true });

const Order = mongoose.model('Order', orderSchema);

async function testQuery() {
  try {
    const uri = process.env.MONGO_URI;
    await mongoose.connect(uri);
    console.log('✅ Connected to MongoDB\n');

    // These are the User IDs from the JWT tokens in the logs
    const mamasUserId = '690b3a37405714d550af81af';
    const campusUserId = '690b3a38405714d550af81b9';
    const quickUserId = '690b3a3a405714d550af81c3';

    console.log('Testing queries for each vendor:\n');

    // Test Mama's Kitchen
    const mamasOrders = await Order.find({ vendorId: mamasUserId });
    console.log(`Mama's Kitchen (User ID: ${mamasUserId}):`);
    console.log(`  Found ${mamasOrders.length} orders`);
    if (mamasOrders.length > 0) {
      console.log(`  Order IDs: ${mamasOrders.map(o => o._id).join(', ')}`);
    }
    console.log('');

    // Test Campus Bites
    const campusOrders = await Order.find({ vendorId: campusUserId });
    console.log(`Campus Bites (User ID: ${campusUserId}):`);
    console.log(`  Found ${campusOrders.length} orders`);
    if (campusOrders.length > 0) {
      console.log(`  Order IDs: ${campusOrders.map(o => o._id).join(', ')}`);
    }
    console.log('');

    // Test Quick Snacks Hub
    const quickOrders = await Order.find({ vendorId: quickUserId });
    console.log(`Quick Snacks Hub (User ID: ${quickUserId}):`);
    console.log(`  Found ${quickOrders.length} orders`);
    if (quickOrders.length > 0) {
      console.log(`  Order IDs: ${quickOrders.map(o => o._id).join(', ')}`);
    }

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    await mongoose.connection.close();
    process.exit(1);
  }
}

testQuery();
