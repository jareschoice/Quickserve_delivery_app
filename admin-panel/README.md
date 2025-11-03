# QuickServe Admin Panel

Modern web-based admin dashboard for managing the QuickServe delivery platform.

## Features

- 📊 **Dashboard** - Real-time statistics and analytics
- 👥 **User Management** - View and manage customers, vendors, riders
- 🏪 **Vendor Management** - Approve KYC, monitor store performance
- 📦 **Order Management** - Track all orders and their status
- 💰 **Payment Management** - Monitor transactions and revenue
- 🚴 **Rider Management** - Manage delivery personnel
- ⚙️ **Settings** - Configure platform commissions and settings

## Tech Stack

- **Frontend**: React 18 + Vite
- **UI Framework**: Tailwind CSS
- **Charts**: Recharts
- **Icons**: Lucide React
- **HTTP Client**: Axios
- **Routing**: React Router v6

## Setup Instructions

### 1. Install Dependencies

```powershell
cd C:\Users\HP-PC\Desktop\quickserve\admin-panel
npm install
```

### 2. Create Admin User

```powershell
cd C:\Users\HP-PC\Desktop\quickserve\backend
node create-admin.js
```

This will create an admin account with:
- **Email**: admin@quickserve.com
- **Password**: Admin123!

### 3. Start Backend Server (if not running)

```powershell
cd C:\Users\HP-PC\Desktop\quickserve\backend
npm run dev
```

Backend will run on: http://localhost:5555

### 4. Start Admin Panel

```powershell
cd C:\Users\HP-PC\Desktop\quickserve\admin-panel
npm run dev
```

Admin panel will run on: http://localhost:3000

### 5. Access Admin Panel

1. Open browser: http://localhost:3000
2. Login with:
   - Email: admin@quickserve.com
   - Password: Admin123!

## Folder Structure

```
admin-panel/
├── src/
│   ├── components/
│   │   └── Layout.jsx         # Sidebar navigation
│   ├── pages/
│   │   ├── Dashboard.jsx      # Main dashboard
│   │   ├── Users.jsx          # User management
│   │   ├── Vendors.jsx        # Vendor management
│   │   ├── Orders.jsx         # Order tracking
│   │   ├── Payments.jsx       # Payment history
│   │   ├── Riders.jsx         # Rider management
│   │   └── Settings.jsx       # Platform settings
│   ├── App.jsx                # Main app component
│   ├── main.jsx               # Entry point
│   └── index.css              # Global styles
├── package.json
├── vite.config.js
└── tailwind.config.js
```

## Available Routes

- `/` - Dashboard with statistics
- `/users` - User management
- `/vendors` - Vendor management with KYC approval
- `/orders` - All orders with status tracking
- `/payments` - Payment transactions
- `/riders` - Rider management
- `/settings` - Platform configuration

## API Endpoints Used

- `GET /api/admin/users` - Get all users
- `GET /api/admin/vendors` - Get all vendors
- `GET /api/admin/orders` - Get all orders
- `GET /api/admin/stats` - Get dashboard statistics
- `POST /api/kyc/verify` - Approve vendor KYC

## Building for Production

```powershell
npm run build
```

This creates optimized files in the `dist/` folder.

## Troubleshooting

### Port Already in Use

If port 3000 is busy, edit `vite.config.js`:

```javascript
server: {
  port: 3001, // Change to any available port
  // ...
}
```

### Backend Connection Issues

Make sure:
1. Backend server is running on port 5555
2. Admin user exists in database
3. You're logged in with admin credentials

## Security Notes

⚠️ **IMPORTANT**:
- Change default admin password after first login
- Use HTTPS in production
- Enable CORS only for trusted domains
- Keep JWT secret secure
- Regular backup of admin credentials

## Support

For issues or questions, contact the development team.
