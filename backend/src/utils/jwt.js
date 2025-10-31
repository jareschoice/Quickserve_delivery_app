import jwt from 'jsonwebtoken'

export const signJWT = (payload, expiresIn = process.env.JWT_EXPIRES || '7d') =>
  jwt.sign(payload, process.env.JWT_SECRET, { expiresIn })

export const verifyJWT = (token) =>
  jwt.verify(token, process.env.JWT_SECRET)
