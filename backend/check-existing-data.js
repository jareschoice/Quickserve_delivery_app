// Check existing vendors and dispatchers
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import User from './src/models/User.js';
import Vendor from './src/models/Vendor.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

async function checkExisting() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    
    const vendors = await Vendor.find().populate('user', 'name email').sort({ vendorId: 1 });
    const dispatchers = await User.find({ role: 'dispatcher' }).sort({ dispatcherId: 1 });
    
    console.log(`\n📊 Existing Data:`);
    console.log(`   Vendors: ${vendors.length}`);
    console.log(`   Dispatchers: ${dispatchers.length}\n`);
    
    if (vendors.length > 0) {
      console.log('🏪 Existing Vendors:');
      vendors.forEach(v => {
        console.log(`   ${v.vendorId || 'NO-ID'} - ${v.businessName} (${v.category})`);
      });
    }
    
    if (dispatchers.length > 0) {
      console.log('\n🚚 Existing Dispatchers:');
      dispatchers.forEach(d => {
        console.log(`   ${d.dispatcherId || 'NO-ID'} - ${d.name}`);
      });
    }
    
    console.log('\n❓ What would you like to do?');
    console.log('   1. Keep existing data and add more');
    console.log('   2. Delete ALL test data and start fresh');
    console.log('\n💡 Run the appropriate script based on your choice.');
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkExisting();
