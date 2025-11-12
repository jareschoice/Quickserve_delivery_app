const mongoose = require('mongoose');
require('dotenv').config();

const userSchema = new mongoose.Schema({}, { strict: false });
const User = mongoose.model('User', userSchema, 'users');

async function approveVendors() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('\n✅ Connected to MongoDB\n');

    // Approve all test vendors
    const testEmails = [
      'mamas.kitchen@quickserve.test',
      'campus.bites@quickserve.test',
      'quick.snacks@quickserve.test'
    ];

    for (const email of testEmails) {
      const result = await User.updateOne(
        { email },
        { $set: { kycStatus: 'approved' } }
      );
      console.log(`${email}: ${result.modifiedCount > 0 ? '✅ KYC Approved' : '⚠️  Already approved or not found'}`);
    }

    console.log('\n🎉 All test vendors approved!\n');
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    process.exit(1);
  }
}

approveVendors();
