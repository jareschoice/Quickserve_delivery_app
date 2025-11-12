import { API_BASE_URL, FILE_BASE_URL, default as CONFIG } from './config.js';
import { playNotificationSound, ensureNotificationPermission, showBrowserNotification } from './notify.js';
import socket from './socket.js';

// Get order ID from URL
const urlParams = new URLSearchParams(window.location.search);
const orderId = urlParams.get('orderId');
// If a token is provided via redirect, store it for API calls
const tokenFromUrl = urlParams.get('token');
if (tokenFromUrl) {
  try { localStorage.setItem('eventToken', tokenFromUrl); } catch {}
}

// Load order details
async function loadOrderDetails() {
  try {
    const token = localStorage.getItem('eventToken');
    // Use public tracking endpoint if no token (guest checkout)
    const endpoint = token ? `${API_BASE_URL}/orders/${orderId}` : `${API_BASE_URL}/orders/track/${orderId}`;
    const res = await fetch(endpoint, {
      headers: token ? { 'Authorization': `Bearer ${token}` } : {}
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Order not found');
    await displayOrder(data.order);
  } catch (error) {
    console.error('Error loading order:', error);
    const el = document.getElementById('order-status');
    if (el) el.textContent = 'Error loading order';
  }
}

// Display order details
async function displayOrder(order) {
  document.getElementById('order-id').textContent = order._id;
  document.getElementById('order-status').textContent = formatStatus(order.status);
  document.getElementById('seat-id').textContent = order.seatNumber || order.deliveryAddress || 'â€”';
  // Show phone if available (guestPhone, phone, or customerPhone)
  const phoneEl = document.getElementById('order-phone');
  if (phoneEl) phoneEl.textContent = order.guestPhone || order.phone || order.customerPhone || '—';

  // Display order items (support multiple possible field names returned by API)
  const itemsList = document.getElementById('order-items-list');
  if (itemsList) {
    let items = [];
    if (Array.isArray(order.items) && order.items.length) items = order.items;
    else if (Array.isArray(order.cart) && order.cart.length) items = order.cart;
    else if (Array.isArray(order.orderItems) && order.orderItems.length) items = order.orderItems;

    if (items.length) {
      itemsList.innerHTML = items
        .map(it => {
          const qty = it.qty || it.quantity || it.count || 1;
          const price = Number(it.price || it.unitPrice || it.amount || 0);
          const name = it.name || it.productName || it.title || 'Item';
          return `<div class="order-item"><div class="fw-semibold">${name}</div><div class="text-muted small">x${qty} — ₦${price.toLocaleString()}</div></div>`;
        })
        .join('');
    } else {
      itemsList.innerHTML = '<p class="text-muted">No items listed</p>';
    }
  }

  updateEta(order);

  // Display QR code for customer when rider assigned or in transit
  const qrCodeDiv = document.getElementById('qr-code');
  if (qrCodeDiv && ['assigned', 'in_transit', 'waiting_pickup'].includes(order.status)) {
    try {
      const token = localStorage.getItem('eventToken');
      const res = await fetch(`${API_BASE_URL}/orders/${order._id}/qr?type=customer`, {
        headers: token ? { 'Authorization': `Bearer ${token}` } : {}
      });
      const data = await res.json();
      if (res.ok && data.qrBase64) {
        qrCodeDiv.innerHTML = `
          <h5 class="mt-4">Delivery Verification QR Code</h5>
          <img src="${data.qrBase64}" alt="QR Code" class="img-fluid" style="max-width: 300px;">
          <p class="text-muted">Show this QR to the dispatcher to confirm delivery</p>
        `;
      } else {
        qrCodeDiv.innerHTML = '';
      }
    } catch {
      qrCodeDiv.innerHTML = '';
    }
  } else if (qrCodeDiv) {
    qrCodeDiv.innerHTML = '';
  }
}

// ETA handling
let etaTimer;
function updateEta(order) {
  const etaEl = document.getElementById('order-eta');
  if (!etaEl) return;
  clearInterval(etaTimer);
  if (order.status !== 'in_transit') {
    etaEl.textContent = 'â€”';
    return;
  }
  const speedKmh = (CONFIG?.RIDER_SPEED_KMH) || 20;
  const inTransitAtMs = order.inTransitAt ? new Date(order.inTransitAt).getTime() : Date.now();
  const distanceKm = Number(order.distanceKm || 3);
  function render() {
    const elapsedSec = Math.max(0, Math.floor((Date.now() - inTransitAtMs) / 1000));
    const totalSec = Math.max(60, Math.round((distanceKm / speedKmh) * 3600));
    const remaining = Math.max(0, totalSec - elapsedSec);
    const min = Math.floor(remaining / 60);
    const sec = remaining % 60;
    etaEl.textContent = remaining > 0 ? `${min}m ${sec}s` : 'Arriving now';
  }
  render();
  etaTimer = setInterval(render, 30000);
}

// Format status for display
function formatStatus(status) {
  const statusMap = {
    'pending': 'Pending',
    'accepted': 'Accepted by Vendor',
    'preparing': 'Being Prepared',
    'waiting_pickup': 'Ready for Pickup',
    'assigned': 'Rider Assigned',
    'in_transit': 'Out for Delivery',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled'
  };
  return statusMap[status] || status;
}

// Auto-refresh order status every 10 seconds
setInterval(loadOrderDetails, (CONFIG?.REFRESH_INTERVALS?.TRACKING) || 10000);

// Load order when page loads
document.addEventListener('DOMContentLoaded', () => {
  // Ask for permission on first click rather than immediately
  document.addEventListener('click', function onePerm() {
    try { ensureNotificationPermission(); } catch {}
    document.removeEventListener('click', onePerm);
  }, { once: true });
  loadOrderDetails();
});

// Optional realtime updates via socket.io — use imported `socket` which safely handles missing io
if (socket) {
  try {
    const user = JSON.parse(localStorage.getItem('user') || '{}');
    if (user?._id) socket.emit('identify', { userId: user._id, role: user.role || 'customer' });
    else socket.emit('identify', { role: 'customer' });
    if (orderId) socket.emit('join:order', orderId);
    socket.on('order:update', (payload) => {
      if (payload?.id && payload.id === orderId) {
        loadOrderDetails();
        playNotificationSound();
        showBrowserNotification('Order Update', 'Your order status was updated.');
      }
    });
    // Backwards-compatible: respond to new namespaced lifecycle events too
    socket.on('order:placed', (payload) => {
      try {
        if (payload?.orderId === orderId || payload?.id === orderId) {
          loadOrderDetails();
          playNotificationSound();
          showBrowserNotification('Order Placed', 'Your order was placed successfully.');
        }
      } catch (e) { console.error(e); }
    });
    socket.on('order:assigned', (payload) => {
      try {
        if (payload?.orderId === orderId || payload?.id === orderId) {
          loadOrderDetails();
          playNotificationSound();
          showToast('Rider assigned to your order');
          showBrowserNotification('Dispatcher Assigned', 'A dispatcher has been assigned to your order.');
        }
      } catch (e) { console.error(e); }
    });
    // Specific lifecycle events with friendly messages
    socket.on('order:accepted', (payload) => { try { if (payload?.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showToast('Vendor has accepted your order.'); showBrowserNotification('Order Accepted', 'Vendor has accepted your order.'); } } catch (e) {} });
    socket.on('order:preparing', (payload) => { try { if (payload?.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showToast('Your order is being prepared.'); showBrowserNotification('Order Preparing', 'Your order is being prepared.'); } } catch (e) {} });
    socket.on('order:dispatch_requested', (payload) => { try { if (payload?.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showToast('Dispatcher requested for pickup.'); showBrowserNotification('Dispatcher Requested', 'Dispatcher assigned, preparing for delivery.'); } } catch (e) {} });
    socket.on('order:in_transit', (payload) => { try { if (payload?.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showToast('Dispatcher is on the way.'); showBrowserNotification('Out for Delivery', 'Dispatcher is on the way.'); } } catch (e) {} });
    socket.on('order:arrived_customer', (payload) => { try { if (payload?.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showToast('Dispatcher has arrived. Please confirm delivery.'); showBrowserNotification('Arrived', 'Dispatcher has arrived. Please confirm delivery.'); } } catch (e) {} });
    socket.on('order:delivered', (payload) => { try { if (payload?.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showToast('Order delivered successfully. Thank you!', 'success'); showBrowserNotification('Delivered', 'Order delivered successfully. Thank you!'); showReviewModal(); } } catch (e) {} });
    socket.on('order:notification', (payload) => { try { if (payload?.orderId && payload.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showBrowserNotification('Order Notification', payload.message || 'Order update'); } } catch (e) { console.error(e); } });
    socket.on('order:ready', (payload) => { try { if (!orderId && payload?.orderId) { if (payload.orderId === orderId) { loadOrderDetails(); playNotificationSound(); showBrowserNotification('Order Ready', payload.message || 'Your order is ready for pickup'); } } } catch (e) { console.error(e); } });
    // Live rider location updates (Leaflet)
    let map, riderMarker, venueMarker;
    function ensureMap() {
      const mapDiv = document.getElementById('map');
      if (!mapDiv) return;
      if (!map && typeof L !== 'undefined') {
        map = L.map('map').setView([CONFIG.VENUE_LAT, CONFIG.VENUE_LNG], 14);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          maxZoom: 19,
          attribution: 'Â© OpenStreetMap'
        }).addTo(map);
        venueMarker = L.circleMarker([CONFIG.VENUE_LAT, CONFIG.VENUE_LNG], { radius: 6, color: '#FF6B00' }).addTo(map).bindTooltip('Event Venue');
      }
    }
    function haversineKm(lat1, lon1, lat2, lon2) {
      const toRad = (v) => v * Math.PI / 180;
      const R = 6371; // km
      const dLat = toRad(lat2 - lat1);
      const dLon = toRad(lon2 - lon1);
      const a = Math.sin(dLat/2)**2 + Math.cos(toRad(lat1))*Math.cos(toRad(lat2))*Math.sin(dLon/2)**2;
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      return R * c;
    }
    function updateEtaFromCoords(lat, lng) {
      const etaEl = document.getElementById('order-eta');
      if (!etaEl) return;
      const distKm = haversineKm(lat, lng, CONFIG.VENUE_LAT, CONFIG.VENUE_LNG);
      const speed = Number(CONFIG.RIDER_SPEED_KMH || 20);
      const totalSec = Math.max(60, Math.round((distKm / speed) * 3600));
      const min = Math.floor(totalSec / 60);
      const sec = totalSec % 60;
      etaEl.textContent = `${min}m ${sec}s`;
    }
    socket.on('order:loc', ({ orderId: oid, lat, lng }) => {
      if (oid !== orderId || typeof lat !== 'number' || typeof lng !== 'number') return;
      ensureMap();
      if (map) {
        if (!riderMarker) riderMarker = L.marker([lat, lng]).addTo(map).bindTooltip('Rider');
        else riderMarker.setLatLng([lat, lng]);
        if (riderMarker && venueMarker) {
          const bounds = L.latLngBounds([riderMarker.getLatLng(), venueMarker.getLatLng()]);
          map.fitBounds(bounds, { padding: [30, 30], maxZoom: 16 });
        }
      }
      updateEtaFromCoords(lat, lng);
    });
    socket.on('notification:new', (n) => {
      const b = document.getElementById('notifCount');
      if (b) b.textContent = String(Number(b.textContent||'0') + 1);
      // Append to list
      const list = document.getElementById('notifList');
      if (list) list.insertAdjacentHTML('afterbegin', `<div class="list-group-item small"><div class="fw-semibold">${n.title||'Notification'}</div><div>${n.message||''}</div><div class="text-muted">${new Date().toLocaleString()}</div></div>`);
      playNotificationSound();
      showBrowserNotification(n.title || 'Notification', n.message || 'New notification');
    });
  } catch {}
}

