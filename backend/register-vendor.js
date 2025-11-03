import axios from 'axios';

const BASE_URL = 'http://localhost:5555';

async function registerVendor() {
  try {
    console.log('🚀 Registering vendor account...\n');
    
    const vendorData = {
      name: 'QuickServe Test Vendor',
      email: 'padionton@meruado.uk',
      password: 'Test123456!',
      phone: '+2348012345678',
      role: 'vendor'
    };

    const response = await axios.post(`${BASE_URL}/api/auth/register`, vendorData);
    
    console.log('✅ VENDOR REGISTERED SUCCESSFULLY!\n');
    console.log('📧 Email:', vendorData.email);
    console.log('🔑 Password:', vendorData.password);
    console.log('📱 Phone:', vendorData.phone);
    console.log('\n🔗 Vendor ID:', response.data.user?._id);
    console.log('🎫 Auth Token:', response.data.token?.substring(0, 50) + '...');
    
    console.log('\n⏳ CHECK YOUR EMAIL NOW for verification link!');
    console.log('📬 Email sent to: padionton@meruado.uk');
    console.log('\n📝 After verifying, tell me and I\'ll login and complete the business profile!');
    
    return response.data;
  } catch (error) {
    if (error.response) {
      console.error('❌ Registration failed:', error.response.data.message);
      if (error.response.data.message.includes('already exists')) {
        console.log('\n✅ Account already exists! That\'s fine.');
        console.log('📧 Email: padionton@meruado.uk');
        console.log('🔑 Password: Test123456!');
        console.log('\n🔗 If you need to verify, check your email for the verification link!');
      }
    } else {
      console.error('❌ Error:', error.message);
      console.error('🔌 Is the backend server running? Start it with: npm run dev');
    }
  }
}

registerVendor();
