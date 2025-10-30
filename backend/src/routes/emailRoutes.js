import { Router } from 'express'
import { sendTestEmail } from '../controllers/emailController.js' // ✅ fixed import

const router = Router()

// 📩 Send test email
router.post('/send', sendTestEmail)

export default router