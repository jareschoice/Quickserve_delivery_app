// Setup Test Dispatchers for AutofestXTradeExpo Event
// Run: node setup-test-dispatchers.js

import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

// Import Models
const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String },
  role: { type: String, enum: ['customer', 'vendor', 'dispatcher', 'admin'], default: 'customer' },
  isEmailVerified: { type: Boolean, default: false },
  emailVerificationToken: String,
  emailVerificationExpires: Date
}, { timestamps: true });

const DispatcherSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  dispatcherId: { type: String, unique: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  photoUrl: { type: String },
  
  // Wallet System (Virtual - Read-only)
  wallet: {
    totalEarnings: { type: Number, default: 0 },
    completedDeliveries: { type: Number, default: 0 },
    pendingEarnings: { type: Number, default: 0 }
  },
  
  // Delivery Status
  isAvailable: { type: Boolean, default: true },
  currentDelivery: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  
  // Real-time Location (for GPS tracking)
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: [0, 0] }, // [longitude, latitude]
    lastUpdated: { type: Date }
  },
  
  // Performance Metrics
  rating: { type: Number, default: 0, min: 0, max: 5 },
  totalRatings: { type: Number, default: 0 }
}, { timestamps: true });

// Auto-generate dispatcherId (DSP-001, DSP-002, etc.)
DispatcherSchema.pre('save', async function(next) {
  if (!this.dispatcherId) {
    const count = await mongoose.model('Dispatcher').countDocuments();
    this.dispatcherId = `DSP-${String(count + 1).padStart(3, '0')}`;
  }
  next();
});

DispatcherSchema.index({ location: '2dsphere' });

const User = mongoose.model('User', UserSchema);
const Dispatcher = mongoose.model('Dispatcher', DispatcherSchema);

// Test Dispatchers Data
const dispatchers = [
  { name: 'Chidi Okeke', email: 'dispatcher1@quickserve.test', phone: '08012345671' },
  { name: 'Fatima Hassan', email: 'dispatcher2@quickserve.test', phone: '08012345672' },
  { name: 'Emeka Nwosu', email: 'dispatcher3@quickserve.test', phone: '08012345673' },
  { name: 'Aisha Bello', email: 'dispatcher4@quickserve.test', phone: '08012345674' },
  { name: 'Tunde Adeyemi', email: 'dispatcher5@quickserve.test', phone: '08012345675' },
  { name: 'Ngozi Okafor', email: 'dispatcher6@quickserve.test', phone: '08012345676' },
  { name: 'Yusuf Ibrahim', email: 'dispatcher7@quickserve.test', phone: '08012345677' },
  { name: 'Blessing Chioma', email: 'dispatcher8@quickserve.test', phone: '08012345678' },
  { name: 'Segun Oladipo', email: 'dispatcher9@quickserve.test', phone: '08012345679' },
  { name: 'Amina Suleiman', email: 'dispatcher10@quickserve.test', phone: '08012345680' }
];

async function setupTestDispatchers() {
  try {
    console.log('✅ Connecting to MongoDB...\n');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB\n');
    
    console.log('🚀 Creating 10 ad-hoc dispatchers for AutofestXTradeExpo...\n');
    
    // Clear existing test dispatchers
    await User.deleteMany({ email: { $regex: 'dispatcher\\d+@quickserve\\.test' } });
    await Dispatcher.deleteMany({});
    console.log('🧹 Cleared existing test dispatchers\n');
    
    const password = 'dispatcher123';
    const hashedPassword = await bcrypt.hash(password, 10);
    
    for (const dispatcherData of dispatchers) {
      // Create User account
      const user = await User.create({
        name: dispatcherData.name,
        email: dispatcherData.email,
        password: hashedPassword,
        phone: dispatcherData.phone,
        role: 'dispatcher',
        isEmailVerified: true
      });
      
      console.log(`✅ Created user: ${dispatcherData.email}`);
      
      // Create Dispatcher profile (dispatcherId auto-generated)
      const dispatcher = await Dispatcher.create({
        user: user._id,
        name: dispatcherData.name,
        phone: dispatcherData.phone,
        isAvailable: true,
        location: {
          type: 'Point',
          coordinates: [3.3792, 6.5244], // Lagos coordinates (default)
          lastUpdated: new Date()
        }
      });
      
      console.log(`✅ Created dispatcher: ${dispatcher.name} (${dispatcher.dispatcherId})\n`);
    }
    
    console.log('\n✅ Test dispatcher setup complete!\n');
    console.log('📋 Login Credentials:');
    console.log('─────────────────────────────────────────');
    
    dispatchers.forEach((d, i) => {
      console.log(`${d.name} (DSP-${String(i + 1).padStart(3, '0')}):`);
      console.log(`  Email: ${d.email}`);
      console.log(`  Password: ${password}\n`);
    });
    
    console.log('📱 All dispatchers are marked as available for delivery assignments!');
    console.log('💰 Service Fee: ₦70 per delivery (virtual wallet - admin pays manually post-event)');
    console.log('📍 Default Location: Lagos (can be updated via GPS)');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    console.log('\n✅ Database connection closed');
    await mongoose.connection.close();
    process.exit(0);
  }
}

setupTestDispatchers();
