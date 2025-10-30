import { sendEmail } from '../utils/emailClient.js'  // ✅ Fixed import

export const sendTestEmail = async (req, res) => {
  try {
    const { to, subject, message } = req.body
    if (!to || !subject || !message) {
      return res.status(400).json({ error: 'All fields are required' })
    }

    await sendEmail({ to, subject, html: message }) // ✅ pass structured payload
    res.json({ success: true, message: `Email sent successfully to ${to}` })
  } catch (err) {
    console.error('❌ Email send failed:', err)
    res.status(500).json({ error: 'Failed to send email', detail: err.message })
  }
}