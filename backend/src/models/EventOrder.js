import mongoose from 'mongoose';

const EventOrderSchema = new mongoose.Schema({
  // Consumer details (anonymous)
  phone: { type: String, required: true },
  seatNumber: { type: String, required: true },

  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  dispatcherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

  items: [{
    name: String,
    price: Number,
    qty: Number
  }],
  subtotal: Number,
  serviceCharge: { type: Number, default: 100 },
  total: Number,

  status: {
    type: String,
    enum: ['pending', 'accepted', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'],
    default: 'pending'
  },

  deliveryConfirmationToken: String,
  deliveryConfirmedAt: Date,

  payment: {
    reference: String,
    paid: { type: Boolean, default: false },
    channel: String,
    verifiedAt: Date,
  },
}, { timestamps: true });

export default mongoose.model('EventOrder', EventOrderSchema);
