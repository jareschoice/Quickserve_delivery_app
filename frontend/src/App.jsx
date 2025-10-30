import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom"
import Register from "./pages/Register"
import Verify from "./pages/Verify"
import Login from "./pages/Login"
import Dashboard from "./pages/Dashboard"

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/register" />} />
        <Route path="/register" element={<Register />} />
        <Route path="/verify" element={<Verify />} />
        <Route path="/login" element={<Login />} />
        <Route path="/dashboard" element={<Dashboard />} />
      </Routes>
    </BrowserRouter>
  )
}
