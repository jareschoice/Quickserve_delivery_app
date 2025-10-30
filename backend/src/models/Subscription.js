import mongoose from 'mongoose'

const SubscriptionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  plan: { type: String, enum: ['basic','standard','premium'], required: true },
  amount: { type: Number, required: true },
  status: { type: String, enum: ['pending','active','paused','cancelled','expired'], default: 'pending' },
  autoRenew: { type: Boolean, default: true },
  deliveryTimeDaily: { type: String, default: '12:00' }, // HH:mm local time
  periodStart: { type: Date },
  periodEnd: { type: Date },
  paymentRef: String,
}, { timestamps: true })

export default mongoose.model('Subscription', SubscriptionSchema)
