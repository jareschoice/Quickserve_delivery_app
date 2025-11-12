// ========================================
// admin-socket-init.js
// Handles realtime admin notifications (QuickServe Event Edition)
// ========================================

// âœ… 1. Server IP / socket origin
const SOCKET_ORIGIN = "http://192.168.192.104:5555"; // <-- Change if IP changes

// âœ… 2. Ensure socket.io client is loaded before using it
function ensureSocketClientLoaded(cb) {
  if (typeof io !== "undefined") return cb();
  const script = document.createElement("script");
  script.src = "/socket.io/socket.io.js";
  script.onload = cb;
  script.onerror = () => {
    console.error(
      "âŒ Failed to load /socket.io/socket.io.js. Check server or CSP settings."
    );
  };
  document.head.appendChild(script);
}

// âœ… 3. Main logic once socket client ready
ensureSocketClientLoaded(() => {
  try {
    if (!window.__qs_socket) {
      window.__qs_socket = io(SOCKET_ORIGIN, {
        transports: ["websocket", "polling"],
      });
      console.log("âœ… QuickServe socket initialized:", SOCKET_ORIGIN);
    }
  } catch (err) {
    console.error("Socket initialization failed:", err);
  }

  const socket = window.__qs_socket;

  // Identify user (admin)
  try {
    const user = JSON.parse(localStorage.getItem("user") || "{}");
    if (user && user._id) {
      socket.emit("identify", { userId: user._id, role: user.role || "admin" });
    } else {
      socket.emit("identify", { role: "admin" });
    }
  } catch {
    socket.emit("identify", { role: "admin" });
  }

  // =====================================================
  // ðŸ”” 4. Toast Notification Helper
  // =====================================================
  function showToast(title, message, tone = "/audio/notification.mp3") {
    const toast = document.createElement("div");
    toast.className = "toast show mb-2 shadow-lg position-fixed top-0 end-0 m-3";
    toast.style.zIndex = 1055;
    toast.innerHTML = `
      <div class="toast-header bg-success text-white">
        <strong class="me-auto">${title}</strong>
        <small>Just now</small>
        <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
      </div>
      <div class="toast-body">${message}</div>
    `;
    document.body.appendChild(toast);
    try {
      new Audio(tone).play().catch(() => {});
    } catch {}
    setTimeout(() => toast.remove(), 6000);
  }

  // =====================================================
  // âš¡ 5. Socket Event Listeners
  // =====================================================

  // New order placed (notify admin)
  socket.on("order:placed", (payload) => {
    try {
      const order = payload.order || payload;
      const id = String(order._id || order.id || "").slice(-6);
      const amount = Number(order.total || order.amount || order.subtotal || 0);
      showToast("ðŸ› New Order", Order #${id} â€” â‚¦${amount.toLocaleString()});
      const container = document.getElementById("orderNotifications");
      if (container) {
        const toast = document.createElement("div");
        toast.className = "toast show mb-2";
        toast.innerHTML = `
          <div class="toast-header">
            <strong class="me-auto">New Order</strong>
            <small>Just now</small>
            <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
          </div>
          <div class="toast-body">
            Order #${id} â€” â‚¦${amount.toLocaleString()}
          </div>
        `;
        container.prepend(toast);
      }
    } catch (e) {
      console.warn("order:placed handler failed", e);
    }
  });

  // Wallet updates
  socket.on("wallet:update", (wallet) => {
    try {
      const el = document.getElementById("walletBalance");
      if (el && wallet && typeof wallet.balance !== "undefined") {
        el.textContent = Number(wallet.balance).toLocaleString();
      }
    } catch {}
  });

  // Order status updates
  socket.on("order:update", (data) => {
    console.log("order:update", data);
    if (
      window.refreshAdminOrdersList &&
      typeof window.refreshAdminOrdersList === "function"
    ) {
      window.refreshAdminOrdersList();
    }
  });

  // Dispatcher assigned
  socket.on("dispatch:assigned", (d) => {
    showToast("ðŸ›µ Dispatcher Assigned", Order #${d.orderId || ""} now in transit);
  });

  // Connection status logs
  socket.on("connect", () => console.log("ðŸ”Œ Socket connected:", socket.id));
  socket.on("disconnect", () => console.log("ðŸš« Socket disconnected"));
});
