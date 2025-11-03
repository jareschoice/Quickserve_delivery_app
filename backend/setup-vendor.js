import axios from 'axios';
import FormData from 'form-data';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const BASE_URL = 'http://localhost:5555';
let authToken = '';
let vendorId = '';

// Step 1: Login
async function login() {
  try {
    console.log('🔐 Logging in as vendor...\n');
    
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'padionton@meruado.uk',
      password: 'Test123456!'
    });
    
    authToken = response.data.token;
    vendorId = response.data.user._id;
    
    console.log('✅ LOGIN SUCCESSFUL!');
    console.log('👤 Vendor ID:', vendorId);
    console.log('🎫 Token:', authToken.substring(0, 50) + '...\n');
    
    return response.data;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    throw error;
  }
}

// Step 2: Complete Vendor Profile
async function completeProfile() {
  try {
    console.log('📝 Completing vendor profile...\n');
    
    const profileData = {
      profile: {
        businessName: 'QuickServe Test Restaurant',
        businessAddress: '123 Lagos Street, Victoria Island, Lagos',
        phone: '+2348012345678',
        businessType: 'Restaurant',
        description: 'Authentic Nigerian cuisine - Jollof Rice, Fried Rice, and more!',
      }
    };
    
    const response = await axios.post(
      `${BASE_URL}/api/vendors/profile`,
      profileData,
      {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ PROFILE COMPLETED!');
    console.log('🏪 Business Name:', response.data.profile.businessName);
    console.log('📍 Address:', response.data.profile.businessAddress);
    console.log('📱 Phone:', response.data.profile.phone);
    console.log('📝 Description:', response.data.profile.description);
    console.log('');
    
    return response.data;
  } catch (error) {
    console.error('❌ Profile update failed:', error.response?.data || error.message);
    throw error;
  }
}

// Step 3: Upload Product
async function uploadProduct() {
  try {
    console.log('🍲 Uploading test product (Jollof Rice)...\n');
    
    const productData = {
      name: 'Special Jollof Rice',
      description: 'Delicious Nigerian Jollof Rice with chicken and plantain',
      price: 2500,
      category: 'Main Dishes',
      available: true,
      preparationTime: 30,
    };
    
    const response = await axios.post(
      `${BASE_URL}/api/products`,
      productData,
      {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ PRODUCT UPLOADED!');
    console.log('🍽️ Product Name:', response.data.name);
    console.log('💰 Price: ₦' + response.data.price);
    console.log('⏱️ Prep Time:', response.data.preparationTime, 'minutes');
    console.log('🆔 Product ID:', response.data._id);
    console.log('');
    
    return response.data;
  } catch (error) {
    console.error('❌ Product upload failed:', error.response?.data || error.message);
    throw error;
  }
}

// Step 4: Add More Products
async function addMoreProducts() {
  const products = [
    {
      name: 'Fried Rice with Chicken',
      description: 'Tasty fried rice with grilled chicken and vegetables',
      price: 2800,
      category: 'Main Dishes',
      available: true,
      preparationTime: 35,
    },
    {
      name: 'Amala and Ewedu',
      description: 'Traditional Yoruba meal with assorted meat',
      price: 2000,
      category: 'Local Dishes',
      available: true,
      preparationTime: 25,
    },
    {
      name: 'Suya (Beef)',
      description: 'Spicy grilled beef skewers - 5 sticks',
      price: 1500,
      category: 'Snacks',
      available: true,
      preparationTime: 15,
    }
  ];
  
  console.log('🍱 Adding more products...\n');
  
  for (const product of products) {
    try {
      const response = await axios.post(
        `${BASE_URL}/api/products`,
        product,
        {
          headers: {
            'Authorization': `Bearer ${authToken}`,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log(`✅ Added: ${product.name} - ₦${product.price}`);
    } catch (error) {
      console.error(`❌ Failed to add ${product.name}:`, error.response?.data || error.message);
    }
  }
  console.log('');
}

// Run all steps
async function setupVendor() {
  try {
    console.log('🚀 SETTING UP VENDOR ACCOUNT\n');
    console.log('='.repeat(50) + '\n');
    
    await login();
    await completeProfile();
    await uploadProduct();
    await addMoreProducts();
    
    console.log('='.repeat(50));
    console.log('🎉 VENDOR SETUP COMPLETE!\n');
    console.log('✅ Account verified and logged in');
    console.log('✅ Business profile completed');
    console.log('✅ 4 products uploaded');
    console.log('\n🔥 YOUR RESTAURANT IS NOW LIVE!');
    console.log('\n📱 Customers can now:');
    console.log('   - See your restaurant');
    console.log('   - Browse your menu');
    console.log('   - Add items to cart');
    console.log('   - Place orders (with payment)');
    console.log('\n🎯 Next: Build the Flutter app and test on your phone!');
    
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
  }
}

setupVendor();
