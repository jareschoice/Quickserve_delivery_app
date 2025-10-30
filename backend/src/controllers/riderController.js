import Rider from '../models/Rider.js'
import User from '../models/User.js'
export async function createRider(req,res){ const {userId}=req.body; const u=await User.findById(userId); if(!u) return res.status(404).json({error:'User not found'}); const r=await Rider.create({user:u._id}); res.json(r) }
export async function toggleOnline(req,res){ const r=await Rider.findOne({user:req.user.id}); if(!r) return res.status(404).json({error:'Rider not found'}); r.isOnline=!r.isOnline; await r.save(); res.json({isOnline:r.isOnline}) }
