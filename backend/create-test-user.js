// Quick script to create a verified test user
import 'dotenv/config'
import './src/config/db.js'
import User from './src/models/User.js'

async function createTestUser() {
  try {
    // Delete existing test user if any
    await User.deleteOne({ email: 'test@test.com' })
    
    // Create new verified test user
    const user = new User({
      name: 'Test User',
      email: 'test@test.com',
      password: 'password123',
      role: 'customer',
      isVerified: true
    })
    
    await user.save()
    console.log('✅ Test user created and verified:', user.email)
    
    // Also create a user with your Gmail
    await User.deleteOne({ email: 'youremail@gmail.com' })
    const gmailUser = new User({
      name: 'Your Name',
      email: 'youremail@gmail.com', // Replace with your actual Gmail
      password: 'password123',
      role: 'customer',
      isVerified: true
    })
    
    await gmailUser.save()
    console.log('✅ Gmail user created and verified:', gmailUser.email)
    
    process.exit(0)
  } catch (error) {
    console.error('❌ Error creating test users:', error)
    process.exit(1)
  }
}

createTestUser()