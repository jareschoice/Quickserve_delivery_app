// ===============================
// 🧪 QuickServe API Test Script
// ===============================
// Run with: node test-api.js

import axios from 'axios';

const BASE_URL = 'http://localhost:5555';
let vendorToken = '';
let userId = '';

// Colors for console output
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m',
  reset: '\x1b[0m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

function logTest(name) {
  console.log(`\n${'='.repeat(50)}`);
  log(`🧪 Testing: ${name}`, 'blue');
  console.log('='.repeat(50));
}

function logSuccess(message) {
  log(`✅ ${message}`, 'green');
}

function logError(message) {
  log(`❌ ${message}`, 'red');
}

function logWarning(message) {
  log(`⚠️  ${message}`, 'yellow');
}

// ===============================
// Test 1: Health Check
// ===============================
async function testHealthCheck() {
  logTest('Health Check');
  try {
    const response = await axios.get(`${BASE_URL}/`);
    logSuccess('Server is running!');
    console.log(JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    logError('Health check failed!');
    console.error(error.message);
    return false;
  }
}

// ===============================
// Test 2: Register Vendor
// ===============================
async function testRegisterVendor() {
  logTest('Register Vendor');
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/register`, {
      name: 'Test Vendor',
      email: `vendor${Date.now()}@test.com`, // Unique email each time
      password: 'password123',
      role: 'vendor'
    });
    
    vendorToken = response.data.token;
    userId = response.data.user.id;
    
    logSuccess('Vendor registered successfully!');
    console.log(`User ID: ${userId}`);
    console.log(`Token: ${vendorToken.substring(0, 20)}...`);
    return true;
  } catch (error) {
    logError('Registration failed!');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// ===============================
// Test 3: Create Vendor Profile
// ===============================
async function testCreateVendorProfile() {
  logTest('Create Vendor Profile');
  try {
    const response = await axios.post(
      `${BASE_URL}/api/vendors/profile`,
      {
        storeName: 'Test Restaurant'
      },
      {
        headers: {
          'Authorization': `Bearer ${vendorToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    logSuccess('Vendor profile created!');
    console.log(JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    logError('Profile creation failed!');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// ===============================
// Test 4: Submit KYC (The Fixed Feature!)
// ===============================
async function testSubmitKYC() {
  logTest('Submit KYC (The Feature You Just Fixed!)');
  try {
    const response = await axios.post(
      `${BASE_URL}/api/kyc/submit`,
      {
        idUrl: 'https://example.com/government-id.jpg',
        utilityBillUrl: 'https://example.com/utility-bill.pdf',
        bankName: 'GTBank',
        accountNumber: '0123456789'
      },
      {
        headers: {
          'Authorization': `Bearer ${vendorToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    logSuccess('KYC submitted successfully!');
    console.log(JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    logError('KYC submission failed!');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// ===============================
// Test 5: Get KYC Status
// ===============================
async function testGetKYCStatus() {
  logTest('Get KYC Status');
  try {
    const response = await axios.get(
      `${BASE_URL}/api/kyc/status`,
      {
        headers: {
          'Authorization': `Bearer ${vendorToken}`
        }
      }
    );
    
    logSuccess('KYC status retrieved!');
    console.log(JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    logError('KYC status check failed!');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// ===============================
// Test 6: Get Vendor Profile
// ===============================
async function testGetVendorProfile() {
  logTest('Get Vendor Profile');
  try {
    const response = await axios.get(
      `${BASE_URL}/api/vendors/me`,
      {
        headers: {
          'Authorization': `Bearer ${vendorToken}`
        }
      }
    );
    
    logSuccess('Vendor profile retrieved!');
    console.log(JSON.stringify(response.data, null, 2));
    return true;
  } catch (error) {
    logError('Profile retrieval failed!');
    console.error(error.response?.data || error.message);
    return false;
  }
}

// ===============================
// Run All Tests
// ===============================
async function runAllTests() {
  console.log('\n');
  log('🚀 QuickServe API Test Suite', 'blue');
  log('================================\n', 'blue');
  
  const results = {
    passed: 0,
    failed: 0
  };
  
  // Test 1: Health Check
  if (await testHealthCheck()) {
    results.passed++;
  } else {
    results.failed++;
    logWarning('Server might not be running. Start it with: npm run dev');
    return;
  }
  
  // Test 2: Register Vendor
  if (await testRegisterVendor()) {
    results.passed++;
  } else {
    results.failed++;
    logWarning('Cannot continue without authentication token');
    return;
  }
  
  // Test 3: Create Vendor Profile
  if (await testCreateVendorProfile()) {
    results.passed++;
  } else {
    results.failed++;
  }
  
  // Test 4: Submit KYC
  if (await testSubmitKYC()) {
    results.passed++;
  } else {
    results.failed++;
  }
  
  // Test 5: Get KYC Status
  if (await testGetKYCStatus()) {
    results.passed++;
  } else {
    results.failed++;
  }
  
  // Test 6: Get Vendor Profile
  if (await testGetVendorProfile()) {
    results.passed++;
  } else {
    results.failed++;
  }
  
  // Summary
  console.log('\n' + '='.repeat(50));
  log('📊 Test Summary', 'blue');
  console.log('='.repeat(50));
  logSuccess(`Passed: ${results.passed}`);
  if (results.failed > 0) {
    logError(`Failed: ${results.failed}`);
  }
  log(`Total: ${results.passed + results.failed}`, 'yellow');
  console.log('='.repeat(50) + '\n');
  
  if (results.failed === 0) {
    log('🎉 All tests passed! Your backend is working perfectly!', 'green');
  } else {
    logWarning('Some tests failed. Check the errors above.');
  }
}

// Run the tests
runAllTests().catch(error => {
  logError('Test suite crashed!');
  console.error(error);
  process.exit(1);
});
