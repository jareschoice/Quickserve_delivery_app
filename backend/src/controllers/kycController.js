import Kyc from '../models/Kyc.js';
import User from '../models/User.js';
// 📍 PLACE THIS BELOW YOUR EXISTING IMPORTS
import Vendor from "../models/Vendor.js";
import { createTransferRecipient } from "../utils/paystack.js";


// =====================================
// ✳️ SUBMIT or UPDATE KYC
// =====================================
export const submitKyc = async (req, res) => {
  try {
    const { idUrl, utilityBillUrl, bankName, accountNumber } = req.body;
    const userId = req.user?._id;

    if (!userId)
      return res.status(401).json({ error: 'Unauthorized: Missing user info' });

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ error: 'User not found' });

    let kyc = await Kyc.findOne({ user: userId });

    if (kyc) {
      // Update existing KYC record
      kyc.idUrl = idUrl || kyc.idUrl;
      kyc.utilityBillUrl = utilityBillUrl || kyc.utilityBillUrl;
      kyc.bankName = bankName || kyc.bankName;
      kyc.accountNumber = accountNumber || kyc.accountNumber;
      kyc.status = 'pending';
      await kyc.save();
    } else {
      // Create new KYC record
      kyc = await Kyc.create({
        user: userId,
        idUrl,
        utilityBillUrl,
        bankName,
        accountNumber,
        status: 'pending',
      });
    }

    res.json({
      success: true,
      message: 'KYC submitted successfully',
      kyc,
    });
  } catch (err) {
    console.error('❌ submitKyc error:', err);
    res.status(500).json({ error: 'Failed to submit KYC', details: err.message });
  }
};

// =====================================
// ✳️ GET KYC STATUS
// =====================================
export const getKycStatus = async (req, res) => {
  try {
    const userId = req.user?._id;
    const kyc = await Kyc.findOne({ user: userId });

    if (!kyc)
      return res.status(404).json({ error: 'KYC record not found' });

    res.json({
      success: true,
      status: kyc.status,
      remarks: kyc.remarks,
      kyc,
    });
  } catch (err) {
    console.error('❌ getKycStatus error:', err);
    res.status(500).json({ error: 'Failed to fetch KYC status' });
  }
};

// =====================================
// ✳️ ADMIN VERIFY / REJECT KYC
// =====================================
export const verifyKyc = async (req, res) => {
  try {
    const { vendorId, status, remarks } = req.body;

    if (!['verified', 'rejected'].includes(status))
      return res.status(400).json({ error: 'Invalid status' });

    const kyc = await Kyc.findOne({ user: vendorId });
    if (!kyc) return res.status(404).json({ error: 'KYC record not found' });

    kyc.status = status;
    kyc.remarks = remarks || '';
    await kyc.save();

    res.json({
      success: true,
      message: `KYC ${status} successfully`,
      kyc,
    });
  } catch (err) {
    console.error('❌ verifyKyc error:', err);
    res.status(500).json({ error: 'Failed to update KYC status' });
  }
};
// ===============================
// ✅ VERIFY VENDOR KYC & CREATE PAYSTACK RECIPIENT
// ===============================
export const verifyVendorKYC = async (req, res) => {
  try {
    const { vendorId, accountName, accountNumber, bankCode, bankName } = req.body;

    // 1️⃣ Find vendor
    const vendor = await Vendor.findById(vendorId);
    if (!vendor) return res.status(404).json({ error: "Vendor not found" });

    // 2️⃣ Create Paystack transfer recipient
    const recipient = await createTransferRecipient(accountName, accountNumber, bankCode);

    // 3️⃣ Update vendor record
    vendor.accountName = accountName;
    vendor.accountNumber = accountNumber;
    vendor.bankCode = bankCode;
    vendor.bankName = bankName;
    vendor.paystackRecipientCode = recipient.recipient_code;
    vendor.kycVerified = true;
    vendor.kycStatus = "approved";
    await vendor.save();

    console.log(`✅ KYC verified for vendor ${vendor.storeName}, Paystack recipient created: ${recipient.recipient_code}`);

    res.json({
      success: true,
      message: "KYC verified and Paystack recipient created successfully",
      vendor,
    });
  } catch (err) {
    console.error("❌ verifyVendorKYC error:", err.message);
    res.status(500).json({
      error: "Failed to verify KYC",
      details: err.message,
    });
  }
};

