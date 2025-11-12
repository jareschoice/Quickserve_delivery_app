import socketClient from './socket.js';

// Use the shared socket client from js/socket.js. That module will
// initialize a connection using the configured SOCKET_URL.
const socket = socketClient;

function showToast(title, message, tone = '/event-frontend/audio/notification.mp3') {
  const toast = document.createElement('div');
  toast.className = 'toast show mb-2 shadow-lg position-fixed top-0 end-0 m-3';
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
  try { new Audio(tone).play().catch(()=>{}); } catch {}
  setTimeout(() => toast.remove(), 6000);
}

if (socket) {
  try {
    // Identify admin user if available
    const userRaw = localStorage.getItem('eventUser') || localStorage.getItem('user') || '{}';
    let user = {};
    try { user = JSON.parse(userRaw); } catch {}
    if (user && user._id) socket.emit('identify', { userId: user._id, role: user.role || 'admin' });
    else socket.emit('identify', { role: 'admin' });
  } catch (err) {
    console.warn('admin-socket-init identify failed', err);
  }

  socket.on('order:placed', (payload) => {
    try {
      const order = payload.order || payload || {};
      const id = String(order._id || order.id || '').slice(-6);
      const amount = Number(order.total || order.amount || order.subtotal || 0);
      showToast('New Order', `Order #${id} — ₦${amount.toLocaleString()}`);
      const container = document.getElementById('orderNotifications');
      if (container) {
        const t = document.createElement('div');
        t.className = 'toast show mb-2';
        t.innerHTML = `
          <div class="toast-header">
            <strong class="me-auto">New Order</strong>
            <small>Just now</small>
            <button type="button" class="btn-close" data-bs-dismiss="toast"></button>
          </div>
          <div class="toast-body">
            Order #${id} — ₦${amount.toLocaleString()}
          </div>
        `;
        container.prepend(t);
      }
    } catch (e) { console.warn('order:placed handler failed', e); }
  });

  socket.on('wallet:update', (wallet) => {
    try {
      const el = document.getElementById('walletBalance');
      if (el && wallet && typeof wallet.balance !== 'undefined') {
        el.textContent = Number(wallet.balance).toLocaleString();
      }
    } catch (e) { console.warn(e); }
  });

  socket.on('order:update', (data) => {
    console.log('order:update', data);
    if (window.refreshAdminOrdersList && typeof window.refreshAdminOrdersList === 'function') {
      window.refreshAdminOrdersList();
    }
  });

  socket.on('dispatch:assigned', (d) => {
    showToast('Dispatcher Assigned', `Order #${d.orderId || ''} now in transit`);
  });

  socket.on('connect', () => console.log('Socket connected (admin)', socket.id));
  socket.on('disconnect', () => console.log('Socket disconnected (admin)'));
}
