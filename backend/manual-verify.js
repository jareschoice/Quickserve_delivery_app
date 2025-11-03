import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

// Import User model
const userSchema = new mongoose.Schema({
  email: String,
  verifyToken: String,
  isVerified: Boolean,
}, { collection: 'users', strict: false });

const User = mongoose.model('User', userSchema);

async function manuallyVerifyEmail() {
  try {
    console.log('🔍 Connecting to MongoDB...\n');
    await mongoose.connect(process.env.MONGO_URI);
    
    const email = 'padionton@meruado.uk';
    const user = await User.findOne({ email });
    
    if (!user) {
      console.log('❌ User not found!');
      console.log('📧 Email:', email);
      process.exit(1);
    }
    
    console.log('✅ User found!\n');
    console.log('📧 Email:', user.email);
    console.log('✔️ Email Verified (before):', user.isVerified);
    
    // Manually verify the user
    user.isVerified = true;
    user.verifyToken = undefined;
    user.verifyTokenExpires = undefined;
    await user.save();
    
    console.log('✔️ Email Verified (after):', true);
    console.log('\n🎉 EMAIL MANUALLY VERIFIED!');
    console.log('\n✅ You can now login with:');
    console.log('   Email: padionton@meruado.uk');
    console.log('   Password: Test123456!');
    console.log('\n🚀 Ready to complete business profile and upload products!\n');
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

manuallyVerifyEmail();
