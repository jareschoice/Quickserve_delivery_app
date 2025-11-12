// ===============================
// FILE: src/middleware/auth.js
// ===============================
import jwt from "jsonwebtoken";

// Map role aliases (e.g., consumer → customer)
const mapAlias = (r) => {
  if (!r) return r;
  if (r === "consumer") return "customer";
  // Allow dispatcher users to access rider-protected endpoints
  if (r === "dispatcher") return "rider";
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

      // ✅ Role-based validation (map both allowed roles and user role aliases)
      if (roles.length > 0) {
        const allowed = roles.map(mapAlias);
        const userRole = mapAlias(req.user.role);
        if (!allowed.includes(userRole)) {
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

// Protect middleware (verify JWT token)
export const protect = (req, res, next) => {
  const authHeader = req.headers?.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Authorization header missing or invalid" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = {
      _id: decoded.id || decoded._id,
      role: decoded.role,
      email: decoded.email || null,
    };
    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
};

// Authorize middleware (check roles)
export const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: "User not authenticated" });
    }

    const userRole = mapAlias(req.user.role);
    const allowedRoles = roles.map(mapAlias);

    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({ error: "Forbidden: insufficient permissions" });
    }

    next();
  };
};