// Notifications dropdown toggle for consumer
const btn = document.getElementById('notifBtn');
const dd = document.getElementById('notifDropdown');
if (btn && dd) {
  btn.addEventListener('click', () => {
    dd.style.display = dd.style.display === 'block' ? 'none' : 'block';
  });
  document.addEventListener('click', (e) => {
    if (!dd.contains(e.target) && e.target !== btn) dd.style.display = 'none';
  });
}

// Lightweight toast utility for the track page (uses Bootstrap Toast)
function showToast(message, type = 'info') {
  const toastContainer = document.getElementById('toastContainer') || createToastContainer();
  const toast = document.createElement('div');
  toast.className = `toast align-items-center text-white bg-${type} border-0`;
  toast.setAttribute('role', 'alert');
  toast.innerHTML = `
    <div class="d-flex">
      <div class="toast-body">${message}</div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
    </div>
  `;
  toastContainer.appendChild(toast);
  const bsToast = new bootstrap.Toast(toast);
  bsToast.show();
  setTimeout(() => toast.remove(), 5000);
}

function createToastContainer() {
  const container = document.createElement('div');
  container.id = 'toastContainer';
  container.className = 'toast-container position-fixed top-0 end-0 p-3';
  container.style.zIndex = '9999';
  document.body.appendChild(container);
  return container;
}

