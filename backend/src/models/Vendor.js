import mongoose from 'mongoose'
const s=new mongoose.Schema({
	user:{type:mongoose.Schema.Types.ObjectId,ref:'User',required:true},
	storeName:{type:String,required:true},
	wallet:{type:Number,default:0},
	lastWithdrawAt:{type:Date}
},{timestamps:true})
export default mongoose.model('Vendor',s)
