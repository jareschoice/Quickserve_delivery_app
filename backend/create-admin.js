import mongoose from 'mongoose';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';

dotenv.config();

async function createAdminUser() {
  try {
    console.log('🔍 Connecting to MongoDB...\n');
    await mongoose.connect(process.env.MONGO_URI);
    
    // Define User schema
    const UserSchema = new mongoose.Schema({
      role: String,
      name: String,
      email: String,
      password: String,
      isVerified: Boolean,
      wallet: Number,
      currency: String,
      kycStatus: String,
      profile: Object,
    }, { timestamps: true, collection: 'users' });

    const User = mongoose.model('User', UserSchema);
    
    // Check if admin already exists
    const existingAdmin = await User.findOne({ email: 'admin@quickserve.com' });
    
    if (existingAdmin) {
      console.log('⚠️  Admin user already exists!');
      console.log('📧 Email: admin@quickserve.com');
      console.log('🔑 Password: Admin123!');
      console.log('\n✅ You can login to the admin panel with these credentials.');
      await mongoose.connection.close();
      return;
    }
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash('Admin123!', salt);
    
    // Create admin user
    const admin = await User.create({
      role: 'admin',
      name: 'QuickServe Admin',
      email: 'admin@quickserve.com',
      password: hashedPassword,
      isVerified: true,
      wallet: 0,
      currency: 'NGN',
      kycStatus: 'approved',
      profile: {}
    });
    
    console.log('✅ ADMIN USER CREATED SUCCESSFULLY!\n');
    console.log('👤 Name: QuickServe Admin');
    console.log('📧 Email: admin@quickserve.com');
    console.log('🔑 Password: Admin123!');
    console.log('🆔 Admin ID:', admin._id);
    console.log('\n🔐 IMPORTANT: Change the password after first login!');
    console.log('\n🌐 Access the admin panel at: http://localhost:3000');
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

createAdminUser();
