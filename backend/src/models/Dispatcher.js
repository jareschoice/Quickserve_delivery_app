// ===============================
// FILE: backend/src/models/Dispatcher.js
// Dispatcher model for ad-hoc delivery workers
// ===============================
import mongoose from "mongoose";

const DispatcherSchema = new mongoose.Schema(
  {
    // 🔹 Linked User (role='dispatcher')
    user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true, unique: true },

    // 🔹 Unique Dispatcher ID (e.g., DSP-001, DSP-002)
    dispatcherId: { type: String, unique: true, sparse: true }, // Generated on creation

    // 🔹 Profile Information
    name: { type: String, required: true }, // Real name
    phone: { type: String, required: true },
    photoUrl: String,
    
    // 🔹 Virtual Wallet (Service Fee Only: ₦70 per delivery)
    wallet: { type: Number, default: 0 }, // Total earnings from service fees
    totalDeliveries: { type: Number, default: 0 },
    
    // 🔹 Current Delivery Tracking
    currentDelivery: {
      orderId: { type: mongoose.Schema.Types.ObjectId, ref: "Order" },
      status: { 
        type: String, 
        enum: ['idle', 'assigned', 'picked_up', 'in_transit', 'arrived'],
        default: 'idle'
      },
      assignedAt: Date,
      pickedUpAt: Date,
      inTransitAt: Date,
      arrivedAt: Date
    },

    // 🔹 Location Tracking (for real-time GPS)
    location: {
      latitude: Number,
      longitude: Number,
      lastUpdated: Date
    },

    // 🔹 Availability
    isActive: { type: Boolean, default: true }, // Can receive new delivery requests
    isOnline: { type: Boolean, default: false }, // Currently logged in

    // 🔹 Performance Metrics
    completedDeliveries: { type: Number, default: 0 },
    cancelledDeliveries: { type: Number, default: 0 },
    averageRating: { type: Number, default: 0 },
    totalRatings: { type: Number, default: 0 },

    // 🔹 Event-specific
    eventId: { type: String }, // For multi-event support
    registeredBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" } // Admin who registered them
  },
  { timestamps: true }
);

// Pre-save hook to generate unique dispatcherId
DispatcherSchema.pre('save', async function(next) {
  if (!this.dispatcherId) {
    // Count existing dispatchers to generate next ID
    const count = await mongoose.model('Dispatcher').countDocuments();
    this.dispatcherId = `DSP-${String(count + 1).padStart(3, '0')}`; // DSP-001, DSP-002, etc.
  }
  next();
});

// Method to update location
DispatcherSchema.methods.updateLocation = function(lat, lng) {
  this.location = {
    latitude: lat,
    longitude: lng,
    lastUpdated: new Date()
  };
  return this.save();
};

// Method to assign delivery
DispatcherSchema.methods.assignDelivery = function(orderId) {
  this.currentDelivery = {
    orderId,
    status: 'assigned',
    assignedAt: new Date()
  };
  return this.save();
};

// Method to complete delivery and credit wallet
DispatcherSchema.methods.completeDelivery = async function() {
  const serviceFeePerDelivery = 70; // ₦70 per delivery
  this.wallet += serviceFeePerDelivery;
  this.totalDeliveries += 1;
  this.completedDeliveries += 1;
  this.currentDelivery = {
    orderId: null,
    status: 'idle'
  };
  return this.save();
};

export default mongoose.model("Dispatcher", DispatcherSchema);
