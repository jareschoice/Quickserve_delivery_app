// Setup Test Vendors with Products
// Run: node setup-test-vendors.js

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';

dotenv.config();

// Connect to MongoDB
await mongoose.connect(process.env.MONGO_URI);
console.log('✅ Connected to MongoDB');

// Import models
const UserSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  role: { type: String, enum: ['customer', 'vendor', 'rider', 'admin'], default: 'customer' },
  isVerified: { type: Boolean, default: false },
  profile: {
    phone: String,
    address: String,
    businessName: String,
    businessAddress: String,
    businessPhone: String,
  },
}, { timestamps: true });

const VendorSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  businessName: { type: String, required: true },
  businessAddress: String,
  businessPhone: String,
  businessType: String,
  isActive: { type: Boolean, default: true },
  rating: { type: Number, default: 0 },
  totalOrders: { type: Number, default: 0 },
  earnings: { type: Number, default: 0 },
}, { timestamps: true });

const ProductSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  price: { type: Number, required: true },
  category: String,
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'Vendor', required: true },
  imageUrl: String,
  isAvailable: { type: Boolean, default: true },
  quantity: { type: Number, default: 0 },
}, { timestamps: true });

const User = mongoose.model('User', UserSchema);
const Vendor = mongoose.model('Vendor', VendorSchema);
const Product = mongoose.model('Product', ProductSchema);

