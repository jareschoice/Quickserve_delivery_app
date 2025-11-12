const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  email: String,
  role: String
});

const vendorSchema = new mongoose.Schema({
  user: mongoose.Schema.Types.ObjectId,
  businessName: String
});

const User = mongoose.model('User', userSchema);
const Vendor = mongoose.model('Vendor', vendorSchema);

async function checkUserVendorMapping() {
  try {
    const uri = process.env.MONGO_URI;
    await mongoose.connect(uri);
    console.log('✅ Connected to MongoDB\n');

    // Get all vendor users
    const vendorUsers = await User.find({ role: 'vendor' });
    console.log(`Found ${vendorUsers.length} users with role 'vendor':\n`);

    for (const user of vendorUsers) {
      const vendor = await Vendor.findOne({ user: user._id });
      console.log(`User: ${user.email}`);
      console.log(`  User._id: ${user._id}`);
      console.log(`  Has Vendor profile: ${vendor ? '✅ YES' : '❌ NO'}`);
      if (vendor) {
        console.log(`  Business: ${vendor.businessName}`);
        console.log(`  Vendor._id: ${vendor._id}`);
      }
      console.log('');
    }

    await mongoose.connection.close();
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    await mongoose.connection.close();
    process.exit(1);
  }
}

checkUserVendorMapping();
