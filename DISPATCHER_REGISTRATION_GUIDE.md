# Dispatcher Registration - Admin Panel

## Overview
The admin panel now supports full dispatcher management, including registration, status toggling, and viewing all dispatchers in the system.

## Features Added

### 1. **Dispatchers Management Page** (`admin-panel/src/pages/Dispatchers.jsx`)
- ✅ View all dispatchers in a table with:
  - Name, Email, Phone
  - Active/Inactive status
  - KYC status
  - Wallet balance
  - Actions (Activate/Deactivate)
- ✅ Registration form with validation
- ✅ Real-time updates after registration
- ✅ Beautiful UI with Lucide icons

### 2. **Backend API Endpoints** (`backend/src/routes/admin.routes.js`)

#### Register Dispatcher
```
POST /api/admin/dispatchers
Authorization: Bearer <admin_token>

Body:
{
  "name": "Dispatcher Name",
  "email": "dispatcher@example.com",
  "password": "secure_password",
  "phone": "+234 xxx xxx xxxx"
}

Response:
{
  "success": true,
  "dispatcher": {
    "_id": "...",
    "name": "...",
    "email": "...",
    "role": "dispatcher",
    "isVerified": true,
    "profile": {
      "phone": "..."
    }
  },
  "message": "Dispatcher registered successfully"
}
```

#### Update Dispatcher Status
```
PUT /api/admin/dispatchers/:id
Authorization: Bearer <admin_token>

Body:
{
  "isActive": true/false
}

Response:
{
  "success": true,
  "dispatcher": { ... }
}
```

### 3. **Navigation Updates**
- ✅ Added "Dispatchers" menu item with Truck icon in sidebar
- ✅ Positioned between "Riders" and "Special Meals"
- ✅ Route: `/dispatchers`

## How to Use

### Access the Admin Panel
1. Start backend: `cd backend && npm start` (runs on port 5555)
2. Start admin panel: `cd admin-panel && npm run dev` (runs on port 3000)
3. Open browser: http://localhost:3000
4. Login with admin credentials

### Register a New Dispatcher
1. Navigate to **Dispatchers** in the sidebar
2. Click **"Add Dispatcher"** button
3. Fill in the form:
   - **Full Name**: Dispatcher's full name
   - **Email**: Must be unique (used for login)
   - **Phone**: Contact number
   - **Password**: Minimum 6 characters
4. Click **"Register Dispatcher"**
5. The new dispatcher will appear in the table immediately

### Manage Existing Dispatchers
- **View Status**: Check if dispatcher is Active/Inactive
- **Toggle Status**: Click "Deactivate" or "Activate" button
- **Check KYC**: See verification status (approved/pending/none)
- **View Wallet**: See current wallet balance

### Dispatcher Login
After registration, dispatchers can login at:
- Web: http://localhost:5555/event-frontend/dispatcher.html
- API: POST /api/auth/login with email and password

## Port Configuration

✅ **CONFIRMED CORRECT SETUP:**
- **Backend API**: Port 5555 (http://0.0.0.0:5555)
- **Admin Panel**: Port 3000 (http://localhost:3000)
- **Proxy**: Admin panel proxies all `/api/*` requests to `localhost:5555`

This architecture is correct:
- Admin panel runs on its own dev server (3000)
- API requests are proxied to backend (5555)
- No CORS issues thanks to Vite proxy configuration

### Why Different Ports?
- **Development Best Practice**: Frontend dev server (Vite) runs separately from backend
- **Hot Module Replacement**: Changes to React code reload instantly without restarting backend
- **Clean Separation**: Frontend and backend can be deployed independently
- **Proxy Handles CORS**: Vite proxy configuration forwards API calls seamlessly

## Testing

### Automated Test
Run the test script to verify everything works:
```bash
node test-dispatcher-registration.js
```

This will:
1. Login as admin
2. Register a test dispatcher
3. Verify dispatcher can login
4. Test status toggling
5. Confirm all endpoints work correctly

### Manual Testing Steps
1. ✅ Open admin panel: http://localhost:3000
2. ✅ Login with admin credentials
3. ✅ Navigate to "Dispatchers" page
4. ✅ Click "Add Dispatcher"
5. ✅ Fill form and submit
6. ✅ Verify success message appears
7. ✅ Check dispatcher appears in table
8. ✅ Test activate/deactivate toggle
9. ✅ Login as the new dispatcher in dispatcher.html

## Security Features
- ✅ Admin authentication required for all dispatcher management
- ✅ Passwords are automatically hashed (User model pre-save hook)
- ✅ Admin-created dispatchers are pre-verified (no email verification needed)
- ✅ Email uniqueness enforced at database level
- ✅ JWT tokens for secure authentication

## Database Schema
Dispatchers are stored as User documents with:
```javascript
{
  role: 'dispatcher',
  name: String,
  email: String (unique),
  password: String (hashed),
  isVerified: true, // Auto-verified when admin creates
  isActive: Boolean,
  profile: {
    phone: String
  },
  wallet: Number (default: 0),
  kycStatus: String (none/pending/approved/rejected)
}
```

## File Changes Summary

### Frontend
- `admin-panel/src/pages/Dispatchers.jsx` - NEW: Complete dispatcher management page
- `admin-panel/src/components/Layout.jsx` - UPDATED: Added Truck icon import and Dispatchers nav item
- `admin-panel/src/App.jsx` - UPDATED: Added Dispatchers import and route

### Backend
- `backend/src/routes/admin.routes.js` - UPDATED: Added POST /dispatchers and PUT /dispatchers/:id endpoints

### Testing
- `test-dispatcher-registration.js` - NEW: Automated test script

## Troubleshooting

### "Failed to register dispatcher"
- Check backend is running on port 5555
- Verify admin token is valid (login again if expired)
- Ensure email is unique (not already registered)

### "Unauthorized" Error
- Make sure you're logged in as admin
- Admin credentials: email=admin@quickserve.com, password=admin123
- Create admin if needed: `node backend/create-admin.js`

### Port Issues
- Admin panel SHOULD run on 3000 (Vite dev server)
- Backend SHOULD run on 5555 (Express API)
- Don't change these - the proxy handles everything

### Dispatcher Can't Login
- Verify dispatcher was created successfully
- Check email and password are correct
- Dispatchers login at: /event-frontend/dispatcher.html
- Not the admin panel login page

## Next Steps
Now that dispatcher registration is complete, you can:
1. ✅ Register multiple dispatchers through admin panel
2. ✅ Assign orders to dispatchers
3. ✅ Track dispatcher performance
4. ✅ Manage dispatcher wallet balances
5. ✅ Monitor real-time order assignments

## Support
If you encounter any issues:
1. Check backend logs in the terminal running `npm start`
2. Check browser console for frontend errors (F12)
3. Run test script: `node test-dispatcher-registration.js`
4. Verify both servers are running on correct ports
