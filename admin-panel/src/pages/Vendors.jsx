import { useState, useEffect } from 'react'
import axios from 'axios'

const Vendors = () => {
  const [vendors, setVendors] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchVendors()
  }, [])

  const fetchVendors = async () => {
    try {
      const token = localStorage.getItem('adminToken')
      const response = await axios.get('/api/admin/vendors', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setVendors(response.data.vendors || [])
    } catch (error) {
      console.error('Failed to fetch vendors:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleApproveKYC = async (userId) => {
    try {
      const token = localStorage.getItem('adminToken')
      await axios.post('/api/kyc/verify', 
        { userId, status: 'approved' },
        { headers: { Authorization: `Bearer ${token}` } }
      )
      alert('KYC Approved!')
      fetchVendors()
    } catch (error) {
      alert('Failed to approve KYC')
    }
  }

  if (loading) {
    return <div>Loading vendors...</div>
  }

  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Vendors Management</h1>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Store Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Owner</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">KYC Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Wallet</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {vendors.map(vendor => (
              <tr key={vendor._id}>
                <td className="px-6 py-4 whitespace-nowrap font-medium">
                  {vendor.storeName || 'N/A'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {vendor.user?.name || 'N/A'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 py-1 text-xs rounded-full ${
                    vendor.user?.kycStatus === 'approved' ? 'bg-green-100 text-green-800' :
                    vendor.user?.kycStatus === 'pending' ? 'bg-yellow-100 text-yellow-800' :
                    'bg-gray-100 text-gray-800'
                  }`}>
                    {vendor.user?.kycStatus || 'none'}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  ₦{(vendor.wallet || 0).toLocaleString()}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {vendor.user?.kycStatus === 'pending' && (
                    <button
                      onClick={() => handleApproveKYC(vendor.user._id)}
                      className="bg-green-500 text-white px-3 py-1 rounded hover:bg-green-600"
                    >
                      Approve KYC
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {vendors.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            No vendors found
          </div>
        )}
      </div>
    </div>
  )
}

export default Vendors
