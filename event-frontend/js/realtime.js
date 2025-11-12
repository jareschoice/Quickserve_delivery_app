// ==========================
// ðŸ”Œ Real-Time Socket Logic
// ==========================
import { io } from "/socket.io/socket.io.esm.min.js"; // optional if you want ESM

const socket = io("http://192.168.232.104:5555");
console.log("ðŸŸ¢ Socket initialized:", socket);

const consumerId = localStorage.getItem("consumerId") || sessionStorage.getItem("consumerId");

const playNotificationSound = (file = "/event-frontend/audio/notification.mp3") => {
  try {
    const audio = new Audio(file);
    audio.play().catch((err) => console.warn("Audio blocked:", err));
  } catch (e) {
    console.error("Audio error:", e);
  }
};

function showToast(title, message, tone = "/event-frontend/audio/notification.mp3") {
  const toast = document.createElement("div");
  toast.className = "toast show shadow-lg position-fixed top-0 end-0 m-3";
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
  playNotificationSound(tone);
  setTimeout(() => toast.remove(), 6000);
}

// Vendor Status Updates
socket.on("vendor:status", (data) => {
  const el = document.querySelector(`[data-vendor-id="${data.vendorId}"] .vendor-status`);
  if (el) {
    el.textContent = data.isActive ? "ðŸŸ¢ Online" : "ðŸ”´ Offline";
    el.style.color = data.isActive ? "green" : "red";
  }
});

// Consumer Order Notifications
const statusEl = document.getElementById("orderStatus");
const updateStatus = (text) => statusEl && (statusEl.textContent = text);

socket.on("order:placed", (data) => {
  if (data.consumerId === consumerId) {
    showToast("âœ… Order Placed", "Your order was successfully placed!", "/event-frontend/audio/order_placed.mp3");
    updateStatus("Preparing...");
  }
});

// Backwards-compatible aliases and additional namespaced events
socket.on('order:accepted', (data) => {
  if (data.consumerId === consumerId || data?.order?.consumerId === consumerId) {
    showToast('Order Accepted', 'Vendor accepted your order', '/event-frontend/audio/preparing.mp3');
    updateStatus('Preparing your meal...');
  }
});
socket.on('order:in_transit', (data) => {
  if (data.consumerId === consumerId || data?.order?.consumerId === consumerId) {
    showToast('Out for Delivery', 'Dispatcher is on the way!', '/event-frontend/audio/dispatch.mp3');
    updateStatus('Out for delivery');
  }
});
socket.on('order:arrived_customer', (data) => {
  if (data.consumerId === consumerId || data?.order?.consumerId === consumerId) {
    showToast('Arrived', 'Dispatcher has arrived.', '/event-frontend/audio/arrived.mp3');
    updateStatus('Arrived — Confirm delivery');
  }
});

socket.on("order:accepted", (data) => {
  if (data.consumerId === consumerId) {
    showToast("ðŸ‘¨ðŸ½â€ðŸ³ Vendor Accepted", "Vendor started preparing your order.", "/event-frontend/audio/preparing.mp3");
    updateStatus("Preparing your meal...");
  }
});

socket.on("order:ready", (data) => {
  if (data.consumerId === consumerId) {
    showToast("ðŸ± Ready for Pickup", "Your order is ready!", "/event-frontend/audio/ready.mp3");
    updateStatus("Ready for pickup");
  }
});

socket.on("order:dispatched", (data) => {
  if (data.consumerId === consumerId) {
    showToast("ðŸ›µ Out for Delivery", "Dispatcher is on the way!", "/event-frontend/audio/dispatch.mp3");
    updateStatus("Out for delivery");
  }
});

socket.on("order:arrived", (data) => {
  if (data.consumerId === consumerId) {
    showToast("ðŸ“ Arrived", "Dispatcher has arrived.", "/event-frontend/audio/arrived.mp3");
    updateStatus("Arrived â€” Confirm delivery");
  }
});

socket.on("order:delivered", (data) => {
  if (data.consumerId === consumerId) {
    showToast("ðŸŽ‰ Delivered", "Your order was delivered successfully.", "/event-frontend/audio/delivered.mp3");
    updateStatus("Delivered âœ…");
    const reviewModal = document.getElementById("reviewPopup");
    if (reviewModal) reviewModal.style.display = "block";
  }
});
