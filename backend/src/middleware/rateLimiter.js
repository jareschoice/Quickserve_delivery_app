// ===============================
// FILE: backend/src/middleware/rateLimiter.js
// ===============================
import rateLimit from 'express-rate-limit'

// Basic rate limiter for API endpoints.
// Tweak windowMs and max to suit your infra / plan (current: 100 req per 15 min).
export const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX || '100'), // limit each IP to X requests per windowMs
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please slow down' },
  handler: (req, res) => res.status(429).json({ error: 'Rate limit exceeded' })
})

// More aggressive limiter for auth endpoints (login/register, protect from brute force)
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_AUTH_MAX || '10'),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts, try again later' }
})
