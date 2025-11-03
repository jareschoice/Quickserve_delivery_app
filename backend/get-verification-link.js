import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config();

// Import User model
const userSchema = new mongoose.Schema({
  email: String,
  verifyToken: String,
  isEmailVerified: Boolean,
}, { collection: 'users' });

const User = mongoose.model('User', userSchema);

async function getVerificationLink() {
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
    console.log('✔️ Email Verified:', user.isEmailVerified);
    console.log('🔑 Verification Token:', user.verifyToken);
    
    if (user.isEmailVerified) {
      console.log('\n🎉 EMAIL ALREADY VERIFIED! You can login now!');
    } else if (user.verifyToken) {
      const verificationLink = `http://192.168.100.104:5555/api/auth/verify-email?token=${user.verifyToken}`;
      console.log('\n🔗 VERIFICATION LINK:');
      console.log(verificationLink);
      console.log('\n📱 CLICK THIS LINK ON YOUR PHONE:');
      console.log(verificationLink);
      console.log('\nOR open in browser and click the link!\n');
    } else {
      console.log('\n⚠️ No verification token found. Email might already be verified or needs to be resent.');
    }
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

getVerificationLink();
