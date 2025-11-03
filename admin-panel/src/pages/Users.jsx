import { useState, useEffect } from 'react'
import axios from 'axios'

const Users = () => {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all') // all, customer, vendor, rider

  useEffect(() => {
    fetchUsers()
  }, [])

  const fetchUsers = async () => {
    try {
      const token = localStorage.getItem('adminToken')
      const response = await axios.get('/api/admin/users', {
        headers: { Authorization: `Bearer ${token}` }
      })
      setUsers(response.data.users || [])
    } catch (error) {
      console.error('Failed to fetch users:', error)
    } finally {
      setLoading(false)
    }
  }

  const filteredUsers = filter === 'all' 
    ? users 
    : users.filter(u => u.role === filter)

  const getRoleBadgeColor = (role) => {
    const colors = {
      customer: 'bg-blue-100 text-blue-800',
      vendor: 'bg-green-100 text-green-800',
      rider: 'bg-purple-100 text-purple-800',
      admin: 'bg-red-100 text-red-800'
    }
    return colors[role] || 'bg-gray-100 text-gray-800'
  }

  if (loading) {
    return <div>Loading users...</div>
  }

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Users Management</h1>
        <div className="flex gap-2">
          {['all', 'customer', 'vendor', 'rider'].map(role => (
            <button
              key={role}
              onClick={() => setFilter(role)}
              className={`px-4 py-2 rounded-lg capitalize ${
                filter === role 
                  ? 'bg-blue-600 text-white' 
                  : 'bg-white text-gray-700 border'
              }`}
            >
              {role}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Role</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Verified</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Joined</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {filteredUsers.map(user => (
              <tr key={user._id}>
                <td className="px-6 py-4 whitespace-nowrap">{user.name}</td>
                <td className="px-6 py-4 whitespace-nowrap">{user.email}</td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`px-2 py-1 text-xs rounded-full ${getRoleBadgeColor(user.role)}`}>
                    {user.role}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {user.isVerified ? '✅' : '❌'}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  {new Date(user.createdAt).toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        
        {filteredUsers.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            No {filter !== 'all' ? filter : ''} users found
          </div>
        )}
      </div>
    </div>
  )
}

export default Users
