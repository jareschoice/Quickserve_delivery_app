export default function Dashboard() {
  const user = JSON.parse(localStorage.getItem("user") || "{}")

  const logout = () => {
    localStorage.clear()
    window.location.href = "/login"
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gradient-to-br from-green-600 via-green-500 to-orange-400">
      <div className="bg-white p-8 rounded-3xl shadow-2xl w-[95%] max-w-md text-center">
        <h1 className="text-3xl font-bold text-green-700 mb-3">Welcome, {user.name || "User"}!</h1>
        <p className="text-gray-700">Role: <b>{user.role}</b></p>
        <p className="text-gray-600 mt-2">You are now logged in 🎉</p>
        <button
          onClick={logout}
          className="mt-6 bg-red-600 hover:bg-red-700 text-white px-6 py-2 rounded-lg transition"
        >
          Logout
        </button>
      </div>
    </div>
  )
}
