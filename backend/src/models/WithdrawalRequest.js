// ===============================
// FILE: backend/src/models/WithdrawalRequest.js
// ===============================
import mongoose from 'mongoose'

const WithdrawalSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }, // who requested
  amount: { type: Number, required: true },
  currency: { type: String, default: 'NGN' },
  method: { type: String, default: 'bank' }, // bank, paystack_transfer, etc.
  meta: { type: Object }, // bank details, notes
  status: { type: String, enum: ['pending','approved','rejected','paid'], default: 'pending' },
  processedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // admin who processed
  processedAt: Date,
  requestedAt: { type: Date, default: Date.now },
  note: String
}, { timestamps: true })

export default mongoose.model('WithdrawalRequest', WithdrawalSchema)
