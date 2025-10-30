import axios from 'axios'
const base='https://api.paystack.co'
const headers={Authorization:`Bearer ${process.env.PAYSTACK_SECRET_KEY}`,'Content-Type':'application/json'}
export async function initPayment({amount,email,reference}){ const r=await axios.post(`${base}/transaction/initialize`,{email,amount:Math.round(amount*100),currency:process.env.PAYSTACK_CURRENCY||'NGN',reference},{headers}); return r.data }
export async function verifyPayment(reference){ const r=await axios.get(`${base}/transaction/verify/${reference}`,{headers}); return r.data }
