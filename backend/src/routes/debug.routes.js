// ===============================
// FILE: backend/src/routes/debug.routes.js
// ===============================
import express from 'express'
const router = express.Router()

// quick health endpoint (already have /health, this is a debug subset)
router.get('/status', (req, res) => {
  res.json({ ok: true, env: process.env.NODE_ENV || 'development', time: new Date().toISOString() })
})

// emit a socket test message to a room or user
// POST /api/debug/emit { room: "order:123", event: "order:update", payload: {...} }
router.post('/emit', (req, res) => {
  try {
    const io = req.app.get('io') || globalThis.io
    const { room, event, payload } = req.body
    if (!io) return res.status(500).json({ error: 'Socket server not available' })
    if (!room || !event) return res.status(400).json({ error: 'room and event required' })
    io.to(room).emit(event, payload || {})
    return res.json({ success: true, sentTo: room, event })
  } catch (e) {
    console.error('debug.emit error', e.message)
    return res.status(500).json({ error: e.message })
  }
})

// Get minimal socket stats (in-memory)
router.get('/socket-stats', (req, res) => {
  const stats = globalThis.__QUICKSERVE_SOCKET_STATS__ || { connections: 0, events: {} }
  res.json({ success: true, stats })
})

export default router
