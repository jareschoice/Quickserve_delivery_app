// models/User.js
import mongoose from 'mongoose'
import bcrypt from 'bcryptjs'
import crypto from 'crypto'

const ProfileSchema = new mongoose.Schema({
  // flexible per role
  phone: String,
  address: String,
  seatNumber: String, // For event attendees

  // Vendor
  businessName: String,
  businessAddress: String,
  logoUrl: String,

  // Rider
  vehicleType: String,
  plateNumber: String,
  idUrl: String,
  licenseUrl: String,
}, { _id: false })

const UserSchema = new mongoose.Schema({
  // ✅ Role-based access
  role: {
    type: String,
    enum: ['customer', 'vendor', 'rider', 'admin', 'dispatcher'],
    required: true,
    index: true
  },

  email: { type: String, required: true, unique: true, lowercase: true, index: true },
  password: { type: String, required: true, select: false },
  name: { type: String, required: true },

  isVerified: { type: Boolean, default: false },

  verifyToken: { type: String, index: true },
  verifyTokenExpires: { type: Date },

  // OTP verification for mobile apps
  otp: { type: String },
  otpExpires: { type: Date },

  // Password reset tokens
  resetPasswordToken: { type: String },
  resetPasswordExpires: { type: Date },

  profile: ProfileSchema,

  // Unique ID fields for vendors and dispatchers
  dispatcherId: { type: String, sparse: true, unique: true, index: true }, // DIS-0001, DIS-0002, etc.
  
  // Status flags
  isActive: { type: Boolean, default: true },

  // Wallet and finance
  wallet: { type: Number, default: 0 },
  currency: { type: String, default: 'NGN' },

  // KYC
  kycStatus: { type: String, enum: ['none','pending','approved','rejected'], default: 'none' },
  kycMeta: { type: Object },
  kycReviewedAt: { type: Date },
}, { timestamps: true })

// ✅ Encrypt password before saving
UserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next()
  const salt = await bcrypt.genSalt(10)
  this.password = await bcrypt.hash(this.password, salt)
  next()
})

// ✅ Token for email verification
UserSchema.methods.createVerifyToken = function() {
  const verifyToken = crypto.randomBytes(32).toString('hex');
  this.verifyToken = crypto.createHash('sha256').update(verifyToken).digest('hex');
  this.verifyTokenExpires = Date.now() + 10 * 60 * 1000; // 10 minutes
  return verifyToken;
};

// ✅ Compare password
UserSchema.methods.comparePassword = async function(candidate) {
  return bcrypt.compare(candidate, this.password)
}

export default mongoose.model('User', UserSchema)
