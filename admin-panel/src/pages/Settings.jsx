const Settings = () => {
  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Settings</h1>
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="font-semibold mb-4">Platform Configuration</h3>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-2">Platform Commission</label>
            <input 
              type="number" 
              defaultValue="50" 
              className="border rounded px-3 py-2"
            />
            <p className="text-sm text-gray-500 mt-1">₦50 per order</p>
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Vendor Commission</label>
            <input 
              type="number" 
              defaultValue="50" 
              className="border rounded px-3 py-2"
            />
            <p className="text-sm text-gray-500 mt-1">₦50 per order</p>
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Rider Commission</label>
            <input 
              type="number" 
              defaultValue="50" 
              className="border rounded px-3 py-2"
            />
            <p className="text-sm text-gray-500 mt-1">₦50 per delivery</p>
          </div>
          <button className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">
            Save Settings
          </button>
        </div>
      </div>
    </div>
  )
}

export default Settings
