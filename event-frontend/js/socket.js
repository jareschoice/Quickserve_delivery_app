// QuickServe Socket helper (simplified and robust)
import { SOCKET_URL, API_BASE_URL } from './config.js';

// Provide a safe socket object. The client pages include /socket.io/socket.io.js
// so `io` will be available on window when socket.io client script is loaded.
let socketClient = null;
try {
  if (typeof io !== 'undefined') {
    socketClient = io(SOCKET_URL, { transports: ['websocket', 'polling'], reconnection: true, reconnectionAttempts: 5 });
    console.log('[Socket] connected to', SOCKET_URL);
  } else {
    console.warn('[Socket] io is not defined; socket features will be disabled.');
  }
} catch (err) {
  console.error('[Socket] init error:', err);
  socketClient = null;
}

export function showToast(title, message) {
  const containerId = 'toastContainer';
  let container = document.getElementById(containerId);
  if (!container) {
    container = document.createElement('div');
    container.id = containerId;
    container.className = 'toast-container position-fixed top-0 end-0 p-3';
    document.body.appendChild(container);
  }

  const toast = document.createElement('div');
  toast.className = 'toast align-items-center text-bg-light border-0 show mb-2 shadow-sm';
  toast.innerHTML = `<div class="d-flex"><div class="toast-body"><strong>${title}</strong><br>${message}</div><button type="button" class="btn-close me-2 m-auto" data-bs-dismiss="toast"></button></div>`;
  container.appendChild(toast);
  try { new Audio('/audio/notification.mp3').play().catch(()=>{}); } catch {}
}

// Register a few safe listeners if socketClient available
// Register a few safe listeners if socketClient available
if (socketClient) {
  socketClient.on('order:placed', data => { console.log('[Socket] order:placed', data); showToast('New Order', `Order #${data?.id || 'N/A'} - ₦${data?.amount || ''}`); });
  socketClient.on('order:accepted', data => { console.log('[Socket] order:accepted', data); showToast('Order Accepted', `Vendor ${data?.vendorName || ''} accepted the order.`); });
  socketClient.on('order:ready', data => { console.log('[Socket] order:ready', data); showToast('Order Ready', `Order #${data?.id || ''} is ready for pickup.`); });
  socketClient.on('order:in_transit', data => { console.log('[Socket] order:in_transit', data); showToast('Order In Transit', `Dispatcher picked up order #${data?.id || ''}.`); });
  socketClient.on('order:delivered', data => { console.log('[Socket] order:delivered', data); showToast('Order Delivered', `Order #${data?.id || ''} has been delivered.`); try { new Audio('/audio/success.mp3').play().catch(()=>{}); } catch {} });
  socketClient.on('wallet:update', data => { console.log('[Socket] wallet:update', data); showToast('Wallet Update', `New balance: ₦${data?.balance?.toFixed(2) || 0}`); const walletElement = document.getElementById('walletBalance'); if (walletElement && data?.balance !== undefined) walletElement.textContent = data.balance.toFixed(2); });
  socketClient.on('system:online_users', list => { console.log('[Socket] online users', list); });
}

// Provide a safe proxy so pages can always import a socket object without null-checks
const safeSocket = socketClient ? socketClient : {
  id: null,
  on: () => {},
  once: () => {},
  off: () => {},
  emit: () => {},
  disconnect: () => {},
  connected: false
};

// Expose a global reference that legacy inline scripts can also check
if (typeof window !== 'undefined') {
  window.__qs_socket = safeSocket;
  // Don't overwrite an existing window.socket if present
  if (!window.socket) window.socket = safeSocket;
}

export default safeSocket;
