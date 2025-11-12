// ===============================
// FILE: models/Product.js
// ===============================
import mongoose from 'mongoose'

const ProductSchema = new mongoose.Schema({
  // ✅ Vendor who owns this product
  vendorId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Vendor', 
    required: true, 
    index: true 
  },

  // ✅ Product basics
  name: { type: String, required: true, trim: true },
  description: { type: String, default: '' },

  // ✅ Category and tags for filtering
  category: { type: String, default: 'general' },
  tags: { type: [String], default: [] },

  // ✅ Pricing and discounts
  price: { type: Number, required: true },
  discountPrice: { type: Number, default: 0 },

  // ✅ Inventory and stock management
  quantity: { type: Number, required: true, min: 0 },
  inStock: { type: Boolean, default: true },
  unit: { type: String, default: 'piece' }, // piece, plate, bowl, cup, bottle, pack, serving
  available: { type: Boolean, default: true }, // For event system availability toggle

  // ✅ Media
  imageUrl: { type: String },
  image: { type: String }, // For event system uploads
  gallery: { type: [String], default: [] },

  // ✅ Preparation time (for restaurants)
  prepDurationMins: { type: Number, default: 0 },

  // ✅ Product visibility and moderation
  isActive: { type: Boolean, default: true },
  isDeleted: { type: Boolean, default: false },
  approvedByAdmin: { type: Boolean, default: true },

  // ✅ Ratings
  averageRating: { type: Number, default: 0 },
  totalRatings: { type: Number, default: 0 },
  soldCount: { type: Number, default: 0 },

  // ✅ Analytics/meta info
  meta: {
    views: { type: Number, default: 0 },
    favorites: { type: Number, default: 0 },
  },

  // ✅ Automatic timestamps
}, { timestamps: true })

// =====================================
// ✳️ Virtual/computed field
// =====================================

// ✅ Automatically compute final price
ProductSchema.virtual('finalPrice').get(function () {
  if (this.discountPrice && this.discountPrice < this.price) {
    return this.discountPrice
  }
  return this.price
})

// ✅ Auto hide deleted products from find queries
ProductSchema.pre(/^find/, function (next) {
  this.where({ isDeleted: false })
  next()
})

// ✅ Auto update stock availability
ProductSchema.pre('save', function (next) {
  if (this.quantity <= 0) this.inStock = false
  next()
})

export default mongoose.model('Product', ProductSchema)
