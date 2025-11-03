// ===============================
// FILE: backend/src/models/PendingOrder.js
// PURPOSE: Store order details during payment processing
// ===============================
import mongoose from 'mongoose'

const PendingOrderSchema = new mongoose.Schema({
  consumerId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  vendorId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  items: [{
    productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
    name: { type: String, required: true },
    price: { type: Number, required: true },
    qty: { type: Number, required: true, min: 1 }
  }],
  subtotal: { type: Number, required: true },
  deliveryFee: { type: Number, required: true, default: 0 },
  platformFee: { type: Number, required: true, default: 0 },
  total: { type: Number, required: true },
  deliveryAddress: { type: String, required: true },
  notes: String,
  packagingChoice: String,
  packagingNotes: String,
  distanceKm: Number,
  
  // Payment tracking
  paymentReference: { type: String, required: true, unique: true },
  paymentStatus: { 
    type: String, 
    enum: ['pending', 'paid', 'failed', 'cancelled'],
    default: 'pending'
  },
  
  // Expiration (pending orders expire after 1 hour)
  expiresAt: { 
    type: Date, 
    default: () => new Date(Date.now() + 60 * 60 * 1000),
    index: { expires: 0 } // TTL index - MongoDB auto-deletes expired docs
  }
}, { 
  timestamps: true 
})

// Index for fast lookups (paymentReference already has unique: true, no need for separate index)
PendingOrderSchema.index({ consumerId: 1, createdAt: -1 })

export default mongoose.model('PendingOrder', PendingOrderSchema)
