import mongoose from 'mongoose';

const kycSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true, // each user has one KYC record
    },
    idUrl: {
      type: String,
      required: [true, 'Government ID is required'],
    },
    utilityBillUrl: {
      type: String,
      required: [true, 'Utility bill is required'],
    },
    bankName: {
      type: String,
      required: [true, 'Bank name is required'],
    },
    accountNumber: {
      type: String,
      required: [true, 'Account number is required'],
    },
    status: {
      type: String,
      enum: ['pending', 'verified', 'rejected'],
      default: 'pending',
    },
    remarks: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

export default mongoose.model('Kyc', kycSchema);
