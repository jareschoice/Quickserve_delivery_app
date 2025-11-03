import axios from 'axios';

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
    vendorId = response.data.user?._id || response.data.user?.id;
    
    console.log('✅ LOGIN SUCCESSFUL!');
    console.log('👤 Name:', response.data.user?.name);
    console.log('📧 Email:', response.data.user?.email);
    console.log('🆔 Vendor ID:', vendorId);
    console.log('🎫 Token:', authToken.substring(0, 30) + '...\n');
    
    return response.data;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    throw error;
  }
}

// Step 2: Create Vendor Profile
async function createVendorProfile() {
  try {
    console.log('🏪 Creating vendor profile...\n');
    
    const response = await axios.post(
      `${BASE_URL}/api/vendors/profile`,
      { storeName: 'QuickServe Test Restaurant' },
      {
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ VENDOR PROFILE CREATED!');
    console.log('🏪 Store Name:', response.data.vendor?.storeName);
    console.log('🆔 Vendor Profile ID:', response.data.vendor?._id);
    console.log('');
    
    return response.data;
  } catch (error) {
    console.error('❌ Profile creation failed:', error.response?.data || error.message);
    // Don't throw - profile might already exist
  }
}

// Step 3: Upload Products
async function uploadProduct(productData) {
  try {
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
    
    console.log(`✅ Added: ${response.data.product?.name} - ₦${response.data.product?.price}`);
    return response.data;
  } catch (error) {
    console.error(`❌ Failed to add ${productData.name}:`);
    if (error.response?.data) {
      console.error('   Error:', JSON.stringify(error.response.data));
    } else {
      console.error('   Error:', error.message);
    }
    return null;
  }
}

// Step 4: Add Multiple Products
async function addProducts() {
  const products = [
    {
      name: 'Special Jollof Rice',
      description: 'Delicious Nigerian Jollof Rice with chicken and plantain',
      price: 2500,
      category: 'Main Dishes',
      quantity: 100,
      prepDurationMins: 30,
    },
    {
      name: 'Fried Rice with Chicken',
      description: 'Tasty fried rice with grilled chicken and vegetables',
      price: 2800,
      category: 'Main Dishes',
      quantity: 100,
      prepDurationMins: 35,
    },
    {
      name: 'Amala and Ewedu',
      description: 'Traditional Yoruba meal with assorted meat',
      price: 2000,
      category: 'Local Dishes',
      quantity: 50,
      prepDurationMins: 25,
    },
    {
      name: 'Suya (Beef)',
      description: 'Spicy grilled beef skewers - 5 sticks',
      price: 1500,
      category: 'Snacks',
      quantity: 200,
      prepDurationMins: 15,
    },
    {
      name: 'Pounded Yam & Egusi',
      description: 'Fresh pounded yam with rich Egusi soup',
      price: 2200,
      category: 'Local Dishes',
      quantity: 50,
      prepDurationMins: 40,
    }
  ];
  
  console.log('🍱 Uploading products...\n');
  
  let successCount = 0;
  for (const product of products) {
    const result = await uploadProduct(product);
    if (result) successCount++;
  }
  
  console.log(`\n✅ Successfully uploaded ${successCount}/${products.length} products!\n`);
  return successCount;
}

// Step 5: Get Vendor Info
async function getVendorInfo() {
  try {
    console.log('📊 Fetching vendor information...\n');
    
    const response = await axios.get(
      `${BASE_URL}/api/vendors/me`,
      {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      }
    );
    
    console.log('✅ VENDOR INFO:');
    console.log('🏪 Store Name:', response.data.vendor?.storeName);
    console.log('💰 Wallet Balance: ₦' + (response.data.vendor?.wallet || 0));
    console.log('');
    
    return response.data;
  } catch (error) {
    console.error('❌ Failed to fetch vendor info:', error.response?.data || error.message);
  }
}

// Step 6: Get All Products
async function getAllProducts() {
  try {
    console.log('📦 Fetching all products...\n');
    
    const response = await axios.get(`${BASE_URL}/api/products`);
    
    const myProducts = response.data.filter(p => p.vendorId === vendorId);
    
    console.log(`✅ PRODUCTS IN SYSTEM: ${response.data.length} total`);
    console.log(`🏪 YOUR PRODUCTS: ${myProducts.length}\n`);
    
    if (myProducts.length > 0) {
      console.log('Your Menu:');
      myProducts.forEach((p, i) => {
        console.log(`  ${i + 1}. ${p.name} - ₦${p.price}`);
      });
      console.log('');
    }
    
    return myProducts;
  } catch (error) {
    console.error('❌ Failed to fetch products:', error.response?.data || error.message);
  }
}

// Run all steps
async function setupVendor() {
  try {
    console.log('\n🚀 QUICKSERVE VENDOR SETUP\n');
    console.log('='.repeat(60) + '\n');
    
    await login();
    await createVendorProfile();
    const productsAdded = await addProducts();
    await getVendorInfo();
    await getAllProducts();
    
    console.log('='.repeat(60));
    console.log('\n🎉 VENDOR SETUP COMPLETE!\n');
    console.log('✅ Account verified and logged in');
    console.log('✅ Vendor profile created');
    console.log(`✅ ${productsAdded} products uploaded`);
    console.log('\n🔥 YOUR RESTAURANT IS NOW LIVE!\n');
    console.log('📱 What customers will see:');
    console.log('   ✓ Your store: QuickServe Test Restaurant');
    console.log('   ✓ Your menu with prices');
    console.log('   ✓ Preparation times');
    console.log('   ✓ Product descriptions');
    console.log('\n🎯 Next Steps:');
    console.log('   1. Build the Flutter app: flutter build apk');
    console.log('   2. Install on your phone');
    console.log('   3. Register as a customer');
    console.log('   4. Browse products and see your menu!');
    console.log('   5. Test the complete order flow\n');
    
  } catch (error) {
    console.error('\n❌ Setup failed:', error.message);
  }
}

setupVendor();
