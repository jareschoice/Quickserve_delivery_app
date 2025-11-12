// Test script to verify dispatcher registration endpoint
// Run this after creating an admin user: node backend/create-admin.js

import axios from 'axios';

const API_BASE = 'http://localhost:5555/api';

async function testDispatcherRegistration() {
  console.log('🧪 Testing Dispatcher Registration System\n');

  try {
    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const loginResponse = await axios.post(`${API_BASE}/auth/login`, {
      email: 'admin@quickserve.com',
      password: 'Admin123!'
    });

    const adminToken = loginResponse.data.token;
    console.log('✅ Admin login successful\n');

    // Step 2: Register a test dispatcher
    console.log('2️⃣ Registering test dispatcher...');
    const dispatcherData = {
      name: 'Test Dispatcher',
      email: `dispatcher${Date.now()}@quickserve.com`,
      password: 'dispatcher123',
      phone: '+234 800 123 4567'
    };

    const registerResponse = await axios.post(
      `${API_BASE}/admin/dispatchers`,
      dispatcherData,
      {
        headers: { Authorization: `Bearer ${adminToken}` }
      }
    );

    console.log('✅ Dispatcher registered successfully!');
    console.log('📋 Dispatcher Details:');
    console.log(`   Name: ${registerResponse.data.dispatcher.name}`);
    console.log(`   Email: ${registerResponse.data.dispatcher.email}`);
    console.log(`   Role: ${registerResponse.data.dispatcher.role}`);
    console.log(`   Phone: ${registerResponse.data.dispatcher.profile.phone}\n`);

    // Step 3: Verify dispatcher can login
    console.log('3️⃣ Testing dispatcher login...');
    const dispatcherLoginResponse = await axios.post(`${API_BASE}/auth/login`, {
      email: dispatcherData.email,
      password: dispatcherData.password
    });

    console.log('✅ Dispatcher login successful!');
    console.log(`   Token: ${dispatcherLoginResponse.data.token.substring(0, 20)}...\n`);

    // Step 4: Get all dispatchers
    console.log('4️⃣ Fetching all dispatchers...');
    const usersResponse = await axios.get(`${API_BASE}/admin/users`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    const allDispatchers = usersResponse.data.users.filter(u => u.role === 'dispatcher');
    console.log(`✅ Found ${allDispatchers.length} dispatcher(s) in the system\n`);

    // Step 5: Toggle dispatcher status
    console.log('5️⃣ Testing status toggle...');
    const dispatcherId = registerResponse.data.dispatcher._id;
    
    // Deactivate
    await axios.put(
      `${API_BASE}/admin/dispatchers/${dispatcherId}`,
      { isActive: false },
      {
        headers: { Authorization: `Bearer ${adminToken}` }
      }
    );
    console.log('✅ Dispatcher deactivated');

    // Reactivate
    await axios.put(
      `${API_BASE}/admin/dispatchers/${dispatcherId}`,
      { isActive: true },
      {
        headers: { Authorization: `Bearer ${adminToken}` }
      }
    );
    console.log('✅ Dispatcher reactivated\n');

    console.log('🎉 All tests passed! The dispatcher registration system is working correctly.');
    console.log('\n📱 You can now:');
    console.log('   1. Open admin panel: http://localhost:3000');
    console.log('   2. Login with admin credentials');
    console.log('   3. Navigate to "Dispatchers" in the sidebar');
    console.log('   4. Click "Add Dispatcher" to register new dispatchers');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    if (error.response?.status === 401) {
      console.log('\n💡 Tip: Make sure you have created an admin user first:');
      console.log('   Run: node backend/create-admin.js');
    }
  }
}

testDispatcherRegistration();
