import { useState, useEffect } from 'react'
import axios from 'axios'

const API_BASE = 'http://localhost:5555/api'

const Subscriptions = () => {
  const [subscriptions, setSubscriptions] = useState([])
  const [todayDeliveries, setTodayDeliveries] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [selectedSub, setSelectedSub] = useState(null)
  const [statusDialog, setStatusDialog] = useState(false)
  const [newStatus, setNewStatus] = useState('')

  const token = localStorage.getItem('adminToken')

  useEffect(() => {
    fetchData()
    const interval = setInterval(fetchTodayDeliveries, 60000)
    return () => clearInterval(interval)
  }, [])

  const fetchData = async () => {
    try {
      await Promise.all([fetchSubscriptions(), fetchTodayDeliveries()])
      setLoading(false)
    } catch (err) {
      setError(err.message)
      setLoading(false)
    }
  }

  const fetchSubscriptions = async () => {
    const res = await axios.get(`${API_BASE}/subscriptions/admin/all`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    setSubscriptions(res.data.items || [])
  }

  const fetchTodayDeliveries = async () => {
    const res = await axios.get(`${API_BASE}/subscriptions/admin/today-deliveries`, {
      headers: { Authorization: `Bearer ${token}` }
    })
    setTodayDeliveries(res.data.deliveries || [])
  }

  const handleStatusChange = async () => {
    try {
      await axios.post(
        `${API_BASE}/subscriptions/${selectedSub._id}/status`,
        { status: newStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      )
      setStatusDialog(false)
      fetchSubscriptions()
    } catch (err) {
      alert('Error updating status: ' + err.message)
    }
  }

  const getStatusColor = (status) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      active: 'bg-green-100 text-green-800',
      paused: 'bg-gray-100 text-gray-800',
      cancelled: 'bg-red-100 text-red-800',
      expired: 'bg-red-100 text-red-800'
    }
    return colors[status] || 'bg-gray-100 text-gray-800'
  }

  const getPlanColor = (plan) => {
    const colors = {
      basic: 'bg-green-500',
      standard: 'bg-orange-500',
      premium: 'bg-purple-500'
    }
    return colors[plan] || 'bg-gray-500'
  }

  const getMealScheduleBadges = (mealSchedule) => {
    if (!mealSchedule) return '-'
    const meals = []
    if (mealSchedule.breakfast?.enabled)
      meals.push(`🍳 Breakfast (${mealSchedule.breakfast.time})`)
    if (mealSchedule.lunch?.enabled)
      meals.push(`🍱 Lunch (${mealSchedule.lunch.time})`)
    if (mealSchedule.dinner?.enabled)
      meals.push(`🍽️ Dinner (${mealSchedule.dinner.time})`)
    return meals.join(', ') || '-'
  }

  if (loading) return <div className="p-6">Loading subscriptions...</div>

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold text-orange-600 mb-6">📦 Special Meal Subscriptions</h1>

      {/* Today's Deliveries Alert */}
      {todayDeliveries.length > 0 && (
        <div className="bg-blue-50 border-l-4 border-blue-400 p-4 mb-6">
          <h3 className="text-lg font-semibold text-blue-800 mb-3">
            🚨 Today's Scheduled Deliveries ({todayDeliveries.length})
          </h3>
          {todayDeliveries.map((delivery, idx) => (
            <div key={idx} className="bg-white p-3 rounded mb-2">
              <p className="text-sm font-medium">
                <strong>{delivery.mealType?.toUpperCase()}</strong> at {delivery.scheduledTime} -{' '}
                {delivery.user?.name} ({delivery.user?.phone})
              </p>
              <p className="text-xs text-gray-600">
                Plan: {delivery.plan} | Address: {delivery.deliveryAddress}
              </p>
            </div>
          ))}
        </div>
      )}

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <div className="bg-gradient-to-br from-green-500 to-green-400 rounded-lg p-6 text-white">
          <h3 className="text-sm font-semibold mb-2">Active Subscriptions</h3>
          <p className="text-4xl font-bold">
            {subscriptions.filter((s) => s.status === 'active').length}
          </p>
        </div>
        <div className="bg-gradient-to-br from-yellow-500 to-yellow-400 rounded-lg p-6 text-white">
          <h3 className="text-sm font-semibold mb-2">Pending Payment</h3>
          <p className="text-4xl font-bold">
            {subscriptions.filter((s) => s.status === 'pending').length}
          </p>
        </div>
        <div className="bg-gradient-to-br from-blue-500 to-blue-400 rounded-lg p-6 text-white">
          <h3 className="text-sm font-semibold mb-2">Total Revenue</h3>
          <p className="text-4xl font-bold">
            ₦{subscriptions
              .filter((s) => s.status === 'active')
              .reduce((sum, s) => sum + s.amount, 0)
              .toLocaleString()}
          </p>
        </div>
        <div className="bg-gradient-to-br from-purple-500 to-purple-400 rounded-lg p-6 text-white">
          <h3 className="text-sm font-semibold mb-2">Today's Deliveries</h3>
          <p className="text-4xl font-bold">{todayDeliveries.length}</p>
        </div>
      </div>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      {/* Subscriptions Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-orange-600">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Customer</th>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Plan</th>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Amount</th>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Meal Schedule</th>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Delivery Address</th>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Period</th>
              <th className="px-6 py-3 text-left text-xs font-bold text-white uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {subscriptions.map((sub) => (
              <tr key={sub._id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900">{sub.user?.name || 'N/A'}</div>
                  <div className="text-xs text-gray-500">{sub.user?.phone || 'N/A'}</div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-3 py-1 rounded-full text-xs font-bold text-white ${getPlanColor(sub.plan)}`}>
                    {sub.plan?.toUpperCase()}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm">₦{sub.amount?.toLocaleString()}</td>
                <td className="px-6 py-4 text-xs">{getMealScheduleBadges(sub.mealSchedule)}</td>
                <td className="px-6 py-4 text-xs max-w-xs truncate">{sub.deliveryAddress}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 py-1 rounded text-xs font-medium ${getStatusColor(sub.status)}`}>
                    {sub.status?.toUpperCase()}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-xs">
                  {sub.periodStart ? (
                    <>
                      {new Date(sub.periodStart).toLocaleDateString()} -{' '}
                      {new Date(sub.periodEnd).toLocaleDateString()}
                    </>
                  ) : '-'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <button
                    onClick={() => {
                      setSelectedSub(sub)
                      setNewStatus(sub.status)
                      setStatusDialog(true)
                    }}
                    className="text-sm px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
                  >
                    Manage
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Status Change Modal */}
      {statusDialog && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h2 className="text-xl font-bold mb-4">Manage Subscription</h2>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-2">Status</label>
              <select
                value={newStatus}
                onChange={(e) => setNewStatus(e.target.value)}
                className="w-full border border-gray-300 rounded px-3 py-2"
              >
                <option value="pending">Pending</option>
                <option value="active">Active</option>
                <option value="paused">Paused</option>
                <option value="cancelled">Cancelled</option>
                <option value="expired">Expired</option>
              </select>
            </div>
            <div className="flex justify-end space-x-2">
              <button
                onClick={() => setStatusDialog(false)}
                className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleStatusChange}
                className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
              >
                Update Status
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default Subscriptions
