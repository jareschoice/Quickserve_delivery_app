import { Router } from 'express'
import { authRequired } from '../middleware/auth.js'

const router = Router()

router.get('/me', authRequired('rider'), (req,res)=>{
  res.json({ rider: req.user.rider || {}, user: { id: req.user._id, fullName: req.user.fullName } })
})

export default router
