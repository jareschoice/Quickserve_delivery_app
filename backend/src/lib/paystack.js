import axios from "axios";

const secret = process.env.PAYSTACK_SECRET_KEY;
if (!secret) {
  console.warn("⚠️ PAYSTACK_SECRET_KEY missing — payments won't work until you add it to .env");
}
export const paystack = axios.create({
  baseURL: "https://api.paystack.co",
  headers: {
    Authorization: `Bearer ${secret}`,
    "Content-Type": "application/json",
  },
});
