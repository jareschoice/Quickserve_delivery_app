import { MongoClient, ObjectId } from 'mongodb';

const uri = process.env.MONGODB_URI || 'mongodb+srv://quickserveapp:8mHcXza0gCQHzN4Z@cluster0.mongodb.net/quickserve';
const client = new MongoClient(uri);

async function checkOrderStatus() {
  try {
    await client.connect();
    console.log('✅ Connected to MongoDB');
    
    const db = client.db('quickserve');
    const ordersCollection = db.collection('orders');
    
    // Get the order that was just accepted
    const orderId = '690b64364c8b5630d178aa2a'; // Order #f4dad4 from Mama's Kitchen
    
    const order = await ordersCollection.findOne({ 
      _id: new ObjectId(orderId) 
    });
    
    if (order) {
      console.log('\n📦 ORDER DETAILS:');
      console.log('==================');
      console.log(`Order ID: ${order._id}`);
      console.log(`Status: ${order.status}`);
      console.log(`Accepted At: ${order.acceptedAt || 'Not yet accepted'}`);
      console.log(`Consumer ID: ${order.consumerId}`);
      console.log(`Vendor ID: ${order.vendorId}`);
      console.log(`Group ID: ${order.orderGroupId}`);
      console.log(`Multi-Vendor: ${order.isMultiVendor}`);
      console.log(`Total: ₦${order.total}`);
      console.log(`Payment Paid: ${order.payment?.paid ? '✅ Yes' : '❌ No'}`);
      
      console.log('\n📱 NOTIFICATION SENT TO:');
      console.log('======================');
      console.log(`Customer Socket Room: ${order.consumerId}`);
      console.log(`Message: "Vendor accepted your order!"`);
      
      // Check all orders in the same group
      const groupOrders = await ordersCollection.find({
        orderGroupId: order.orderGroupId
      }).toArray();
      
      console.log('\n👥 MULTI-VENDOR GROUP STATUS:');
      console.log('============================');
      console.log(`Total Vendors in Group: ${groupOrders.length}`);
      
      groupOrders.forEach((o, index) => {
        console.log(`\n  Vendor ${index + 1}:`);
        console.log(`    Order ID: ${o._id}`);
        console.log(`    Status: ${o.status}`);
        console.log(`    Vendor ID: ${o.vendorId}`);
        console.log(`    Accepted: ${o.acceptedAt ? '✅ Yes' : '⏳ Pending'}`);
      });
      
      const acceptedCount = groupOrders.filter(o => o.status === 'accepted' || o.status === 'preparing' || o.status === 'ready').length;
      console.log(`\n  Progress: ${acceptedCount}/${groupOrders.length} vendors ready`);
      
    } else {
      console.log('❌ Order not found');
    }
    
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
    console.log('\n✅ Connection closed');
  }
}

checkOrderStatus();
