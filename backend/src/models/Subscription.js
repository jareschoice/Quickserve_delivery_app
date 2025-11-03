import mongoose from 'mongoose'

const SubscriptionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  plan: { type: String, enum: ['basic','standard','premium'], required: true },
  amount: { type: Number, required: true }, // 25k, 50k, or 75k
  status: { type: String, enum: ['pending','active','paused','cancelled','expired'], default: 'pending' },
  autoRenew: { type: Boolean, default: true },
  
  // ✅ Enhanced: Multiple meal schedules per day
  mealSchedule: {
    breakfast: { 
      enabled: { type: Boolean, default: false },
      time: { type: String, default: '08:00' } // HH:mm format
    },
    lunch: { 
      enabled: { type: Boolean, default: false },
      time: { type: String, default: '13:00' }
    },
    dinner: { 
      enabled: { type: Boolean, default: false },
      time: { type: String, default: '19:00' }
    }
  },
  
  // Delivery address for this subscription
  deliveryAddress: { 
    type: String, 
    required: true 
  },
  
  // Period tracking
  periodStart: { type: Date },
  periodEnd: { type: Date },
  paymentRef: String,
  
  // ✅ Admin-managed: This subscription is fulfilled by QuickServe directly
  isAdminManaged: { type: Boolean, default: true },
  
  // Last delivery tracking to avoid duplicate notifications
  lastDeliveryDate: { type: Date },
  
}, { timestamps: true })

export default mongoose.model('Subscription', SubscriptionSchema)
