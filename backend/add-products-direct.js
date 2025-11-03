import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

async function addProductsDirectly() {
  try {
    console.log('🔍 Connecting to MongoDB...\n');
    await mongoose.connect(process.env.MONGO_URI);
    
    // Find the vendor
    const Vendor = mongoose.model('Vendor', new mongoose.Schema({}, { strict: false }), 'vendors');
    const vendor = await Vendor.findOne({ storeName: 'QuickServe Test Restaurant' });
    
    if (!vendor) {
      console.log('❌ Vendor not found!');
      process.exit(1);
    }
    
    console.log('✅ Vendor found:', vendor.storeName);
    console.log('🆔 Vendor ID:', vendor._id, '\n');
    
    // Create products
    const Product = mongoose.model('Product', new mongoose.Schema({}, { strict: false }), 'products');
    
    const products = [
      {
        vendorId: vendor._id,
        name: 'Special Jollof Rice',
        description: 'Delicious Nigerian Jollof Rice with chicken and plantain',
        price: 2500,
        category: 'Main Dishes',
        quantity: 100,
        prepDurationMins: 30,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        vendorId: vendor._id,
        name: 'Fried Rice with Chicken',
        description: 'Tasty fried rice with grilled chicken and vegetables',
        price: 2800,
        category: 'Main Dishes',
        quantity: 100,
        prepDurationMins: 35,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        vendorId: vendor._id,
        name: 'Amala and Ewedu',
        description: 'Traditional Yoruba meal with assorted meat',
        price: 2000,
        category: 'Local Dishes',
        quantity: 50,
        prepDurationMins: 25,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        vendorId: vendor._id,
        name: 'Suya (Beef)',
        description: 'Spicy grilled beef skewers - 5 sticks',
        price: 1500,
        category: 'Snacks',
        quantity: 200,
        prepDurationMins: 15,
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        vendorId: vendor._id,
        name: 'Pounded Yam & Egusi',
        description: 'Fresh pounded yam with rich Egusi soup',
        price: 2200,
        category: 'Local Dishes',
        quantity: 50,
        prepDurationMins: 40,
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ];
    
    console.log('🍱 Adding products directly to database...\n');
    
    for (const product of products) {
      await Product.create(product);
      console.log(`✅ Added: ${product.name} - ₦${product.price}`);
    }
    
    console.log('\n🎉 ALL PRODUCTS ADDED SUCCESSFULLY!\n');
    console.log('📊 Summary:');
    console.log('   🏪 Vendor: QuickServe Test Restaurant');
    console.log('   🍽️ Products: 5 items');
    console.log('   💰 Price Range: ₦1,500 - ₦2,800');
    console.log('\n✅ Ready for customers to browse and order!');
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addProductsDirectly();