// Test vendor data
const testVendors = [
  {
    businessName: "Mama's Kitchen",
    businessAddress: "Block A, Stadium Road",
    businessPhone: "08012345671",
    businessType: "Restaurant",
    email: "mamas.kitchen@quickserve.test",
    password: "vendor123",
    products: [
      { name: "Jollof Rice", description: "Spicy Nigerian jollof rice", price: 1500, category: "Main Course" },
      { name: "Fried Rice", description: "Chinese-style fried rice", price: 1500, category: "Main Course" },
      { name: "Chicken Wings", description: "Crispy fried wings", price: 2000, category: "Snacks" },
      { name: "Beef Suya", description: "Grilled beef skewers", price: 1000, category: "Snacks" },
      { name: "Fish & Chips", description: "Fried fish with potato chips", price: 2500, category: "Main Course" },
      { name: "Moi Moi", description: "Steamed bean pudding", price: 500, category: "Side Dish" },
      { name: "Puff Puff", description: "Sweet fried dough balls", price: 300, category: "Snacks" },
      { name: "Meat Pie", description: "Savory meat-filled pastry", price: 400, category: "Snacks" },
      { name: "Chicken Shawarma", description: "Grilled chicken wrap", price: 1200, category: "Fast Food" },
      { name: "Beef Burger", description: "Juicy beef burger", price: 1500, category: "Fast Food" },
      { name: "Plantain Chips", description: "Crispy plantain slices", price: 500, category: "Snacks" },
      { name: "Spring Rolls", description: "Vegetable spring rolls", price: 600, category: "Snacks" },
      { name: "Pasta Bolognese", description: "Pasta with meat sauce", price: 1800, category: "Main Course" },
      { name: "Chicken Pizza", description: "8-inch chicken pizza", price: 2500, category: "Fast Food" },
      { name: "Coleslaw", description: "Fresh vegetable salad", price: 500, category: "Side Dish" },
      { name: "Fruit Salad", description: "Mixed fresh fruits", price: 800, category: "Dessert" },
      { name: "Ice Cream", description: "Vanilla ice cream", price: 500, category: "Dessert" },
      { name: "Coke 50cl", description: "Coca-Cola soft drink", price: 200, category: "Drinks" },
      { name: "Bottled Water", description: "500ml bottled water", price: 100, category: "Drinks" },
      { name: "Chapman", description: "Mixed fruit drink", price: 600, category: "Drinks" },
    ]
  },
  {
    businessName: "Campus Bites",
    businessAddress: "Stadium Gate, Beside Bookshop",
    businessPhone: "08012345672",
    businessType: "Fast Food",
    email: "campus.bites@quickserve.test",
    password: "vendor123",
    products: [
      { name: "Combo Meal A", description: "Rice, chicken & drink", price: 1800, category: "Combo" },
      { name: "Combo Meal B", description: "Burger, chips & drink", price: 2000, category: "Combo" },
      { name: "Fried Yam", description: "Golden fried yam", price: 800, category: "Snacks" },
      { name: "Egg Sauce", description: "Tomato egg sauce", price: 500, category: "Side Dish" },
      { name: "Sausage Roll", description: "Baked sausage pastry", price: 400, category: "Snacks" },
      { name: "Doughnut", description: "Sugar-coated doughnut", price: 300, category: "Snacks" },
      { name: "Hot Dog", description: "Grilled sausage in bun", price: 800, category: "Fast Food" },
      { name: "Sandwich", description: "Club sandwich", price: 1000, category: "Fast Food" },
      { name: "Noodles", description: "Indomie special", price: 600, category: "Main Course" },
      { name: "Spaghetti", description: "Spaghetti with sauce", price: 1200, category: "Main Course" },
      { name: "Potato Chips", description: "Crispy potato fries", price: 500, category: "Side Dish" },
      { name: "Chicken Nuggets", description: "6 pieces chicken nuggets", price: 1200, category: "Snacks" },
      { name: "Samosa", description: "Fried triangle pastry", price: 300, category: "Snacks" },
      { name: "Akara", description: "Fried bean cakes", price: 300, category: "Snacks" },
      { name: "Bread & Egg", description: "Bread with fried egg", price: 500, category: "Breakfast" },
      { name: "Yoghurt", description: "Fruit yoghurt cup", price: 400, category: "Drinks" },
      { name: "Smoothie", description: "Mixed fruit smoothie", price: 800, category: "Drinks" },
      { name: "Fanta 50cl", description: "Orange soft drink", price: 200, category: "Drinks" },
      { name: "Energy Drink", description: "Power energy drink", price: 400, category: "Drinks" },
      { name: "Tea", description: "Hot or iced tea", price: 300, category: "Drinks" },
    ]
  },
  {
    businessName: "Quick Snacks Hub",
    businessAddress: "Front Gate, Main Campus",
    businessPhone: "08012345673",
    businessType: "Snack Bar",
    email: "quick.snacks@quickserve.test",
    password: "vendor123",
    products: [
      { name: "Popcorn", description: "Butter popcorn", price: 400, category: "Snacks" },
      { name: "Chin Chin", description: "Crunchy chin chin", price: 300, category: "Snacks" },
      { name: "Groundnut", description: "Roasted groundnuts", price: 200, category: "Snacks" },
      { name: "Coconut Candy", description: "Sweet coconut candy", price: 200, category: "Snacks" },
      { name: "Biscuits", description: "Assorted biscuits", price: 300, category: "Snacks" },
      { name: "Chocolate Bar", description: "Milk chocolate", price: 400, category: "Snacks" },
      { name: "Gala", description: "Meat pie snack", price: 200, category: "Snacks" },
      { name: "Crackers", description: "Cheese crackers", price: 300, category: "Snacks" },
      { name: "Banana Chips", description: "Sweet banana chips", price: 400, category: "Snacks" },
      { name: "Kulikuli", description: "Groundnut cake", price: 200, category: "Snacks" },
      { name: "Chewing Gum", description: "Mint chewing gum", price: 100, category: "Snacks" },
      { name: "Candy", description: "Assorted candy", price: 100, category: "Snacks" },
      { name: "Cookies", description: "Chocolate chip cookies", price: 500, category: "Snacks" },
      { name: "Cake Slice", description: "Vanilla cake slice", price: 600, category: "Dessert" },
      { name: "Muffin", description: "Blueberry muffin", price: 500, category: "Dessert" },
      { name: "Juice Box", description: "100% fruit juice", price: 300, category: "Drinks" },
      { name: "Capri Sun", description: "Orange drink", price: 200, category: "Drinks" },
      { name: "Hollandia Yoghurt", description: "200ml yoghurt", price: 300, category: "Drinks" },
      { name: "Peak Milk", description: "Milk sachet", price: 150, category: "Drinks" },
      { name: "Coffee", description: "Hot or cold coffee", price: 400, category: "Drinks" },
    ]
  },
  {
    businessName: "Stadium Grill",
    businessAddress: "Stadium Complex, Sports Center",
    businessPhone: "08012345674",
    businessType: "Grill & BBQ",
    email: "stadium.grill@quickserve.test",
    password: "vendor123",
    products: [
      { name: "Grilled Chicken", description: "Half chicken grilled", price: 2500, category: "Grills" },
      { name: "Grilled Fish", description: "Whole tilapia grilled", price: 3000, category: "Grills" },
      { name: "BBQ Ribs", description: "Pork ribs with sauce", price: 3500, category: "Grills" },
      { name: "Kebab", description: "Beef kebab skewers", price: 1500, category: "Grills" },
      { name: "Turkey Wings", description: "Grilled turkey wings", price: 2000, category: "Grills" },
      { name: "Goat Meat Pepper Soup", description: "Spicy goat soup", price: 1800, category: "Soups" },
      { name: "Catfish Pepper Soup", description: "Fresh catfish soup", price: 2000, category: "Soups" },
      { name: "Asun", description: "Spicy goat meat", price: 2500, category: "Grills" },
      { name: "Peppered Gizzard", description: "Spicy chicken gizzard", price: 1500, category: "Snacks" },
      { name: "Peppered Snail", description: "Garden snails in pepper", price: 2000, category: "Snacks" },
      { name: "Yam Porridge", description: "Yam & vegetables", price: 1200, category: "Main Course" },
      { name: "Beans Porridge", description: "Beans & plantain", price: 1000, category: "Main Course" },
      { name: "Ofada Rice", description: "Local rice with sauce", price: 1500, category: "Main Course" },
      { name: "Efo Riro", description: "Vegetable soup", price: 1200, category: "Soups" },
      { name: "Egusi Soup", description: "Melon seed soup", price: 1500, category: "Soups" },
      { name: "Pounded Yam", description: "With soup of choice", price: 1800, category: "Main Course" },
      { name: "Amala", description: "Yam flour meal", price: 1500, category: "Main Course" },
      { name: "Palm Wine", description: "Fresh palm wine", price: 500, category: "Drinks" },
      { name: "Zobo", description: "Hibiscus drink", price: 400, category: "Drinks" },
      { name: "Kunu", description: "Millet drink", price: 400, category: "Drinks" },
    ]
  },
  {
    businessName: "Fresh Bites",
    businessAddress: "Library Road, Academic Block",
    businessPhone: "08012345675",
    businessType: "Healthy Food",
    email: "fresh.bites@quickserve.test",
    password: "vendor123",
    products: [
      { name: "Greek Salad", description: "Fresh vegetable salad", price: 1500, category: "Salads" },
      { name: "Caesar Salad", description: "Chicken caesar salad", price: 1800, category: "Salads" },
      { name: "Grilled Chicken Wrap", description: "Healthy chicken wrap", price: 1500, category: "Wraps" },
      { name: "Veggie Wrap", description: "Vegetarian wrap", price: 1200, category: "Wraps" },
      { name: "Smoothie Bowl", description: "Fruit & granola bowl", price: 1800, category: "Breakfast" },
      { name: "Oatmeal", description: "Honey oatmeal", price: 1000, category: "Breakfast" },
      { name: "Pancakes", description: "3 fluffy pancakes", price: 1200, category: "Breakfast" },
      { name: "Waffles", description: "Belgian waffles", price: 1500, category: "Breakfast" },
      { name: "Avocado Toast", description: "Toast with avocado", price: 1500, category: "Breakfast" },
      { name: "Fruit Bowl", description: "Mixed fresh fruits", price: 1000, category: "Breakfast" },
      { name: "Protein Shake", description: "Muscle builder shake", price: 1500, category: "Drinks" },
      { name: "Green Juice", description: "Vegetable detox juice", price: 1200, category: "Drinks" },
      { name: "Orange Juice", description: "Fresh squeezed OJ", price: 800, category: "Drinks" },
      { name: "Pineapple Juice", description: "Fresh pineapple juice", price: 800, category: "Drinks" },
      { name: "Watermelon Juice", description: "Fresh watermelon juice", price: 600, category: "Drinks" },
      { name: "Granola Bar", description: "Energy granola bar", price: 500, category: "Snacks" },
      { name: "Trail Mix", description: "Nuts & dried fruits", price: 600, category: "Snacks" },
      { name: "Protein Bar", description: "High protein bar", price: 700, category: "Snacks" },
      { name: "Energy Balls", description: "Date & nut balls", price: 500, category: "Snacks" },
      { name: "Chia Pudding", description: "Coconut chia pudding", price: 1200, category: "Dessert" },
    ]
  },
];

