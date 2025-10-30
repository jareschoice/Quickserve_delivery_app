import { useEffect, useState } from "react"
import { useSearchParams } from "react-router-dom"
import API from "../api"

export default function Verify() {
  const [search] = useSearchParams()
  const [msg, setMsg] = useState("Verifying your account...")

  useEffect(() => {
    const token = search.get("token")
    if (!token) return setMsg("❌ Invalid verification link.")
    API.get(`/auth/verify?token=${token}`)
      .then(() => setMsg("✅ Email verified successfully! You can now log in."))
      .catch(() => setMsg("❌ Verification failed or expired."))
  }, [search])

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-green-600 via-green-500 to-orange-400">
      <div className="bg-white p-8 rounded-3xl shadow-2xl w-[95%] max-w-md text-center">
        <h1 className="text-3xl font-bold text-green-700 mb-3">QuickServe</h1>
        <p className="text-gray-700">{msg}</p>
        <a
          href="/login"
          className="inline-block mt-5 bg-green-600 hover:bg-green-700 text-white py-2 px-6 rounded-lg"
        >
          Go to Login
        </a>
      </div>
    </div>
  )
}
