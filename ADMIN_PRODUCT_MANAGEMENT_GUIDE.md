# 📦 Admin Product Management System - User Guide

## Overview
The Admin Product Management System allows you (the admin) to upload, manage, and track inventory for all vendors participating in the QuickServe Event Edition.

---

## 🎯 Key Features

### 1. **Upload Products for Any Vendor**
- Select a vendor from the sidebar
- Click "Add New Product"
- Fill in product details:
  - **Name**: Product name (e.g., "Jollof Rice")
  - **Category**: Nigerian, Fast Food, Drinks, Snacks, Continental, Desserts, Other
  - **Description**: Detailed product description
  - **Price**: Price in Naira (₦)
  - **Stock Quantity**: Initial inventory amount
  - **Unit**: piece, plate, bowl, cup, bottle, pack, serving
  - **Image**: Upload product photo (optional)
  - **Available**: Toggle if product is available for ordering

### 2. **Adjust Stock (Add/Reduce/Set)**
- **Add Stock**: Increase inventory (e.g., +50 pieces)
- **Reduce Stock**: Decrease inventory manually (e.g., -10 damaged items)
- **Set Exact**: Set specific quantity (e.g., set to 100)
- Optional reason tracking for each adjustment

### 3. **Auto Stock Reduction**
When a customer places an order, the system **automatically reduces** the product quantity:
```
Customer orders 2 plates of Jollof Rice
→ Stock: 50 → 48 (automatically)
```

### 4. **Stock Level Indicators**
- 🟢 **Green Badge** (High Stock): 10+ items
- 🟡 **Yellow Badge** (Low Stock): 1-9 items
- 🔴 **Red Badge** (Out of Stock): 0 items

### 5. **Enable/Disable Products**
Toggle product availability without deleting:
- **Enabled**: Customers can order
- **Disabled**: Hidden from customer view

---

## 📋 Step-by-Step Guide

### Adding a New Product

1. **Login as Admin**
   - Go to: `http://localhost:8080/login.html`
   - Email: `admin@event.test`
   - Password: `admin123`

2. **Navigate to Product Management**
   - Click "Products" in the top navigation
   - Or go directly to: `http://localhost:8080/admin-products.html`

3. **Select a Vendor**
   - Search or scroll vendor list on the left
   - Click on vendor card (it will highlight blue)

4. **Add Product**
   - Click "Add New Product" button (top right)
   - Fill in the form:
     ```
     Product Name: Jollof Rice with Chicken
     Category: Nigerian
     Description: Spicy jollof rice with grilled chicken, plantain, and coleslaw
     Price: 1500
     Stock Quantity: 100
     Unit: plate
     ```
   - Upload image (optional)
   - Click "Save Product"

5. **Success!**
   - Product appears in vendor's product grid
   - Customers can now see and order it

### Adjusting Stock

#### Scenario 1: Restocking
```
You receive new supply from vendor

1. Click "Stock" button on product card
2. Select "Add Stock"
3. Enter amount: 50
4. Reason: "Restock from vendor"
5. Click "Update Stock"

Result: Stock increases from 20 → 70
```

#### Scenario 2: Damaged Items
```
Some items were damaged

1. Click "Stock" button on product card
2. Select "Reduce Stock"
3. Enter amount: 5
4. Reason: "Damaged during transport"
5. Click "Update Stock"

Result: Stock decreases from 70 → 65
```

#### Scenario 3: Physical Count
```
After physical inventory count

1. Click "Stock" button on product card
2. Select "Set Exact"
3. Enter amount: 80
4. Reason: "Physical inventory count"
5. Click "Update Stock"

Result: Stock set to exactly 80
```

### Editing a Product

1. Click "Edit" button on product card
2. Modify any field (name, price, description, etc.)
3. Optionally upload new image
4. Click "Save Product"

### Disabling a Product

