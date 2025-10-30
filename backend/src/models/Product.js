import mongoose from 'mongoose'

const ProductSchema = new mongoose.Schema({
  vendorId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true },
  description: { type: String },
  prepDurationMins: { type: Number },
  imageUrl: { type: String },
  active: { type: Boolean, default: true },
}, { timestamps: true })

export default mongoose.model('Product', ProductSchema)

