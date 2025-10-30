import mongoose from 'mongoose'
const s=new mongoose.Schema({user:{type:mongoose.Schema.Types.ObjectId,ref:'User'},order:{type:mongoose.Schema.Types.ObjectId,ref:'Order'},amount:Number,type:{type:String,enum:['debit','credit'],default:'credit'},meta:Object},{timestamps:true})
export default mongoose.model('Transaction',s)
