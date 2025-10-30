import axios from 'axios'

const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY

export const initPayment = async (req, res) => {
  try {
    const { email, amount } = req.body
    if (!email || !amount) return res.status(400).json({ error: 'email & amount required' })
    const kobo = Math.max(100, Math.round(Number(amount) * 100)) // NGN to kobo
    const resp = await axios.post('https://api.paystack.co/transaction/initialize', {
      email, amount: kobo, currency: process.env.PAYSTACK_CURRENCY || 'NGN'
    }, {
      headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
    })
    res.json(resp.data)
  } catch (e) {
    console.error('initPayment error:', e.response?.data || e.message)
    res.status(500).json({ error: 'init failed', detail: e.response?.data || e.message })
  }
}

export const verifyPayment = async (req, res) => {
  try {
    const { reference } = req.query
    const resp = await axios.get(`https://api.paystack.co/transaction/verify/${reference}`, {
      headers: { Authorization: `Bearer ${PAYSTACK_SECRET_KEY}` }
    })
    res.json(resp.data)
  } catch (e) {
    console.error('verifyPayment error:', e.response?.data || e.message)
    res.status(500).json({ error: 'verify failed', detail: e.response?.data || e.message })
  }
}
