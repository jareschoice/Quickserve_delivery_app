// Simple test server to debug connection issues
import 'dotenv/config'
import express from 'express'
import cors from 'cors'

const app = express()
const PORT = process.env.PORT || 5000

// Middleware
app.use(cors())
app.use(express.json())

// Test route
app.get('/', (req, res) => {
  res.json({ 
    ok: true, 
    service: 'QuickServe API Test', 
    time: new Date().toISOString(),
    message: 'Backend is working!'
  })
})

// Simple auth test route
app.post('/auth/test', (req, res) => {
  res.json({ message: 'Auth endpoint working!', body: req.body })
})

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Test QuickServe API running on http://0.0.0.0:${PORT}`)
  console.log(`📱 Access from phone: http://192.168.4.104:${PORT}`)
})