// Simple review modal (asked when order delivered)
function showReviewModal() {
  try {
    const id = 'reviewModal';
    if (document.getElementById(id)) return;
    const html = `
      <div class="modal fade" id="${id}" tabindex="-1">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">Rate your delivery</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <p>Thank you! Would you like to leave a quick rating for this delivery?</p>
              <div class="mb-3">
                <select id="reviewRating" class="form-select">
                  <option value="5">5 - Excellent</option>
                  <option value="4">4 - Good</option>
                  <option value="3">3 - Okay</option>
                  <option value="2">2 - Poor</option>
                  <option value="1">1 - Terrible</option>
                </select>
              </div>
              <div class="mb-3"><textarea id="reviewComment" class="form-control" placeholder="Optional comment"></textarea></div>
            </div>
            <div class="modal-footer">
              <button class="btn btn-secondary" data-bs-dismiss="modal">Skip</button>
              <button id="submitReview" class="btn btn-primary">Submit</button>
            </div>
          </div>
        </div>
      </div>`;
    document.body.insertAdjacentHTML('beforeend', html);
    const modalEl = document.getElementById(id);
    const modal = new bootstrap.Modal(modalEl);
    modal.show();
    document.getElementById('submitReview').addEventListener('click', async () => {
      const rating = document.getElementById('reviewRating').value;
      const comment = document.getElementById('reviewComment').value;
      try {
        await fetch(`${API_BASE_URL}/orders/${orderId}/review`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('eventToken') || ''}` },
          body: JSON.stringify({ rating: Number(rating), comment })
        });
      } catch {}
      modal.hide();
      setTimeout(() => modalEl.remove(), 500);
    });
  } catch (e) {}
}
