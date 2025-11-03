import { useState, useEffect } from 'react'
import axios from 'axios'
import { Users, Store, Package, DollarSign, Wallet } from 'lucide-react'

const Dashboard = () => {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalVendors: 0,
    totalOrders: 0,
    totalRevenue: 0,
    platformEarnings: 0,
    adminWallet: 0
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchStats()
  }, [])

  const fetchStats = async () => {
    try {
      const token = localStorage.getItem('adminToken')
      
      // Fetch users
      const usersRes = await axios.get('/api/admin/users', {
        headers: { Authorization: `Bearer ${token}` }
      })
      
      // Fetch orders
      const ordersRes = await axios.get('/api/admin/orders', {
        headers: { Authorization: `Bearer ${token}` }
      })

      const users = usersRes.data.users || []
      const orders = ordersRes.data.orders || []
      
      const vendors = users.filter(u => u.role === 'vendor')
      const totalRevenue = orders.reduce((sum, order) => sum + (order.total || 0), 0)
      
      // Calculate platform earnings (₦50 per order from commission)
      const platformEarnings = orders.filter(o => o.status !== 'cancelled').length * 50
      
      // Get admin wallet (sum of all admin user wallets)
      const adminUsers = users.filter(u => u.role === 'admin')
      const adminWallet = adminUsers.reduce((sum, admin) => sum + (admin.wallet || 0), 0)

      setStats({
        totalUsers: users.length,
        totalVendors: vendors.length,
        totalOrders: orders.length,
        totalRevenue,
        platformEarnings,
        adminWallet
      })
    } catch (error) {
      console.error('Failed to fetch stats:', error)
    } finally {
      setLoading(false)
    }
  }

  const StatCard = ({ icon: Icon, title, value, color }) => (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-gray-500 text-sm">{title}</p>
          <p className="text-3xl font-bold mt-2">{value}</p>
        </div>
        <div className={`p-3 rounded-full ${color}`}>
          <Icon className="text-white" size={24} />
        </div>
      </div>
    </div>
  )

  if (loading) {
    return <div>Loading...</div>
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-8">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard
          icon={Users}
          title="Total Users"
          value={stats.totalUsers}
          color="bg-blue-500"
        />
        <StatCard
          icon={Store}
          title="Total Vendors"
          value={stats.totalVendors}
          color="bg-green-500"
        />
        <StatCard
          icon={Package}
          title="Total Orders"
          value={stats.totalOrders}
          color="bg-purple-500"
        />
        <StatCard
          icon={DollarSign}
          title="Total Revenue"
          value={`₦${stats.totalRevenue.toLocaleString()}`}
          color="bg-orange-500"
        />
      </div>

      {/* Virtual Wallet Section */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-lg shadow-lg p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-green-100 text-sm font-medium">Platform Earnings</p>
              <p className="text-3xl font-bold mt-2">₦{stats.platformEarnings.toLocaleString()}</p>
              <p className="text-green-100 text-xs mt-1">From {stats.totalOrders} orders (₦50 each)</p>
            </div>
            <div className="p-4 bg-white bg-opacity-20 rounded-full">
              <Wallet size={32} />
            </div>
          </div>
          <div className="pt-4 border-t border-green-400">
            <p className="text-sm text-green-100">Commission collected from completed orders</p>
          </div>
        </div>

        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg shadow-lg p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-blue-100 text-sm font-medium">Admin Wallet Balance</p>
              <p className="text-3xl font-bold mt-2">₦{stats.adminWallet.toLocaleString()}</p>
              <p className="text-blue-100 text-xs mt-1">Available for withdrawal</p>
            </div>
            <div className="p-4 bg-white bg-opacity-20 rounded-full">
              <DollarSign size={32} />
            </div>
          </div>
          <div className="pt-4 border-t border-blue-400">
            <button className="bg-white text-blue-600 px-4 py-2 rounded-lg font-medium hover:bg-blue-50 transition">
              Withdraw Funds
            </button>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-xl font-semibold mb-4">Welcome to QuickServe Admin Panel</h2>
        <p className="text-gray-600">
          Use the sidebar to navigate through different sections. You can manage users, vendors, orders, payments, and more.
        </p>
        <div className="mt-4 grid grid-cols-3 gap-4 text-sm">
          <div className="bg-gray-50 p-3 rounded">
            <p className="text-gray-500">Commission Rate</p>
            <p className="font-bold text-lg">₦50/order</p>
          </div>
          <div className="bg-gray-50 p-3 rounded">
            <p className="text-gray-500">Active Vendors</p>
            <p className="font-bold text-lg">{stats.totalVendors}</p>
          </div>
          <div className="bg-gray-50 p-3 rounded">
            <p className="text-gray-500">Pending Orders</p>
            <p className="font-bold text-lg">{stats.totalOrders}</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default Dashboard
