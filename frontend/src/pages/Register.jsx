import { useState } from "react"
import API from "../api"

export default function Register() {
  const [form, setForm] = useState({ name: "", email: "", password: "" })
  const [msg, setMsg] = useState("")
  const [loading, setLoading] = useState(false)

  const handleChange = (e) => setForm({ ...form, [e.target.name]: e.target.value })

  const handleSubmit = async (e) => {
    e.preventDefault()
    setMsg("")
    setLoading(true)
    try {
      const { data } = await API.post("/auth/register/customer", form)
      setMsg(data.message || "✅ Registration successful! Check your email.")
    } catch (err) {
      setMsg(err.response?.data?.error || "❌ Something went wrong.")
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-600 via-green-500 to-orange-400">
      <form onSubmit={handleSubmit} className="bg-white shadow-2xl rounded-3xl p-8 w-[95%] max-w-md">
        <h2 className="text-3xl font-bold text-center text-green-700 mb-2">Create Account</h2>
        <p className="text-center text-gray-600 mb-6">Join QuickServe and order easily!</p>

        <input
          name="name"
          placeholder="Full Name"
          onChange={handleChange}
          className="border border-gray-300 p-3 w-full mb-3 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
          required
        />
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
          {loading ? "Creating Account..." : "Register"}
        </button>

        {msg && (
          <p
            className={`text-center mt-4 ${
              msg.startsWith("✅") ? "text-green-600" : "text-red-600"
            }`}
          >
            {msg}
          </p>
        )}

        <p className="text-center text-sm text-gray-600 mt-4">
          Already have an account?{" "}
          <a href="/login" className="text-green-700 font-semibold hover:underline">
            Login
          </a>
        </p>
      </form>
    </div>
  )
}
