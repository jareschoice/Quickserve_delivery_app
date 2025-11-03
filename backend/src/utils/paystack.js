import axios from "axios";

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY;
const BASE_URL = "https://api.paystack.co";

// ✅ Initialize Paystack Axios
const paystack = axios.create({
  baseURL: BASE_URL,
  headers: {
    Authorization: `Bearer ${PAYSTACK_SECRET}`,
    "Content-Type": "application/json",
  },
});

// ✅ Verify transaction
export const verifyPaystackPayment = async (reference) => {
  const { data } = await paystack.get(`/transaction/verify/${reference}`);
  return data;
};

// ✅ Initiate transfer to vendor
export const initiateTransfer = async (amount, recipientCode, reason = "") => {
  const { data } = await paystack.post("/transfer", {
    source: "balance",
    amount: Math.round(amount * 100), // convert to kobo
    recipient: recipientCode,
    reason,
  });
  return data;
};

/// ===============================
// ✅ CREATE PAYSTACK TRANSFER RECIPIENT
// ===============================
export const createTransferRecipient = async (name, accountNumber, bankCode) => {
  try {
    const response = await axios.post(
      "https://api.paystack.co/transferrecipient",
      {
        type: "nuban",
        name,
        account_number: accountNumber,
        bank_code: bankCode,
        currency: "NGN",
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    const data = response.data;
    if (!data.status) throw new Error("Failed to create Paystack recipient");

    console.log(`✅ Paystack recipient created: ${data.data.recipient_code}`);
    return data.data;
  } catch (err) {
    console.error("❌ createTransferRecipient error:", err.response?.data || err.message);
    throw err;
  }
};


export default paystack;
