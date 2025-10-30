import mongoose from 'mongoose'
import bcrypt from 'bcryptjs'

const ProfileSchema = new mongoose.Schema({
  // flexible per role
  phone: String,
  address: String,

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
  role: {
    type: String,
    enum: ['customer', 'vendor', 'rider', 'admin'],
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

  profile: ProfileSchema,

  // Wallet and finance
  wallet: { type: Number, default: 0 },
  currency: { type: String, default: 'NGN' },

  // KYC
  kycStatus: { type: String, enum: ['none','pending','approved','rejected'], default: 'none' },
  kycMeta: { type: Object },
  kycReviewedAt: { type: Date },

}, { timestamps: true })

UserSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next()
  const salt = await bcrypt.genSalt(10)
  this.password = await bcrypt.hash(this.password, salt)
  next()
})

UserSchema.methods.comparePassword = async function(candidate) {
  return bcrypt.compare(candidate, this.password)
}

export default mongoose.model('User', UserSchema)
