# 📦 QuickServe Product & Vendor Upload Guide

## 🎯 Understanding The System

### **How QuickServe Works:**

```
HOME PAGE (home.html)
├── Categories Filter (Restaurant, Fast Food, Snacks, etc.)
├── EXPLORE Section → Shows ALL Vendors (circular avatars)
├── FEATURED Section → Shows First 8 Vendors (cards with emojis)
│
└── When User Clicks a Vendor →
    └── VENDOR PAGE (vendor.html)
        └── Shows ALL Products for that Vendor
```

---

## 📝 Step-by-Step Upload Process

### **STEP 1: Register a Vendor (Restaurant/Shop)**

1. **Open Admin Dashboard**:
   - Go to: `http://127.0.0.1:3000/event-frontend/admin.html`

2. **Click "Register Vendor"** in the sidebar

3. **Fill in Vendor Details**:
   ```
   ✅ Business Name: e.g., "Mama Put Kitchen"
   ✅ Contact Person: e.g., "John Doe"
   ✅ Email: e.g., "mamaput@example.com"
   ✅ Phone: e.g., "+234 800 000 0000"
   ✅ Category: Select from dropdown:
      • Restaurant
      • Fast Food
      • Drinks & Beverages
      • Snacks
      • Continental
      • Local Food
      • Desserts
      • Other
   ✅ Minimum Order: e.g., 1000 (₦1,000)
   ✅ Address: Full address
   ✅ Location: City/Area
   ✅ Password: For vendor login
   ✅ Description: Brief description of the business
   ```

4. **Click "Register Vendor"**

5. **Result**: Vendor now appears in:
   - Home page **Explore** section (all vendors)
   - Home page **Featured** section (first 8 vendors)
   - Can be filtered by the category you selected

---

### **STEP 2: Upload Products for a Vendor**

1. **Go to Product Management**:
   - From Admin Dashboard → Click **"Manage Products"** in sidebar
   - Or go to: `http://127.0.0.1:3000/event-frontend/admin-products.html`

2. **Select a Vendor**:
   - Left sidebar shows all registered vendors
   - Search for your vendor using the search box
   - Click on the vendor to select them

3. **Add New Product**:
   - Click **"Add New Product"** button (top right)

4. **Fill in Product Details**:
   ```
   ✅ Product Name: e.g., "Jollof Rice with Chicken"
   ✅ Category: Select from dropdown:
      • Nigerian
      • Fast Food
      • Drinks
      • Snacks
      • Continental
      • Desserts
      • Other
   ✅ Description: e.g., "Delicious party jollof rice served with fried chicken"
   ✅ Price: e.g., 2500 (₦2,500)
   ✅ Stock Quantity: e.g., 50
   ✅ Unit: Select from dropdown:
      • Piece
      • Plate
      • Bowl
      • Cup
      • Bottle
      • Pack
      • Serving
   ✅ Product Image: Upload a clear image of the food
   ✅ Product is available: Check if product is ready for ordering
   ```

5. **Click "Save Product"**

6. **Result**: Product now appears:
   - On that vendor's menu page (`vendor.html`)
   - Users can add it to cart and order

---

## 🔍 Understanding Categories

### **Vendor Categories (Where Restaurant Appears):**
These determine how vendors are grouped on the home page:

| Category | Purpose | Example |
|----------|---------|---------|
| **Restaurant** | Traditional sit-down restaurants | Mama Put, Mr. Biggs |
| **Fast Food** | Quick service restaurants | KFC, Dominos |
| **Drinks & Beverages** | Drink shops, juice bars | Smoothie King, Juice World |
| **Snacks** | Snack shops | Popcorn stands, Chin Chin shop |
| **Continental** | International cuisine | Chinese restaurant, Italian |
| **Local Food** | Traditional Nigerian food | Buka, Local food vendor |
| **Desserts** | Dessert shops | Ice cream parlor, Bakery |
| **Other** | Miscellaneous | Any other type |

### **Product Categories (What Type of Food):**
These help organize products within a vendor's menu:

| Category | Examples |
|----------|----------|
| **Nigerian** | Jollof Rice, Egusi Soup, Pounded Yam, Suya |
| **Fast Food** | Burgers, Pizza, Shawarma, Fried Chicken |
| **Drinks** | Soft Drinks, Juice, Smoothies, Water |
| **Snacks** | Chin Chin, Puff Puff, Popcorn, Plantain Chips |
| **Continental** | Pasta, Steak, Salad, Sandwiches |
| **Desserts** | Ice Cream, Cake, Cookies, Parfait |
| **Other** | Any other food items |

---

## 📍 Where Things Appear After Upload

### **After Registering a Vendor:**

```
HOME PAGE
├── Top Filter → Category buttons (Restaurant, Fast Food, etc.)
│   └── Click category → Shows only vendors in that category
│
├── EXPLORE Section (Horizontal scroll)
│   └── Shows: Vendor avatar + Business name
│   └── Click → Opens vendor's menu page
│
└── FEATURED Section (Grid of cards)
    └── Shows: Food emoji + Business name + Min. order
    └── Click → Opens vendor's menu page
```

