import mongoose from 'mongoose'

const OrderSchema = new mongoose.Schema({
  consumerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  riderId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  items: [{
    name: String,
    price: Number,
    qty: Number
  }],
  subtotal: Number,
  deliveryFee: Number,
  platformFee: Number,
  total: Number,
  status: { 
    type: String, 
    enum: ['placed','accepted','preparing','waiting_pickup','ready','dispatch_requested','assigned','in_transit','arrived_customer','delivered','cancelled'],
    default: 'placed'
  },
  qrConsumerToken: String,
  qrRiderToken: String,
  qrConsumerVerifiedAt: Date,
  qrRiderVerifiedAt: Date,
  qrTokenExpiresAt: Date,
  distanceKm: Number,
  deliveryAddress: String,
  notes: String,
  payment: {
    reference: String,
    paid: { type: Boolean, default: false },
    channel: String,
    verifiedAt: Date,
  },
  packagingChoice: String,
  packagingNotes: String
}, { timestamps: true })

export default mongoose.model('Order', OrderSchema)
