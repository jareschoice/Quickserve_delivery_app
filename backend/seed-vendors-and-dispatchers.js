// Seed 20 vendors and 10 dispatchers with auto-incrementing IDs
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import User from './src/models/User.js';
import Vendor from './src/models/Vendor.js';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: join(__dirname, '.env') });

// Vendor data organized by category
const vendorsByCategory = {
  restaurant: [
    { name: 'Golden Spoon Restaurant', owner: 'Chef Michael Brown', phone: '+234 801 234 5001', address: '12 Marina Road, Lagos' },
    { name: 'Mama Put Express', owner: 'Mrs. Ngozi Okafor', phone: '+234 801 234 5002', address: '45 Allen Avenue, Ikeja' },
    { name: 'Suya Kingdom', owner: 'Alhaji Musa Ibrahim', phone: '+234 801 234 5003', address: '78 Admiralty Way, Lekki' },
    { name: 'Jollof Palace', owner: 'Chef Amaka Williams', phone: '+234 801 234 5004', address: '23 Awolowo Road, Ikoyi' },
    { name: 'Pepper Soup Hub', owner: 'Mr. Tunde Adeyemi', phone: '+234 801 234 5005', address: '56 Opebi Road, Ikeja' },
  ],
  pharmacy: [
    { name: 'HealthPlus Pharmacy', owner: 'Dr. Sarah Johnson', phone: '+234 802 234 5001', address: '34 Broad Street, Lagos Island' },
    { name: 'MediCare Pharmacy', owner: 'Pharm. David Okon', phone: '+234 802 234 5002', address: '67 Herbert Macaulay, Yaba' },
    { name: 'WellCare Pharmacy', owner: 'Pharm. Grace Eze', phone: '+234 802 234 5003', address: '89 Victoria Island, VI' },
    { name: 'QuickMeds Pharmacy', owner: 'Dr. Ahmed Lawal', phone: '+234 802 234 5004', address: '12 Surulere Road, Surulere' },
    { name: 'Family Health Pharmacy', owner: 'Pharm. Rita Chukwu', phone: '+234 802 234 5005', address: '45 Festac Link Road, Festac' },
  ],
  shop: [
    { name: 'Fashion Hub Boutique', owner: 'Ms. Linda Davies', phone: '+234 803 234 5001', address: '23 Palms Mall, Lekki' },
    { name: 'Electronics World', owner: 'Mr. James Okoro', phone: '+234 803 234 5002', address: '56 Computer Village, Ikeja' },
    { name: 'Beauty Haven', owner: 'Mrs. Blessing Ade', phone: '+234 803 234 5003', address: '34 Adeniran Ogunsanya, Surulere' },
    { name: 'Phone Accessories Plus', owner: 'Mr. Kevin Uche', phone: '+234 803 234 5004', address: '78 Balogun Market, Lagos Island' },
    { name: 'Gift Gallery', owner: 'Ms. Tope Balogun', phone: '+234 803 234 5005', address: '90 Tejuosho Market, Yaba' },
  ],
  supermarket: [
    { name: 'FreshMart Supermarket', owner: 'Mr. Paul Obi', phone: '+234 804 234 5001', address: '45 Admiralty Way, Lekki Phase 1' },
    { name: 'QuickStop Groceries', owner: 'Mrs. Joy Nnamdi', phone: '+234 804 234 5002', address: '67 Ajah Road, Ajah' },
    { name: 'City Supermarket', owner: 'Mr. Daniel Eke', phone: '+234 804 234 5003', address: '23 Lekki-Epe Expressway, Lekki' },
    { name: 'Family Mart', owner: 'Mrs. Chioma Nwankwo', phone: '+234 804 234 5004', address: '89 Gbagada Expressway, Gbagada' },
    { name: 'Express Grocers', owner: 'Mr. Felix Ojo', phone: '+234 804 234 5005', address: '12 Oshodi-Apapa Expressway, Oshodi' },
  ]
};

