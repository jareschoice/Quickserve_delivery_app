const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');

async function checkVendorStructure() {
  try {
    const uri = process.env.MONGO_URI;
    await mongoose.connect(uri);
    
    const Vendor = mongoose.model('Vendor', new mongoose.Schema({
      user: mongoose.Schema.Types.ObjectId,
      businessName: String
    }));
    
    const User = mongoose.model('User', new mongoose.Schema({
      email: String,
      role: String
    }));
    
    const Order = mongoose.model('Order', new mongoose.Schema({
      vendorId: mongoose.Schema.Types.ObjectId,
      orderGroupId: String,
      items: Array
    }));
    
    console.log('🔍 Checking vendor structure...\n');
    
    const vendor = await Vendor.findOne({ businessName: "Mama's Kitchen" }).populate('user');
    console.log('Vendor document:');
    console.log('  Vendor _id:', vendor._id);
    console.log('  Vendor.user (User _id):', vendor.user._id);
    console.log('  User email:', vendor.user.email);
    console.log('  User role:', vendor.user.role);
    
    console.log('\n🔍 Checking created orders...\n');
    const orders = await Order.find({ orderGroupId: /^OG-/ }).sort({ createdAt: -1 }).limit(3);
    orders.forEach((order, i) => {
      console.log(`Order ${i + 1}:`);
      console.log(`  vendorId in order: ${order.vendorId}`);
      console.log(`  Items: ${order.items.map(it => it.name).join(', ')}`);
    });
    
    console.log('\n✅ The issue: Orders have Vendor._id as vendorId');
    console.log('❌ But /mine endpoint expects User._id as vendorId');
    console.log('\n💡 Solution: Update orders to use User._id instead of Vendor._id');
    
    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

checkVendorStructure();