Use this when a product is **temporarily unavailable** (don't delete it):

1. Toggle the "Product is available" switch on product card
2. Product becomes hidden from customers immediately
3. Toggle back to make it available again

### Deleting a Product

**Warning**: This permanently removes the product!

1. Click "Delete" button (trash icon)
2. Confirm deletion
3. Product and its image are removed

---

## 🔄 Automatic Stock Management

### How It Works

When a customer places an order:

1. **Order Placed**
   ```
   Customer: "2x Jollof Rice, 1x Chapman"
   ```

2. **Stock Auto-Reduced**
   ```
   Jollof Rice: 100 → 98 plates
   Chapman: 50 → 49 cups
   ```

3. **Real-Time Update**
   - Product cards show updated stock immediately
   - Stock badges change color if threshold crossed

### Low Stock Alerts

When stock reaches **10 or fewer**, the badge turns **yellow**:
- 🟡 This alerts you to restock soon

When stock reaches **0**, the badge turns **red**:
- 🔴 Customers cannot order this item
- Product may auto-disable (based on settings)

### Preventing Overselling

The system prevents orders if stock is insufficient:
```
Customer tries to order 5 plates
Current stock: 3 plates
→ Order rejected: "Insufficient stock"
```

---

## 📊 Stock Tracking & Reports

### View Stock History (Coming Soon)
Each stock adjustment is logged:
```
Date: Nov 3, 2025, 3:00 PM
Product: Jollof Rice
Action: Add Stock
Amount: +50
Reason: Restock from vendor
Adjusted By: admin@event.test
Old Stock: 20
New Stock: 70
```

### Generate Reports (Coming Soon)
- Products with low stock
- Most ordered products
- Stock value by vendor
- Stock adjustment history

---

## 🎨 Product Image Guidelines

### Recommended Specs
- **Format**: JPG, PNG, GIF, WebP
- **Size**: Max 5MB
- **Dimensions**: 800x800px (square) recommended
- **Quality**: High resolution, well-lit

### Tips for Great Product Photos
- ✅ Use natural lighting
- ✅ Show food on clean plates/bowls
- ✅ Include garnish for appeal
- ✅ Shoot from slight angle (not directly above)
- ❌ Avoid dark or blurry images
- ❌ Don't use heavily filtered photos

---

## 🚀 Quick Reference

### Admin URLs
- **Product Management**: `http://localhost:8080/admin-products.html`
- **Dashboard**: `http://localhost:8080/admin.html`
- **Login**: `http://localhost:8080/login.html`

### API Endpoints
```
POST   /api/admin/products              Create product
PUT    /api/admin/products/:id          Update product
DELETE /api/admin/products/:id          Delete product
PATCH  /api/admin/products/:id/stock    Adjust stock
PATCH  /api/admin/products/:id/availability  Toggle availability
GET    /api/admin/products              Get all products
GET    /api/admin/products/:id          Get single product
```

### Stock Actions
| Action | Purpose | Example |
|--------|---------|---------|
| **Add** | Increase inventory | Restock from supplier |
| **Reduce** | Decrease inventory | Damaged items, staff meal |
| **Set** | Set exact amount | After physical count |

### Stock Levels
| Color | Range | Status |
|-------|-------|--------|
| 🟢 Green | 10+ | High Stock |
| 🟡 Yellow | 1-9 | Low Stock |
| 🔴 Red | 0 | Out of Stock |

---

## 🔧 Troubleshooting

### Issue: Can't upload image
**Solutions:**
- Check file size (must be < 5MB)
- Use supported formats: JPG, PNG, GIF, WebP
- Try compressing image with TinyPNG.com

### Issue: Stock not updating
**Solutions:**
- Refresh the page
- Check browser console for errors
- Verify backend is running

### Issue: Product not showing to customers
**Solutions:**
- Check "Available" toggle is ON (green)
- Verify stock quantity > 0
- Check product category is assigned

### Issue: Multiple admins editing same product
**Best Practice:**
- Coordinate with other admins
- Use "Reason" field in stock adjustments
- Check recent changes before making adjustments

---

## 📱 Mobile Access

The admin product management interface is **mobile-responsive**:

- Use on tablets during event setup
- Adjust stock on-the-go with your phone
- All features work on mobile devices

---

## 🎯 Best Practices

### Before Event Day
1. ✅ Upload all products for all 20 vendors
2. ✅ Add high-quality images for each product
3. ✅ Set accurate initial stock quantities
4. ✅ Test ordering a product to verify stock reduction
5. ✅ Enable all products that should be available

### During Event
1. 📊 Monitor stock levels every 30 minutes
2. 🟡 Restock products showing yellow badges
3. 🔄 Adjust stock if vendors add/remove items
4. ❌ Disable products that run out
5. 📝 Note any issues for post-event review

### After Event
1. 📈 Review which products sold best
2. 📉 Note products with leftover stock
3. 💾 Export data for vendor reports
4. 🧹 Clean up test products
5. 📊 Prepare analytics for next event

---

## 💡 Pro Tips

### Bulk Upload (Future Feature)
Upload 50 products at once using CSV:
```csv
vendorId,name,category,price,quantity,unit
123abc,Jollof Rice,Nigerian,1500,100,plate
123abc,Fried Rice,Nigerian,1200,80,plate
```

### Keyboard Shortcuts
- `Alt + N` - Add New Product (when vendor selected)
- `Alt + S` - Open Stock Modal (when product focused)
- `Esc` - Close modal

### Stock Forecasting
Track order patterns to predict stock needs:
```
If average orders/hour = 20 plates
Event duration = 8 hours
Recommended stock = 20 × 8 × 1.2 = 192 plates (20% buffer)
```

---

## 📞 Support

For issues or questions:
- Check backend logs: `backend/` folder
- Check browser console (F12)
- Review API responses in Network tab
- Contact system administrator

---

**Happy Managing! 🎉**

The QuickServe Admin Product Management System keeps your event running smoothly with accurate inventory tracking and seamless stock management.
