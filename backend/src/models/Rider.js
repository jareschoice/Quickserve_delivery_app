import mongoose from 'mongoose'
const s=new mongoose.Schema({user:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true},isOnline:{type:Boolean,default:false},wallet:{type:Number,default:0}},{timestamps:true})
export default mongoose.model('Rider',s)
