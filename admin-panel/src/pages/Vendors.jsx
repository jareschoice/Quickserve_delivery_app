import { useState, useEffect } from 'react'
import axios from 'axios'

const Vendors = () => {
  const [vendors, setVendors] = useState([])
  const [loading, setLoading] = useState(true)
  const [editingVendor, setEditingVendor] = useState(null)
  const [editForm, setEditForm] = useState({
    storeName: '',
    businessName: '',
    businessAddress: '',
    businessPhone: '',
    category: '',
    isActive: true
  })

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

  const handleEditVendor = (vendor) => {
    setEditingVendor(vendor._id)
    setEditForm({
      storeName: vendor.storeName || '',
      businessName: vendor.businessName || '',
      businessAddress: vendor.businessAddress || '',
      businessPhone: vendor.businessPhone || '',
      category: vendor.category || '',
      isActive: vendor.isActive !== false
    })
  }

  const handleSaveVendor = async (vendorId) => {
    try {
      const token = localStorage.getItem('adminToken')
      await axios.put(`/api/admin/vendors/${vendorId}`, editForm, {
        headers: { Authorization: `Bearer ${token}` }
      })
      alert('Vendor updated successfully!')
      setEditingVendor(null)
      fetchVendors()
    } catch (error) {
      alert('Failed to update vendor: ' + (error.response?.data?.error || error.message))
    }
  }

  const handleCancelEdit = () => {
    setEditingVendor(null)
    setEditForm({
      storeName: '',
      businessName: '',
      businessAddress: '',
      businessPhone: '',
      category: '',
      isActive: true
    })
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
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Business Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Category</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Owner</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">KYC Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Wallet</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {vendors.map(vendor => (
              <tr key={vendor._id}>
                <td className="px-6 py-4 whitespace-nowrap">
                  {editingVendor === vendor._id ? (
                    <input
                      type="text"
                      value={editForm.storeName}
                      onChange={(e) => setEditForm({ ...editForm, storeName: e.target.value })}
                      className="border rounded px-2 py-1 w-full"
                    />
                  ) : (
                    <span className="font-medium">{vendor.storeName || 'N/A'}</span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {editingVendor === vendor._id ? (
                    <input
                      type="text"
                      value={editForm.businessName}
                      onChange={(e) => setEditForm({ ...editForm, businessName: e.target.value })}
                      className="border rounded px-2 py-1 w-full"
                    />
                  ) : (
                    <span>{vendor.businessName || 'N/A'}</span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {editingVendor === vendor._id ? (
                    <select
                      value={editForm.category}
                      onChange={(e) => setEditForm({ ...editForm, category: e.target.value })}
                      className="border rounded px-2 py-1 w-full"
                    >
                      <option value="">Select category</option>
                      <option value="restaurant">Restaurant</option>
                      <option value="pharmacy">Pharmacy</option>
                      <option value="shop">Shop</option>
                      <option value="supermarket">Supermarket</option>
                      <option value="minimart">Mini Mart</option>
                      <option value="market">Local Market</option>
                    </select>
                  ) : (
                    <span>{vendor.category || 'N/A'}</span>
                  )}
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
                  {editingVendor === vendor._id ? (
                    <select
                      value={editForm.isActive}
                      onChange={(e) => setEditForm({ ...editForm, isActive: e.target.value === 'true' })}
                      className="border rounded px-2 py-1"
                    >
                      <option value="true">Active</option>
                      <option value="false">Inactive</option>
                    </select>
                  ) : (
                    <span className={`px-2 py-1 text-xs rounded-full ${
                      vendor.isActive !== false ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {vendor.isActive !== false ? 'Active' : 'Inactive'}
                    </span>
                  )}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex gap-2">
                    {editingVendor === vendor._id ? (
                      <>
                        <button
                          onClick={() => handleSaveVendor(vendor._id)}
                          className="bg-green-500 text-white px-3 py-1 rounded hover:bg-green-600 text-sm"
                        >
                          Save
                        </button>
                        <button
                          onClick={handleCancelEdit}
                          className="bg-gray-500 text-white px-3 py-1 rounded hover:bg-gray-600 text-sm"
                        >
                          Cancel
                        </button>
                      </>
                    ) : (
                      <>
                        <button
                          onClick={() => handleEditVendor(vendor)}
                          className="bg-blue-500 text-white px-3 py-1 rounded hover:bg-blue-600 text-sm"
                        >
                          Edit
                        </button>
                        {vendor.user?.kycStatus === 'pending' && (
                          <button
                            onClick={() => handleApproveKYC(vendor.user._id)}
                            className="bg-green-500 text-white px-3 py-1 rounded hover:bg-green-600 text-sm"
                          >
                            Approve KYC
                          </button>
                        )}
                      </>
                    )}
                  </div>
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

      {/* Edit Modal could be added here for better UX */}
    </div>
  )
}

export default Vendors