// Dispatcher data
const dispatchers = [
  { name: 'Chidi Okeke', phone: '+234 805 100 0001' },
  { name: 'Fatima Abubakar', phone: '+234 805 100 0002' },
  { name: 'Emeka Okafor', phone: '+234 805 100 0003' },
  { name: 'Aisha Mohammed', phone: '+234 805 100 0004' },
  { name: 'Tunde Bakare', phone: '+234 805 100 0005' },
  { name: 'Ngozi Eze', phone: '+234 805 100 0006' },
  { name: 'Yusuf Ibrahim', phone: '+234 805 100 0007' },
  { name: 'Chioma Nwosu', phone: '+234 805 100 0008' },
  { name: 'Bashir Suleiman', phone: '+234 805 100 0009' },
  { name: 'Funmi Adeleke', phone: '+234 805 100 0010' },
];

async function getNextVendorId() {
  const lastVendor = await Vendor.findOne().sort({ vendorId: -1 }).select('vendorId');
  if (!lastVendor || !lastVendor.vendorId) {
    return 'VEN-0001';
  }
  const lastNumber = parseInt(lastVendor.vendorId.split('-')[1]);
  const nextNumber = lastNumber + 1;
  return `VEN-${String(nextNumber).padStart(4, '0')}`;
}

async function getNextDispatcherId() {
  const lastDispatcher = await User.findOne({ role: 'dispatcher' }).sort({ dispatcherId: -1 }).select('dispatcherId');
  if (!lastDispatcher || !lastDispatcher.dispatcherId) {
    return 'DIS-0001';
  }
  const lastNumber = parseInt(lastDispatcher.dispatcherId.split('-')[1]);
  const nextNumber = lastNumber + 1;
  return `DIS-${String(nextNumber).padStart(4, '0')}`;
}

async function seedDatabase() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB!\n');

    const credentials = {
      vendors: [],
      dispatchers: []
    };

    // Create Vendors
    console.log('👨‍🍳 Creating 20 vendors...\n');
    let vendorCount = 0;

    for (const [category, vendors] of Object.entries(vendorsByCategory)) {
      console.log(`📦 Creating ${category} vendors...`);
      
      for (const vendorData of vendors) {
        vendorCount++;
        const vendorId = await getNextVendorId();
        const email = `vendor${vendorCount}@quickserve.com`;
        const password = `Vendor${vendorCount}!`;

        // Create user account
        const user = await User.create({
          name: vendorData.owner,
          email,
          password,
          role: 'vendor',
          isVerified: true,
          isActive: true,
          profile: {
            phone: vendorData.phone
          }
        });

        // Create vendor profile
        const vendor = await Vendor.create({
          vendorId,
          user: user._id,
          businessName: vendorData.name,
          storeName: vendorData.name,
          businessAddress: vendorData.address,
          businessPhone: vendorData.phone,
          category,
          isActive: true,
          isApproved: true,
          availabilityStatus: 'open',
          kycStatus: 'approved'
        });

        credentials.vendors.push({
          id: vendorCount,
          vendorId,
          businessName: vendorData.name,
          owner: vendorData.owner,
          category,
          email,
          password,
          phone: vendorData.phone,
          address: vendorData.address
        });

        console.log(`   ✅ ${vendorId}: ${vendorData.name}`);
      }
    }

    console.log(`\n✅ Created ${vendorCount} vendors!\n`);

    // Create Dispatchers
    console.log('🚚 Creating 10 dispatchers...\n');
    
    for (let i = 0; i < dispatchers.length; i++) {
      const dispatcherData = dispatchers[i];
      const dispatcherId = await getNextDispatcherId();
      const email = `dispatcher${i + 1}@quickserve.com`;
      const password = `Dispatcher${i + 1}!`;

      const dispatcher = await User.create({
        name: dispatcherData.name,
        email,
        password,
        role: 'dispatcher',
        dispatcherId,
        isVerified: true,
        isActive: true,
        profile: {
          phone: dispatcherData.phone
        }
      });

      credentials.dispatchers.push({
        id: i + 1,
        dispatcherId,
        name: dispatcherData.name,
        email,
        password,
        phone: dispatcherData.phone
      });

      console.log(`   ✅ ${dispatcherId}: ${dispatcherData.name}`);
    }

    console.log(`\n✅ Created ${dispatchers.length} dispatchers!\n`);

    // Save credentials to file
    const credentialsText = `
╔════════════════════════════════════════════════════════════════════════════╗
║                   QUICKSERVE TEST ACCOUNTS CREDENTIALS                     ║
║                        Generated: ${new Date().toLocaleString()}                        ║
╚════════════════════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════════════════════
                              🏪 VENDOR ACCOUNTS (20)
═══════════════════════════════════════════════════════════════════════════════

${credentials.vendors.map(v => `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
VENDOR #${v.id.toString().padEnd(2)} | ${v.vendorId} | ${v.category.toUpperCase()}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Business: ${v.businessName}
Owner:    ${v.owner}
Address:  ${v.address}
Phone:    ${v.phone}

