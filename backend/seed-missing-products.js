// Seed products for vendors who have no products yet
// Usage: node seed-missing-products.js
import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

const Vendor = mongoose.model('Vendor', new mongoose.Schema({}, { strict: false }), 'vendors');
const Product = mongoose.model('Product', new mongoose.Schema({}, { strict: false }), 'products');

function sampleItemsFor(vendor) {
  // Rotate tags so each vendor gets a mix across sections
  const base = [
    { name: 'Jollof Rice Combo', description: 'Rice, chicken, plantain', price: 2200, category: 'Restaurant', unit: 'plate', quantity: 30 },
    { name: 'Shawarma', description: 'Chicken shawarma wrap', price: 1500, category: 'FastFood', unit: 'wrap', quantity: 40 },
    { name: 'Zobo Drink', description: 'Hibiscus iced drink', price: 500, category: 'Drinks', unit: 'bottle', quantity: 50 },
    { name: 'Meat Pie', description: 'Crispy beef pie', price: 400, category: 'Snacks', unit: 'piece', quantity: 60 },
  ];
  const tagsSets = [ ['Explore'], ['Featured'], ['FoodCourt'], ['FoodCourt'] ];
  return base.map((p, i) => ({
    ...p,
    vendorId: vendor._id,
    available: true,
    tags: tagsSets[i % tagsSets.length],
    createdAt: new Date(),
    updatedAt: new Date(),
  }));
}

async function run() {
  try {
    if (!process.env.MONGO_URI) throw new Error('MONGO_URI not set in environment');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');

    const vendors = await Vendor.find({});
    console.log(`Found ${vendors.length} vendors`);

    let seededVendors = 0;
    for (const v of vendors) {
      const count = await Product.countDocuments({ vendorId: v._id });
      if (count === 0) {
        const items = sampleItemsFor(v);
        await Product.insertMany(items);
        seededVendors += 1;
        console.log(`🌱 Seeded ${items.length} products for vendor: ${v.businessName || v.storeName || v._id}`);
      }
    }

    if (seededVendors === 0) {
      console.log('ℹ️ No vendors without products. Nothing to seed.');
    } else {
      console.log(`\n🎉 Completed seeding for ${seededVendors} vendors.`);
    }
  } catch (e) {
    console.error('❌ Seed error:', e.message);
    process.exitCode = 1;
  } finally {
    try { await mongoose.connection.close(); } catch {}
  }
}

run();
