import multer from 'multer'
import path from 'path'
import fs from 'fs'

const uploadDir = path.resolve('public', 'uploads')
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true })
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname)
    const base = path.basename(file.originalname, ext).replace(/[^a-z0-9_-]/gi, '')
    const name = `${base}-${Date.now()}${ext}`
    cb(null, name)
  }
})

export const upload = multer({
  storage,
  fileFilter: (req, file, cb) => {
    if (!file.mimetype.startsWith('image/')) return cb(new Error('Images only'))
    cb(null, true)
  },
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
})
