const mongoose = require('mongoose');
require('dotenv').config();

const userSchema = new mongoose.Schema({}, { strict: false });
const User = mongoose.model('User', userSchema, 'users');

const vendorSchema = new mongoose.Schema({}, { strict: false });
const Vendor = mongoose.model('Vendor', vendorSchema, 'vendors');

async function checkVendors() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('\n🔍 Checking Vendor Profiles...\n');

    // Check the logged-in user first
    const loggedInUser = await User.findById('690a1957f1326d049276d69b');
    console.log('❓ Logged-in User (690a1957f1326d049276d69b):');
    if (loggedInUser) {
      console.log(`   Email: ${loggedInUser.email}`);
      console.log(`   Name: ${loggedInUser.name}`);
      console.log(`   Role: ${loggedInUser.role}`);
      const loggedInVendor = await Vendor.findOne({ user: loggedInUser._id });
      console.log(`   Has Vendor profile: ${loggedInVendor ? '✅ YES' : '❌ NO'}`);
      if (loggedInVendor) {
        console.log(`   Business: ${loggedInVendor.businessName}`);
      }
    } else {
      console.log('   ❌ User not found');
    }

    console.log('\n📋 Our Test Vendors:');
    const testEmails = [
      'mamas.kitchen@quickserve.test',
      'campus.bites@quickserve.test',
      'quick.snacks@quickserve.test'
    ];

    for (const email of testEmails) {
      const user = await User.findOne({ email });
      if (user) {
        const vendor = await Vendor.findOne({ user: user._id });
        console.log(`\n✉️  ${email}`);
        console.log(`   User ID: ${user._id}`);
        console.log(`   Has Vendor profile: ${vendor ? '✅ YES' : '❌ NO'}`);
        if (vendor) {
          console.log(`   Business: ${vendor.businessName}`);
        }
      } else {
        console.log(`\n❌ ${email} - User not found`);
      }
    }

    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

checkVendors();
