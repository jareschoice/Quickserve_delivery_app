// List all test accounts for testing
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

const UserSchema = new mongoose.Schema({
  name: String,
  email: String,
  role: String,
  phone: String,
  profile: Object
}, { timestamps: true });

const DispatcherSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  dispatcherId: String,
  name: String,
  phone: String,
  isAvailable: Boolean
}, { timestamps: true });

const User = mongoose.model('User', UserSchema);
const Dispatcher = mongoose.model('Dispatcher', DispatcherSchema);

async function listAccounts() {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');

    // List vendors
    console.log('📦 TEST VENDORS:');
    console.log('================');
    const vendors = await User.find({ role: 'vendor' }).select('name email phone profile').lean();
    vendors.forEach((v, i) => {
      console.log(`${i + 1}. ${v.profile?.businessName || v.name}`);
      console.log(`   Email: ${v.email}`);
      console.log(`   Password: password123`);
      console.log(`   Phone: ${v.phone || v.profile?.phone || 'N/A'}`);
      console.log('');
    });

    // List dispatchers
    console.log('\n🏍️ TEST DISPATCHERS:');
    console.log('==================');
    const dispatchers = await Dispatcher.find().populate('user', 'email name phone').lean();
    dispatchers.forEach((d, i) => {
      console.log(`${i + 1}. ${d.name} (${d.dispatcherId})`);
      console.log(`   Email: ${d.user?.email || 'N/A'}`);
      console.log(`   Password: dispatcher123`);
      console.log(`   Phone: ${d.phone}`);
      console.log(`   Available: ${d.isAvailable ? '✅ Yes' : '❌ No'}`);
      console.log('');
    });

    // List admins
    console.log('\n👨‍💼 ADMIN ACCOUNTS:');
    console.log('=================');
    const admins = await User.find({ role: 'admin' }).select('name email').lean();
    admins.forEach((a, i) => {
      console.log(`${i + 1}. ${a.name}`);
      console.log(`   Email: ${a.email}`);
      console.log(`   Password: (check creation script)`);
      console.log('');
    });

    console.log('\n💡 LOGIN URLs:');
    console.log('==============');
    console.log('Vendor Dashboard: http://localhost:5555/vendor-dashboard.html');
    console.log('Dispatcher Dashboard: http://localhost:5555/dispatcher.html');
    console.log('Admin Dashboard: http://localhost:5555/admin.html');
    console.log('Customer Shopping: http://localhost:5555/home.html');
    
    await mongoose.disconnect();
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

listAccounts();
