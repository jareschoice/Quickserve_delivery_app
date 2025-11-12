// QuickServe Event Edition - Test Data Setup Script
// Run this script to create test vendors and products

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import User from './src/models/User.js';
import Product from './src/models/Product.js';
import { connectDB } from './src/lib/db.js';

dotenv.config();

const VENDORS = [
  { name: 'Mama Put Kitchen', businessName: 'Mama Put Kitchen', category: 'Food' },
  { name: 'Burger Palace', businessName: 'Burger Palace', category: 'Fast Food' },
  { name: 'Suya Spot', businessName: 'Suya Spot', category: 'Grilled' },
  { name: 'Smoothie Corner', businessName: 'Smoothie Corner', category: 'Drinks' },
  { name: 'Pizza Hub', businessName: 'Pizza Hub', category: 'Fast Food' },
  { name: 'Ice Cream Paradise', businessName: 'Ice Cream Paradise', category: 'Desserts' },
  { name: 'Rice & More', businessName: 'Rice & More', category: 'Food' },
  { name: 'Chicken Delight', businessName: 'Chicken Delight', category: 'Fast Food' },
  { name: 'Juice Bar', businessName: 'Fresh Juice Bar', category: 'Drinks' },
  { name: 'Pastry Shop', businessName: 'Sweet Pastries', category: 'Desserts' },
  { name: 'Noodles Express', businessName: 'Noodles Express', category: 'Food' },
  { name: 'Shawarma King', businessName: 'Shawarma King', category: 'Fast Food' },
  { name: 'Coffee Corner', businessName: 'Coffee Corner', category: 'Drinks' },
  { name: 'Salad Bar', businessName: 'Fresh Salad Bar', category: 'Healthy' },
  { name: 'Snack Attack', businessName: 'Snack Attack', category: 'Snacks' },
  { name: 'Grilled Fish', businessName: 'Grilled Fish Spot', category: 'Seafood' },
  { name: 'Donut Shop', businessName: 'Donut Shop', category: 'Desserts' },
  { name: 'Taco Stand', businessName: 'Taco Stand', category: 'Fast Food' },
  { name: 'Smoothie Bowl', businessName: 'Smoothie Bowl', category: 'Healthy' },
  { name: 'BBQ Grill', businessName: 'BBQ Grill Master', category: 'Grilled' }
];

const SAMPLE_PRODUCTS = {
  'Food': [
    { name: 'Jollof Rice', price: 1500 },
    { name: 'Fried Rice', price: 1500 },
    { name: 'Rice & Stew', price: 1200 },
    { name: 'White Rice & Sauce', price: 1300 }
  ],
  'Fast Food': [
    { name: 'Burger', price: 2000 },
    { name: 'Chicken Wings', price: 2500 },
    { name: 'Fries', price: 800 },
    { name: 'Hot Dog', price: 1500 }
  ],
  'Grilled': [
    { name: 'Suya (Small)', price: 1500 },
    { name: 'Suya (Large)', price: 3000 },
    { name: 'Grilled Chicken', price: 2500 },
    { name: 'Grilled Fish', price: 3500 }
  ],
  'Drinks': [
    { name: 'Smoothie', price: 1000 },
    { name: 'Fresh Juice', price: 800 },
    { name: 'Soft Drink', price: 300 },
    { name: 'Water', price: 200 }
  ],
  'Desserts': [
    { name: 'Ice Cream', price: 1000 },
    { name: 'Cake Slice', price: 1500 },
    { name: 'Donut', price: 500 },
    { name: 'Pastry', price: 800 }
  ],
  'Healthy': [
    { name: 'Caesar Salad', price: 2000 },
    { name: 'Greek Salad', price: 2200 },
    { name: 'Fruit Bowl', price: 1500 },
    { name: 'Smoothie Bowl', price: 1800 }
  ],
  'Snacks': [
    { name: 'Puff Puff', price: 500 },
    { name: 'Chin Chin', price: 500 },
    { name: 'Samosa', price: 600 },
    { name: 'Spring Roll', price: 700 }
  ],
  'Seafood': [
    { name: 'Grilled Tilapia', price: 4000 },
    { name: 'Grilled Catfish', price: 3500 },
    { name: 'Fried Fish', price: 3000 },
    { name: 'Fish Pepper Soup', price: 2500 }
  ]
};

async function createVendorsAndProducts() {
  try {
    console.log('🔄 Connecting to database...');
    await connectDB();

    console.log('🗑️ Clearing existing event test data...');
    // Don't delete all users, only test vendors
    await User.deleteMany({ email: { $regex: /vendor\d+@event\.test/ } });

    console.log('👥 Creating vendors...');
    const createdVendors = [];

    for (let i = 0; i < VENDORS.length; i++) {
      const vendor = VENDORS[i];
      const hashedPassword = await bcrypt.hash('password123', 10);

      const newVendor = await User.create({
        email: `vendor${i + 1}@event.test`,
        password: hashedPassword,
        name: vendor.name,
        role: 'vendor',
        isVerified: true,
        profile: {
          businessName: vendor.businessName,
          phone: `0801234${String(i + 1).padStart(4, '0')}`
        }
      });

      console.log(`✅ Created vendor: ${vendor.name} (${newVendor.email})`);
      createdVendors.push({ ...newVendor.toObject(), category: vendor.category });
    }

    console.log('\n📦 Creating products for each vendor...');
    let totalProducts = 0;

    for (const vendor of createdVendors) {
      const products = SAMPLE_PRODUCTS[vendor.category] || SAMPLE_PRODUCTS['Food'];

      for (const product of products) {
        await Product.create({
          name: product.name,
          description: `Delicious ${product.name} from ${vendor.name}`,
          price: product.price,
          category: vendor.category,
          vendor: vendor._id,
          available: true
        });
        totalProducts++;
      }

      console.log(`✅ Created ${products.length} products for ${vendor.name}`);
    }

    console.log(`\n🎉 Successfully created ${VENDORS.length} vendors and ${totalProducts} products!`);
    console.log('\n📝 Test Credentials:');
    console.log('Email: vendor1@event.test to vendor20@event.test');
    console.log('Password: password123');
    console.log('\n💡 You can now login with any vendor account in the frontend!');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

// Create dispatchers
async function createDispatchers(count = 10) {
  try {
    console.log(`\n👷 Creating ${count} dispatchers...`);

    for (let i = 1; i <= count; i++) {
      const hashedPassword = await bcrypt.hash('password123', 10);

      await User.create({
        email: `dispatcher${i}@event.test`,
        password: hashedPassword,
        name: `Dispatcher ${i}`,
        role: 'dispatcher',
        isVerified: true,
        profile: {
          phone: `0809876${String(i).padStart(4, '0')}`
        }
      });

      console.log(`✅ Created dispatcher${i}@event.test`);
    }

    console.log(`\n🎉 Successfully created ${count} dispatchers!`);
    console.log('Email: dispatcher1@event.test to dispatcher10@event.test');
    console.log('Password: password123');
  } catch (error) {
    console.error('❌ Error creating dispatchers:', error);
  }
}

// Run the script
console.log('🚀 QuickServe Event Edition - Test Data Setup\n');
console.log('This script will create:');
console.log('- 20 test vendors');
console.log('- Products for each vendor');
console.log('- 10 test dispatchers\n');

(async () => {
  await createVendorsAndProducts();
  await createDispatchers();
  mongoose.connection.close();
})();