// Create vendors and products
console.log('\n🚀 Creating test vendors and products...\n');

for (const vendorData of testVendors) {
  try {
    // Check if user already exists
    let user = await User.findOne({ email: vendorData.email });
    
    if (!user) {
      // Create user account
      const hashedPassword = await bcrypt.hash(vendorData.password, 10);
      user = await User.create({
        name: vendorData.businessName,
        email: vendorData.email,
        password: hashedPassword,
        role: 'vendor',
        isVerified: true,
        profile: {
          businessName: vendorData.businessName,
          businessAddress: vendorData.businessAddress,
          businessPhone: vendorData.businessPhone,
          phone: vendorData.businessPhone,
        }
      });
      console.log(`✅ Created user: ${vendorData.email}`);
    } else {
      console.log(`ℹ️  User exists: ${vendorData.email}`);
    }

    // Check if vendor profile exists
    let vendor = await Vendor.findOne({ user: user._id });
    
    if (!vendor) {
      // Create vendor profile
      vendor = await Vendor.create({
        user: user._id,
        businessName: vendorData.businessName,
        businessAddress: vendorData.businessAddress,
        businessPhone: vendorData.businessPhone,
        businessType: vendorData.businessType,
        isActive: true,
        rating: 4.5,
        totalOrders: 0,
        earnings: 0,
      });
      console.log(`✅ Created vendor: ${vendorData.businessName}`);
    } else {
      console.log(`ℹ️  Vendor exists: ${vendorData.businessName}`);
    }

    // Check if products exist
    const existingProducts = await Product.countDocuments({ vendorId: vendor._id });
    
    if (existingProducts === 0) {
      // Create products
      const products = vendorData.products.map(p => ({
        ...p,
        vendorId: vendor._id,
        quantity: Math.floor(Math.random() * 50) + 10, // Random quantity 10-60
        isAvailable: true,
      }));
      
      await Product.insertMany(products);
      console.log(`✅ Created ${products.length} products for ${vendorData.businessName}\n`);
    } else {
      console.log(`ℹ️  Products exist for ${vendorData.businessName} (${existingProducts} items)\n`);
    }

  } catch (error) {
    console.error(`❌ Error creating ${vendorData.businessName}:`, error.message);
  }
}

console.log('\n✅ Test vendor setup complete!\n');
console.log('📋 Login Credentials:');
console.log('─────────────────────────────────────────');
testVendors.forEach(v => {
  console.log(`${v.businessName}:`);
  console.log(`  Email: ${v.email}`);
  console.log(`  Password: ${v.password}`);
  console.log('');
});

await mongoose.connection.close();
console.log('✅ Database connection closed');
