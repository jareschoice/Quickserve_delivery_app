// Cleanup all test vendors, dispatchers, and products
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import User from './src/models/User.js';
import Vendor from './src/models/Vendor.js';
import Product from './src/models/Product.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

async function cleanup() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected!\n');

    // Get counts before deletion
    const vendorCount = await Vendor.countDocuments();
    const dispatcherCount = await User.countDocuments({ role: 'dispatcher' });
    const productCount = await Product.countDocuments();
    
    console.log('📊 Current Data:');
    console.log(`   Vendors: ${vendorCount}`);
    console.log(`   Dispatchers: ${dispatcherCount}`);
    console.log(`   Products: ${productCount}\n`);
    
    if (vendorCount === 0 && dispatcherCount === 0 && productCount === 0) {
      console.log('✅ Database is already clean!');
      process.exit(0);
    }
    
    console.log('🗑️  Deleting...');
    
    // Delete all products
    const deletedProducts = await Product.deleteMany({});
    console.log(`   ✅ Deleted ${deletedProducts.deletedCount} products`);
    
    // Delete all vendors
    const deletedVendors = await Vendor.deleteMany({});
    console.log(`   ✅ Deleted ${deletedVendors.deletedCount} vendors`);
    
    // Delete all dispatcher users
    const deletedDispatchers = await User.deleteMany({ role: 'dispatcher' });
    console.log(`   ✅ Deleted ${deletedDispatchers.deletedCount} dispatchers`);
    
    // Delete all vendor users
    const deletedVendorUsers = await User.deleteMany({ role: 'vendor' });
    console.log(`   ✅ Deleted ${deletedVendorUsers.deletedCount} vendor users`);
    
    console.log('\n✅ Cleanup complete! Database is ready for fresh test data.');
    console.log('\n🚀 Next: Run the setup script to create 20 vendors and 10 dispatchers');
    console.log('   Command: .\\SETUP_TEST_DATA.ps1\n');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    process.exit(1);
  }
}

cleanup();
