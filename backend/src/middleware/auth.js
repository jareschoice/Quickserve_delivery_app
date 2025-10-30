import jwt from 'jsonwebtoken'

// map client role aliases to backend roles
const mapAlias = (r) => {
  if (!r) return r
  if (r === 'consumer') return 'customer'
  return r
}

export const authRequired = (...roles) => {
  return (req, res, next) => {
    const authHeader = req.headers?.authorization
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Authorization header missing or invalid' })
    }

    const token = authHeader.split(' ')[1]
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET)
      req.user = decoded

      // Optional role-based access control: accept multiple allowed roles
      if (roles && roles.length > 0) {
        const allowed = roles.map(mapAlias)
        if (!allowed.includes(decoded.role)) {
          return res.status(403).json({ error: 'Forbidden: insufficient permissions' })
        }
      }

      next()
    } catch (err) {
      return res.status(401).json({ error: 'Invalid or expired token' })
    }
  }
}