🔐 LOGIN CREDENTIALS:
   Email:    ${v.email}
   Password: ${v.password}

📱 Dashboard: http://192.168.88.104:5555/event-frontend/vendor.html
`).join('\n')}

═══════════════════════════════════════════════════════════════════════════════
                           🚚 DISPATCHER ACCOUNTS (10)
═══════════════════════════════════════════════════════════════════════════════

${credentials.dispatchers.map(d => `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DISPATCHER #${d.id.toString().padEnd(2)} | ${d.dispatcherId}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Name:  ${d.name}
Phone: ${d.phone}

🔐 LOGIN CREDENTIALS:
   Email:    ${d.email}
   Password: ${d.password}

📱 Dashboard: http://192.168.88.104:5555/event-frontend/dispatcher.html
`).join('\n')}

═══════════════════════════════════════════════════════════════════════════════
                                📊 SUMMARY
═══════════════════════════════════════════════════════════════════════════════

Total Vendors:     ${credentials.vendors.length}
  • Restaurants:   ${credentials.vendors.filter(v => v.category === 'restaurant').length}
  • Pharmacies:    ${credentials.vendors.filter(v => v.category === 'pharmacy').length}
  • Shops:         ${credentials.vendors.filter(v => v.category === 'shop').length}
  • Supermarkets:  ${credentials.vendors.filter(v => v.category === 'supermarket').length}

Total Dispatchers: ${credentials.dispatchers.length}

All accounts are:
✅ Fully registered and verified
✅ Active and ready to use
✅ Assigned unique IDs (VEN-XXXX / DIS-XXXX)
✅ Ready to appear on home page

═══════════════════════════════════════════════════════════════════════════════
                              🎯 NEXT STEPS
═══════════════════════════════════════════════════════════════════════════════

1. Run product seeding script:
   node backend/seed-products-bulk.js

2. Each vendor will get 20 products automatically

3. All vendors will appear on home page grouped by category

4. Use credentials above to login and test each vendor/dispatcher dashboard

═══════════════════════════════════════════════════════════════════════════════
`;

    fs.writeFileSync(
      join(__dirname, 'TEST_ACCOUNTS_CREDENTIALS.txt'),
      credentialsText
    );

    console.log('📄 Credentials saved to: backend/TEST_ACCOUNTS_CREDENTIALS.txt\n');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log('                    🎉 SEEDING COMPLETE!');
    console.log('═══════════════════════════════════════════════════════════════');
    console.log(`✅ ${credentials.vendors.length} vendors created`);
    console.log(`✅ ${credentials.dispatchers.length} dispatchers created`);
    console.log('✅ All accounts verified and active');
    console.log('✅ Auto-incrementing IDs assigned');
    console.log('✅ Ready to appear on home page\n');
    console.log('📋 View credentials in: backend/TEST_ACCOUNTS_CREDENTIALS.txt');
    console.log('\n🚀 Next: Run product seeding script');
    console.log('   Command: node backend/seed-products-bulk.js\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding database:', error);
    process.exit(1);
  }
}

seedDatabase();
