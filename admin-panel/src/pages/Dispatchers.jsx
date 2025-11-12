import { useState, useEffect } from 'react'
import axios from 'axios'
import { Truck, UserPlus, X } from 'lucide-react'

const Dispatchers = () => {
  const [dispatchers, setDispatchers] = useState([])
  const [loading, setLoading] = useState(true)
  const [showForm, setShowForm] = useState(false)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    phone: ''
  })
  const [formLoading, setFormLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  useEffect(() => {
    fetchDispatchers()
  }, [])

  const fetchDispatchers = async () => {
    try {
      const token = localStorage.getItem('adminToken')
      const usersRes = await axios.get('/api/admin/users', {
        headers: { Authorization: `Bearer ${token}` }
      })
      const allUsers = usersRes.data.users || []
      setDispatchers(allUsers.filter(u => u.role === 'dispatcher'))
    } catch (error) {
      console.error('Failed to fetch dispatchers:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    })
    setError('')
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    setFormLoading(true)

    try {
      const token = localStorage.getItem('adminToken')
      await axios.post('/api/admin/dispatchers', formData, {
        headers: { Authorization: `Bearer ${token}` }
      })
      
      setSuccess('Dispatcher registered successfully!')
      setFormData({ name: '', email: '', password: '', phone: '' })
      setShowForm(false)
      fetchDispatchers() // Refresh the list
    } catch (error) {
      setError(error.response?.data?.error || 'Failed to register dispatcher')
    } finally {
      setFormLoading(false)
    }
  }

  const handleToggleActive = async (dispatcherId, currentStatus) => {
    try {
      const token = localStorage.getItem('adminToken')
      await axios.put(`/api/admin/dispatchers/${dispatcherId}`, 
        { isActive: !currentStatus },
        { headers: { Authorization: `Bearer ${token}` } }
      )
      fetchDispatchers()
    } catch (error) {
      console.error('Failed to toggle dispatcher status:', error)
    }
  }

  if (loading) {
    return <div>Loading dispatchers...</div>
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Dispatchers Management</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors"
        >
          {showForm ? <X size={20} /> : <UserPlus size={20} />}
          {showForm ? 'Cancel' : 'Add Dispatcher'}
        </button>
      </div>

      {/* Registration Form */}
      {showForm && (
        <div className="bg-white rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Register New Dispatcher</h2>
          
          {error && (
            <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded mb-4">
              {error}
            </div>
          )}

          {success && (
            <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded mb-4">
              {success}
            </div>
          )}

          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Full Name *
              </label>
              <input
                type="text"
                name="name"
                value={formData.name}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="John Doe"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Email *
              </label>
              <input
                type="email"
                name="email"
                value={formData.email}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="dispatcher@example.com"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Phone Number *
              </label>
              <input
                type="tel"
                name="phone"
                value={formData.phone}
                onChange={handleInputChange}
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="+234 xxx xxx xxxx"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Password *
              </label>
              <input
                type="password"
                name="password"
                value={formData.password}
                onChange={handleInputChange}
                required
                minLength="6"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Min 6 characters"
              />
            </div>

            <div className="md:col-span-2">
              <button
                type="submit"
                disabled={formLoading}
                className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-400"
              >
                {formLoading ? 'Registering...' : 'Register Dispatcher'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Dispatchers List */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Phone</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">KYC</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Wallet</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {dispatchers.map(dispatcher => (
              <tr key={dispatcher._id}>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center gap-2">
                    <Truck size={16} className="text-blue-600" />
                    {dispatcher.name}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">{dispatcher.email}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {dispatcher.profile?.phone || dispatcher.phone || 'N/A'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    dispatcher.isActive !== false ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  }`}>
                    {dispatcher.isActive !== false ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    dispatcher.kycStatus === 'approved' ? 'bg-green-100 text-green-800' :
                    dispatcher.kycStatus === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {dispatcher.kycStatus || 'none'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  ₦{(dispatcher.wallet || 0).toLocaleString()}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <button
                    onClick={() => handleToggleActive(dispatcher._id, dispatcher.isActive !== false)}
                    className={`px-3 py-1 text-xs rounded ${
                      dispatcher.isActive !== false
                        ? 'bg-red-100 text-red-700 hover:bg-red-200'
                        : 'bg-green-100 text-green-700 hover:bg-green-200'
                    }`}
                  >
                    {dispatcher.isActive !== false ? 'Deactivate' : 'Activate'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {dispatchers.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            No dispatchers found. Click "Add Dispatcher" to register one.
          </div>
        )}
      </div>
    </div>
  )
}

export default Dispatchers
