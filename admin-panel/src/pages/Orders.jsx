import { useState, useEffect } from 'react'
import axios from 'axios'

const Orders = () => {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchOrders()
  }, [])

  const fetchOrders = async () => {
    try {
      const token = localStorage.getItem('adminToken')
      const response = await axios.get('/api/admin/orders', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setOrders(response.data.orders || [])
    } catch (error) {
      console.error('Failed to fetch orders:', error)
    } finally {
      setLoading(false)
    }
  }

  const getStatusColor = (status) => {
    const colors = {
      placed: 'bg-blue-100 text-blue-800',
      accepted: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      packed: 'bg-purple-100 text-purple-800',
      delivered: 'bg-green-500 text-white',
      cancelled: 'bg-gray-100 text-gray-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  if (loading) {
    return <div>Loading orders...</div>
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Orders Management</h1>

      <div className="grid grid-cols-1 gap-4">
        {orders.map(order => (
          <div key={order._id} className="bg-white rounded-lg shadow p-6">
            <div className="flex justify-between items-start mb-4">
              <div>
                <h3 className="font-semibold text-lg">Order #{order._id?.slice(-8)}</h3>
                <p className="text-sm text-gray-500">
                  {new Date(order.createdAt).toLocaleString()}
                </p>
              </div>
              <span className={`px-3 py-1 rounded-full text-sm ${getStatusColor(order.status)}`}>
                {order.status}
              </span>
            </div>

            <div className="grid grid-cols-3 gap-4 mb-4">
              <div>
                <p className="text-sm text-gray-500">Customer</p>
                <p className="font-medium">{order.customer?.name || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Vendor</p>
                <p className="font-medium">{order.vendor?.storeName || 'N/A'}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500">Total</p>
                <p className="font-medium">₦{(order.total || 0).toLocaleString()}</p>
              </div>
            </div>

            <div>
              <p className="text-sm text-gray-500 mb-2">Items:</p>
              {order.items?.map((item, idx) => (
                <div key={idx} className="flex justify-between text-sm">
                  <span>{item.name} × {item.quantity}</span>
                  <span>₦{item.price?.toLocaleString()}</span>
                </div>
              ))}
            </div>
          </div>
        ))}

        {orders.length === 0 && (
          <div className="bg-white rounded-lg shadow p-8 text-center text-gray-500">
            No orders found
          </div>
        )}
      </div>
    </div>
  )
}

export default Orders
