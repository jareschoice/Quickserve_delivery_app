import { useState } from "react"
import API from "../api"

export default function Login() {
  const [form, setForm] = useState({ email: "", password: "" })
  const [msg, setMsg] = useState("")
  const [loading, setLoading] = useState(false)

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value })

  const handleSubmit = async (e) => {
    e.preventDefault()
    setMsg("")
    setLoading(true)
    try {
      const { data } = await API.post("/auth/login", form)
      localStorage.setItem("token", data.token)
      localStorage.setItem("user", JSON.stringify(data.user))
      window.location.href = "/dashboard"
    } catch (err) {
      setMsg(err.response?.data?.error || "❌ Login failed")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-600 via-green-500 to-orange-400">
      <form onSubmit={handleSubmit} className="bg-white shadow-2xl rounded-3xl p-8 w-[95%] max-w-md">
        <h2 className="text-3xl font-bold text-center text-green-700 mb-2">Login</h2>
        <p className="text-center text-gray-600 mb-6">Welcome back to QuickServe!</p>

        <input
          name="email"
          type="email"
          placeholder="Email Address"
          onChange={handleChange}
          className="border border-gray-300 p-3 w-full mb-3 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
          required
        />
        <input
          name="password"
          type="password"
          placeholder="Password"
          onChange={handleChange}
          className="border border-gray-300 p-3 w-full mb-5 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
          required
        />

        <button
          type="submit"
          disabled={loading}
          className="bg-green-600 hover:bg-green-700 text-white font-semibold w-full py-3 rounded-lg transition"
        >
          {loading ? "Logging in..." : "Login"}
        </button>

        {msg && (
          <p className={`text-center mt-4 ${msg.startsWith("✅") ? "text-green-600" : "text-red-600"}`}>
            {msg}
          </p>
        )}

        <p className="text-center text-sm text-gray-600 mt-4">
          Don’t have an account?{" "}
          <a href="/register" className="text-green-700 font-semibold hover:underline">
            Register
          </a>
        </p>
      </form>
    </div>
  )
}