### **After Uploading Products:**

```
VENDOR PAGE (vendor.html)
├── Vendor Name (Header)
├── Back Button
│
└── Products Grid
    ├── Product Image
    ├── Product Name
    ├── Description
    ├── Price
    ├── Category badge
    └── "Add to Cart" button
```

---

## 🛠️ Admin Product Management Features

Once products are uploaded, you can:

1. **Edit Products**: Click edit icon on any product card
2. **Delete Products**: Click delete icon (trash bin)
3. **Toggle Availability**: Switch products on/off without deleting
4. **Update Stock**: Change quantity available
5. **Change Price**: Update product pricing
6. **Upload New Image**: Replace product photos

---

## 📊 Complete Workflow Example

### **Example: Adding "Mama Put Kitchen" Restaurant**

1. **Register Vendor**:
   ```
   Business Name: Mama Put Kitchen
   Category: Restaurant
   Minimum Order: ₦1,500
   ```
   ✅ Now appears on home page in "Explore" and "Featured"

2. **Upload Products**:
   
   **Product 1:**
   ```
   Name: Jollof Rice with Chicken
   Category: Nigerian
   Price: ₦2,500
   Image: [Upload photo]
   ```
   
   **Product 2:**
   ```
   Name: Fried Rice Special
   Category: Nigerian
   Price: ₦2,800
   Image: [Upload photo]
   ```
   
   **Product 3:**
   ```
   Name: Chapman Drink
   Category: Drinks
   Price: ₦800
   Image: [Upload photo]
   ```

3. **Result**:
   - Users click "Mama Put Kitchen" on home page
   - See all 3 products on vendor page
   - Can add items to cart and order

---

## 🔄 API Endpoints Used

**Frontend uses these backend APIs:**

| Action | Endpoint | Method |
|--------|----------|--------|
| Register Vendor | `/api/vendor/create-vendor` | POST |
| Get All Vendors | `/api/event/vendors` | GET |
| Get Vendor Products | `/api/event/vendors/:vendorId/products` | GET |
| Add Product | `/api/admin/products` | POST |
| Update Product | `/api/admin/products/:productId` | PUT |
| Delete Product | `/api/admin/products/:productId` | DELETE |
| Update Stock | `/api/admin/products/:productId/stock` | PATCH |
| Toggle Availability | `/api/admin/products/:productId/availability` | PATCH |

---

## ❓ Frequently Asked Questions

### **Q: How do I make a vendor appear in "Featured" section?**
**A:** Featured section automatically shows the first 8 vendors. The most recently added vendors will appear here.

### **Q: How do I make a product appear in "Explore" section?**
**A:** Products don't appear in Explore section. Explore shows VENDORS only. When users click a vendor, they see the products.

### **Q: Can I have multiple categories for one product?**
**A:** No, each product has one primary category. Choose the most appropriate one.

### **Q: What's the difference between vendor category and product category?**
**A:** 
- **Vendor Category**: What type of business (Restaurant, Fast Food, etc.)
- **Product Category**: What type of food item (Nigerian, Continental, etc.)

### **Q: How do I remove a vendor?**
**A:** Currently, you need to do this from the backend. Delete the vendor from the database.

### **Q: Can vendors upload their own products?**
**A:** Not yet. Currently, only admin can upload products through the admin panel. Vendor self-service could be added later.

### **Q: Where are product images stored?**
**A:** Images are uploaded to the backend server at `/uploads` folder.

### **Q: How do I change the order of vendors on home page?**
**A:** Vendors are shown in the order they were created (newest first in some sections).

---

## 🎨 Categories Reference Quick Guide

### **When Registering Vendor - Choose Vendor Category:**
- Restaurant
- Fast Food  
- Drinks & Beverages
- Snacks
- Continental
- Local Food
- Desserts
- Other

### **When Uploading Product - Choose Product Category:**
- Nigerian
- Fast Food
- Drinks
- Snacks
- Continental
- Desserts
- Other

---

## ✅ Checklist for Uploading

**Before you upload:**
- [ ] Have business details ready
- [ ] Have clear product photos (recommended: 800x800px minimum)
- [ ] Know your pricing
- [ ] Know your stock quantities
- [ ] Have product descriptions written

**After uploading:**
- [ ] Test on home page - Can you see the vendor?
- [ ] Click vendor - Can you see products?
- [ ] Try adding to cart - Does it work?
- [ ] Test checkout flow

---

## 🚀 Quick Start Commands

```bash
# Start backend server
cd backend
npm start

# Start frontend
cd event-frontend
# Open admin.html in browser
# Navigate to Register Vendor
# Upload products
```

---

## 📞 Need Help?

If you encounter issues:

1. Check browser console for errors (F12)
2. Verify backend server is running
3. Check API_BASE_URL in `js/config.js`
4. Ensure MongoDB is connected
5. Check backend terminal for error logs

---

**Last Updated**: November 3, 2025  
**System Version**: QuickServe Event Platform v2.0
