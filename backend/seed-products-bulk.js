// Seed 20 products for each vendor automatically
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import Product from './src/models/Product.js';
import Vendor from './src/models/Vendor.js';
import User from './src/models/User.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

// Product templates by category
const productTemplates = {
  restaurant: [
    { name: 'Jollof Rice with Chicken', description: 'Delicious Nigerian jollof rice served with grilled chicken', price: 2500, unit: 'plate', prepDurationMins: 30 },
    { name: 'Fried Rice & Plantain', description: 'Tasty fried rice with sweet plantain and fish', price: 2000, unit: 'plate', prepDurationMins: 25 },
    { name: 'Pounded Yam & Egusi Soup', description: 'Traditional pounded yam with rich egusi soup and assorted meat', price: 3000, unit: 'plate', prepDurationMins: 40 },
    { name: 'Amala & Ewedu', description: 'Fresh amala with ewedu soup and goat meat', price: 2200, unit: 'plate', prepDurationMins: 35 },
    { name: 'Pepper Soup (Catfish)', description: 'Spicy catfish pepper soup with herbs', price: 2800, unit: 'bowl', prepDurationMins: 20 },
    { name: 'Suya (Beef)', description: 'Grilled spicy beef suya with onions', price: 1500, unit: 'wrap', prepDurationMins: 15 },
    { name: 'Small Chops Platter', description: 'Mixed small chops - samosa, spring rolls, puff puff', price: 3500, unit: 'pack', prepDurationMins: 30 },
    { name: 'Ofada Rice & Ayamase', description: 'Local ofada rice with designer stew', price: 2700, unit: 'plate', prepDurationMins: 35 },
    { name: 'Spaghetti Bolognese', description: 'Italian spaghetti with beef sauce', price: 1800, unit: 'plate', prepDurationMins: 20 },
    { name: 'Eba & Ogbono Soup', description: 'Eba with ogbono soup and stockfish', price: 2400, unit: 'plate', prepDurationMins: 30 },
    { name: 'Chicken & Chips', description: 'Crispy fried chicken with french fries', price: 2600, unit: 'combo', prepDurationMins: 25 },
    { name: 'Moi Moi', description: 'Steamed bean pudding', price: 800, unit: 'piece', prepDurationMins: 45 },
    { name: 'Akara (Bean Cake)', description: 'Fried bean cakes', price: 500, unit: 'pack', prepDurationMins: 15 },
    { name: 'Nkwobi', description: 'Spicy cow foot delicacy', price: 3200, unit: 'plate', prepDurationMins: 40 },
    { name: 'Asun (Peppered Goat Meat)', description: 'Spicy grilled goat meat', price: 3500, unit: 'plate', prepDurationMins: 30 },
    { name: 'Gizdodo', description: 'Gizzard and plantain in pepper sauce', price: 2900, unit: 'plate', prepDurationMins: 25 },
    { name: 'Chicken Shawarma', description: 'Grilled chicken shawarma wrap', price: 1800, unit: 'wrap', prepDurationMins: 10 },
    { name: 'Yam Porridge', description: 'Yam porridge with vegetables and fish', price: 2100, unit: 'plate', prepDurationMins: 35 },
    { name: 'Boli & Groundnut', description: 'Roasted plantain with groundnuts', price: 1000, unit: 'combo', prepDurationMins: 15 },
    { name: 'Fish & Chips', description: 'Fried fish fillet with chips', price: 2700, unit: 'plate', prepDurationMins: 20 },
  ],
  pharmacy: [
    { name: 'Paracetamol Tablets', description: 'Pain relief and fever reducer - 500mg', price: 500, unit: 'pack', prepDurationMins: 5 },
    { name: 'Vitamin C Tablets', description: 'Immune system booster - 1000mg', price: 2500, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Antibacterial Hand Sanitizer', description: '500ml antibacterial hand sanitizer', price: 1500, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Digital Thermometer', description: 'Fast digital thermometer', price: 3000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Face Masks (50pcs)', description: 'Disposable surgical face masks', price: 2000, unit: 'box', prepDurationMins: 5 },
    { name: 'Blood Pressure Monitor', description: 'Digital automatic BP monitor', price: 15000, unit: 'piece', prepDurationMins: 5 },
    { name: 'First Aid Kit', description: 'Complete first aid kit with essentials', price: 5000, unit: 'box', prepDurationMins: 5 },
    { name: 'Multivitamin Tablets', description: 'Daily multivitamin supplement', price: 3500, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Cough Syrup', description: 'Relief for cough and cold', price: 1800, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Antiseptic Solution', description: 'Dettol antiseptic liquid 500ml', price: 2200, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Bandages Assorted', description: 'Various sizes of adhesive bandages', price: 800, unit: 'pack', prepDurationMins: 5 },
    { name: 'Pain Relief Gel', description: 'Topical pain relief gel', price: 2500, unit: 'tube', prepDurationMins: 5 },
    { name: 'Oral Rehydration Salt', description: 'ORS for dehydration', price: 300, unit: 'sachet', prepDurationMins: 5 },
    { name: 'Zinc Tablets', description: 'Zinc supplement 50mg', price: 2000, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Cotton Wool', description: 'Medical grade cotton wool 500g', price: 1000, unit: 'pack', prepDurationMins: 5 },
    { name: 'Medical Gloves', description: 'Disposable latex gloves - 100pcs', price: 3500, unit: 'box', prepDurationMins: 5 },
    { name: 'Eye Drops', description: 'Lubricating eye drops', price: 1500, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Antibiotic Ointment', description: 'Topical antibiotic cream', price: 1200, unit: 'tube', prepDurationMins: 5 },
    { name: 'Glucose Meter Kit', description: 'Blood glucose monitoring kit', price: 8000, unit: 'set', prepDurationMins: 5 },
    { name: 'Calcium Tablets', description: 'Calcium supplement 600mg', price: 2800, unit: 'bottle', prepDurationMins: 5 },
  ],
  shop: [
    { name: 'Designer T-Shirt', description: 'Premium cotton t-shirt', price: 5000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Jeans Trouser', description: 'Stylish denim jeans', price: 12000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Sneakers', description: 'Comfortable sports sneakers', price: 18000, unit: 'pair', prepDurationMins: 5 },
    { name: 'Wristwatch', description: 'Elegant analog wristwatch', price: 25000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Laptop Bag', description: 'Durable laptop backpack', price: 8000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Phone Case', description: 'Protective phone case', price: 2500, unit: 'piece', prepDurationMins: 5 },
    { name: 'Wireless Earbuds', description: 'Bluetooth wireless earbuds', price: 15000, unit: 'pair', prepDurationMins: 5 },
    { name: 'Power Bank 20000mAh', description: 'High capacity power bank', price: 12000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Perfume', description: 'Long-lasting fragrance', price: 8500, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Sunglasses', description: 'UV protection sunglasses', price: 6000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Wallet (Leather)', description: 'Genuine leather wallet', price: 7000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Belt (Leather)', description: 'Premium leather belt', price: 5500, unit: 'piece', prepDurationMins: 5 },
    { name: 'Cap/Hat', description: 'Stylish baseball cap', price: 3000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Bluetooth Speaker', description: 'Portable wireless speaker', price: 16000, unit: 'piece', prepDurationMins: 5 },
    { name: 'USB Flash Drive 64GB', description: 'High-speed flash drive', price: 4000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Phone Charger', description: 'Fast charging adapter', price: 3500, unit: 'piece', prepDurationMins: 5 },
    { name: 'HDMI Cable', description: '2m HDMI cable', price: 2000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Mouse (Wireless)', description: 'Wireless computer mouse', price: 4500, unit: 'piece', prepDurationMins: 5 },
    { name: 'Keyboard (Wireless)', description: 'Wireless keyboard', price: 8000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Travel Mug', description: 'Insulated travel mug', price: 3500, unit: 'piece', prepDurationMins: 5 },
  ],
  supermarket: [
    { name: 'Rice (5kg)', description: 'Premium long grain rice', price: 8000, unit: 'bag', prepDurationMins: 5 },
    { name: 'Vegetable Oil (5L)', description: 'Pure vegetable cooking oil', price: 12000, unit: 'bottle', prepDurationMins: 5 },
    { name: 'Sugar (2kg)', description: 'White granulated sugar', price: 2500, unit: 'pack', prepDurationMins: 5 },
    { name: 'Salt (1kg)', description: 'Iodized table salt', price: 500, unit: 'pack', prepDurationMins: 5 },
    { name: 'Pasta (500g)', description: 'Spaghetti pasta', price: 800, unit: 'pack', prepDurationMins: 5 },
    { name: 'Tomato Paste (400g)', description: 'Concentrated tomato paste', price: 600, unit: 'tin', prepDurationMins: 5 },
    { name: 'Milk (1L)', description: 'Fresh full cream milk', price: 1500, unit: 'carton', prepDurationMins: 5 },
    { name: 'Bread (Large)', description: 'Sliced white bread', price: 1200, unit: 'loaf', prepDurationMins: 5 },
    { name: 'Eggs (Crate)', description: '30 eggs crate', price: 4500, unit: 'crate', prepDurationMins: 5 },
    { name: 'Chicken (Frozen 1kg)', description: 'Frozen whole chicken', price: 3500, unit: 'pack', prepDurationMins: 5 },
    { name: 'Beef (1kg)', description: 'Fresh beef meat', price: 5000, unit: 'kg', prepDurationMins: 5 },
    { name: 'Fish (Frozen 1kg)', description: 'Frozen tilapia fish', price: 3000, unit: 'pack', prepDurationMins: 5 },
    { name: 'Onions (2kg)', description: 'Fresh onions', price: 1500, unit: 'bag', prepDurationMins: 5 },
    { name: 'Tomatoes (2kg)', description: 'Fresh tomatoes', price: 2000, unit: 'bag', prepDurationMins: 5 },
    { name: 'Potatoes (2kg)', description: 'Irish potatoes', price: 1800, unit: 'bag', prepDurationMins: 5 },
    { name: 'Garri (2kg)', description: 'Yellow garri', price: 1200, unit: 'bag', prepDurationMins: 5 },
    { name: 'Beans (2kg)', description: 'Brown beans', price: 2500, unit: 'bag', prepDurationMins: 5 },
    { name: 'Yam Tuber (Medium)', description: 'Fresh yam tuber', price: 3000, unit: 'piece', prepDurationMins: 5 },
    { name: 'Bottled Water (12 pack)', description: '75cl bottled water', price: 2000, unit: 'pack', prepDurationMins: 5 },
    { name: 'Soft Drink (Coke 50cl)', description: 'Coca-Cola 50cl', price: 400, unit: 'bottle', prepDurationMins: 5 },
  ]
};

async function seedProducts() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB!\n');

    // Get all vendors
    const vendors = await Vendor.find({ isActive: true }).populate('user');
    
    if (vendors.length === 0) {
      console.log('❌ No vendors found! Run seed-vendors-and-dispatchers.js first.');
      process.exit(1);
    }

    console.log(`📦 Found ${vendors.length} vendors. Creating 20 products for each...\n`);

    let totalProducts = 0;

    for (const vendor of vendors) {
      const category = vendor.category;
      const templates = productTemplates[category] || productTemplates.shop;
      
      console.log(`\n🏪 ${vendor.vendorId}: ${vendor.businessName} (${category})`);
      console.log('   Creating products:');

      for (const template of templates) {
        try {
          const product = await Product.create({
            vendorId: vendor._id,
            name: template.name,
            description: template.description,
            price: template.price,
            quantity: Math.floor(Math.random() * 50) + 20, // Random stock 20-70
            unit: template.unit,
            category: category,
            available: true,
            imageUrl: '/uploads/placeholder-product.jpg',
            prepDurationMins: template.prepDurationMins,
            tags: [category, 'featured', 'popular']
          });

          totalProducts++;
          console.log(`   ✅ ${product.name} - ₦${product.price}`);
        } catch (error) {
          console.log(`   ⚠️  Skipping duplicate: ${template.name}`);
        }
      }
    }

    console.log('\n═══════════════════════════════════════════════════════════════');
    console.log('                    🎉 PRODUCTS SEEDED!');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log(`✅ ${totalProducts} products created`);
    console.log(`✅ ${vendors.length} vendors now have products`);
    console.log('✅ All products available for ordering');
    console.log('✅ Ready to display on home page\n');

    console.log('🚀 Next Steps:');
    console.log('   1. Open home page: http://192.168.88.104:5555/event-frontend/home.html');
    console.log('   2. All vendors should appear by category');
    console.log('   3. Click any vendor to see their 20 products');
    console.log('   4. Use credentials from TEST_ACCOUNTS_CREDENTIALS.txt to login\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding products:', error);
    process.exit(1);
  }
}

seedProducts();
