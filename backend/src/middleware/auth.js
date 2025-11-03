// ===============================
// FILE: src/middleware/auth.js
// ===============================
import jwt from "jsonwebtoken";

// Map role aliases (e.g., consumer → customer)
const mapAlias = (r) => {
  if (!r) return r;
  if (r === "consumer") return "customer";
  return r;
};

export const authRequired = (...roles) => {
  return (req, res, next) => {
    const authHeader = req.headers?.authorization;

    console.log("🧩 [AUTH] Middleware reached for", req.originalUrl);

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      console.log("❌ [AUTH] Missing or invalid Authorization header");
      return res.status(401).json({ error: "Authorization header missing or invalid" });
    }

    const token = authHeader.split(" ")[1];
    let decoded;

    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = {
        _id: decoded.id || decoded._id,
        role: decoded.role,
        email: decoded.email || null,
      };
      console.log("✅ [AUTH] Token verified:", req.user);

      // ✅ Role-based validation
      if (roles.length > 0) {
        const allowed = roles.map(mapAlias);
        if (!allowed.includes(req.user.role)) {
          console.log("🚫 [AUTH] Forbidden role:", req.user.role, "| Allowed:", allowed);
          return res.status(403).json({ error: "Forbidden: insufficient permissions" });
        }
      }

      console.log("➡️ [AUTH] Passing control to next()...");
      return next();
    } catch (err) {
      console.error("❌ [AUTH] Token verification failed:", err.message);
      return res.status(401).json({ error: "Invalid or expired token" });
    }
  };
};
