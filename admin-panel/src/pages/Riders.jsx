import { useState, useEffect } from 'react'
import axios from 'axios'

const Riders = () => {
  const [riders, setRiders] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchRiders()
  }, [])

  const fetchRiders = async () => {
    try {
      const token = localStorage.getItem('adminToken')
      const usersRes = await axios.get('/api/admin/users', {
        headers: { Authorization: `Bearer ${token}` }
      })
      const allUsers = usersRes.data.users || []
      setRiders(allUsers.filter(u => u.role === 'rider'))
    } catch (error) {
      console.error('Failed to fetch riders:', error)
    } finally {
      setLoading(false)
    }
  }

  if (loading) {
    return <div>Loading riders...</div>
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Riders Management</h1>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Phone</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Vehicle</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">KYC Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Wallet</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {riders.map(rider => (
              <tr key={rider._id}>
                <td className="px-6 py-4 whitespace-nowrap">{rider.name}</td>
                <td className="px-6 py-4 whitespace-nowrap">{rider.email}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {rider.profile?.phone || 'N/A'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {rider.profile?.vehicleType || 'N/A'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    rider.kycStatus === 'approved' ? 'bg-green-100 text-green-800' :
                    rider.kycStatus === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {rider.kycStatus || 'none'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  ₦{(rider.wallet || 0).toLocaleString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {riders.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            No riders found
          </div>
        )}
      </div>
    </div>
  )
}

export default Riders
