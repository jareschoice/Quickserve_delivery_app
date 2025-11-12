// ===============================
// ðŸŒ QuickServe Event Configuration (Auto Synced)
// ===============================

// ðŸ§© Import auto-generated backend settings
// This file is created automatically by the backend on each startup
import { BACKEND_HTTP, API_BASE_URL, AUTH_API_URL, SOCKET_URL } from './env-config.js';
// Add missing file base URL
export const FILE_BASE_URL = `${BACKEND_HTTP}/uploads/`;

// ðŸš€ Unified Config Object
const CONFIG = {
  SERVER_IP: BACKEND_HTTP,  // same as backendâ€™s detected IP
  API_BASE_URL,
  AUTH_API_URL,
  SOCKET_URL,
  
  // ðŸ’³ Paystack Configuration
  PAYSTACK_PUBLIC_KEY: "pk_test_xxxxxxxxxxxxxxxxxx", // âœ… replace with real Paystack key

  // ðŸ”„ Auto-refresh intervals (milliseconds)
  REFRESH_INTERVALS: {
    ORDERS: 15000,
    TRACKING: 10000,
    ADMIN: 10000,
    DISPATCHER: 15000,
  },

  // âš™ Service Fee Configuration
  SERVICE_CHARGE: 100, // â‚¦100 per order flat

  // ðŸš€ Event Settings
  EVENT_DEMO_MODE: false,
  EVENT_GUEST_CHECKOUT: true,
  RIDER_SPEED_KMH: 20,

  // ðŸ“ Default Event Location
  VENUE_LAT: 6.465422,
  VENUE_LNG: 3.406448,

  // ðŸŒ Environment
  ENVIRONMENT: "development",
};

// ===============================
// âœ… Canonical Category + Section Data
// ===============================
export const CATEGORY_OPTIONS = [
  { key: "Restaurant", label: "Restaurant" },
  { key: "FastFood", label: "Fast Food" },
  { key: "Drinks", label: "Drinks" },
  { key: "Snacks", label: "Snacks" },
  { key: "Continental", label: "Continental" },
  { key: "Shop", label: "Shop" },
  { key: "Pharmacy", label: "Pharmacy" },
  { key: "Desserts", label: "Desserts" },
  { key: "Other", label: "Other" },
];

export const SUBCATEGORY_OPTIONS = {
  Drinks: [{ key: "BeveragesFood", label: "Beverages/Food" }],
};

export const SECTION_OPTIONS = [
  { key: "Explore", label: "Explore" },
  { key: "Featured", label: "Featured" },
  { key: "FoodCourt", label: "Food Court" },
];

// ===============================
// ðŸ§  Auto Alignment (Dev Convenience)
// ===============================
try {
  if (typeof window !== "undefined") {
    const port = window.location.port || "5555";
    const host = window.location.hostname || "127.0.0.1";
    const protocol = window.location.protocol || "http:";

    // Ensure local frontend always syncs with backend
    CONFIG.API_BASE_URL = `${protocol}//${host}:${port}/api`;
    CONFIG.AUTH_API_URL = `${protocol}//${host}:${port}/api/auth`;
    CONFIG.SOCKET_URL = `ws://${host}:${port}`;
    CONFIG.SERVER_IP = `${protocol}//${host}:${port}`;

    console.log("ðŸ”„ [QuickServe Config] Synced API endpoints with backend:", CONFIG.API_BASE_URL);
  }
} catch (err) {
  console.error("âš  Config auto-sync error:", err);
}

// ===============================
// âœ… Exports
// ===============================
export { API_BASE_URL, AUTH_API_URL, SOCKET_URL, CONFIG as default };
