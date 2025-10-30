const { MongoClient, ServerApiVersion } = require('mongodb');

// ✅ Your encoded password and proper SRV URI
const uri = "mongodb+srv://quickserve_admin:Quickserve%402025%2323DB@quickserve-prod-cluster.ezminyr.mongodb.net/quickserve?retryWrites=true&w=majority&appName=QuickServe";

// ✅ Create MongoClient with Stable API
const client = new MongoClient(uri, {
    serverApi: {
        version: ServerApiVersion.v1,
        strict: true,
        deprecationErrors: true,
    },
});

async function run() {
    try {
        console.log("🧭 Connecting to MongoDB Atlas...");
        await client.connect();
        await client.db("quickserve").command({ ping: 1 });
        console.log("✅ Pinged your deployment. You successfully connected to MongoDB!");
    } catch (err) {
        console.error("❌ Connection failed:", err.message);
    } finally {
        await client.close();
    }
}

run();
