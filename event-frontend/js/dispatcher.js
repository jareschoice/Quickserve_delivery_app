import { API_BASE_URL, FILE_BASE_URL, default as CONFIG } from './config.js';
import { playNotificationSound, ensureNotificationPermission } from './notify.js';
import socket from './socket.js';

const token = localStorage.getItem('token');

async function loadRiderEarnings() {
  try {
  // Endpoint is plural in API mount: /api/riders/earnings
  const res = await fetch(`${API_BASE_URL}/riders/earnings`, { headers: { 'Authorization': `Bearer ${token}` } });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to load earnings');
    document.getElementById('rider-earnings')?.replaceChildren(document.createTextNode(`â‚¦${Number(data.earnings||0).toLocaleString()}`));
    document.getElementById('rider-delivered')?.replaceChildren(document.createTextNode(String(data.deliveredCount||0)));
    document.getElementById('rider-active')?.replaceChildren(document.createTextNode(String(data.assignedCount||0)));
  } catch (e) {
    // silent
  }
}

async function loadReadyOrders() {
  try {
    const res = await fetch(`${API_BASE_URL}/orders/available/list`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to load orders');
    displayReadyOrders(data.items || []);
  } catch (err) {
    console.error('Error loading orders:', err);
    const el = document.getElementById('ready-orders');
    if (el) el.innerHTML = `<p class="text-danger">${err.message}</p>`;
  }
}

function displayReadyOrders(orders) {
  const orderList = document.getElementById('ready-orders');
  if (!orderList) return;
  if (!orders.length) {
    orderList.innerHTML = '<p class="text-muted">No orders ready for pickup</p>';
    return;
  }
  orderList.innerHTML = '';
  orders.forEach(order => {
    const seat = order.seatNumber || 'â€”';
    const itemsCount = order.items?.length ?? 0;
    const total = order.total || order.subtotal || 0;
    const html = `
      <div class="list-group-item">
        <div class="d-flex w-100 justify-content-between">
          <h5 class="mb-1">Order #${String(order._id).slice(-6)}</h5>
          <small>Seat: ${seat}</small>
        </div>
        <p class="mb-1"><strong>Items:</strong> ${itemsCount}</p>
        <p class="mb-1"><strong>Total:</strong> â‚¦${total}</p>
        <button class="btn btn-primary btn-sm mt-2" data-order-id="${order._id}">Claim Order</button>
      </div>`;
    orderList.insertAdjacentHTML('beforeend', html);
  });

  // Attach click listeners
  orderList.querySelectorAll('button[data-order-id]').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const id = e.currentTarget.getAttribute('data-order-id');
      await claimOrder(id, e.currentTarget);
    });
  });
}

async function claimOrder(orderId, buttonEl) {
  if (buttonEl) { buttonEl.disabled = true; buttonEl.textContent = 'Claiming...'; }
  try {
    const res = await fetch(`${API_BASE_URL}/orders/${orderId}/accept-dispatch`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    if (res.status === 409) {
      alert('Sorry, another dispatcher already accepted this order.');
      await loadReadyOrders();
      if (buttonEl) { buttonEl.disabled = false; buttonEl.textContent = 'Claim Order'; }
      return;
    }
    if (!res.ok) throw new Error(data.error || 'Failed to accept order');

    alert('Order accepted! Proceed to pickup.');
  try { playNotificationSound(); } catch {}
    await loadReadyOrders();
    // Start sharing live location for this order
    startLocationSharing(orderId);
    // Optionally, display QR for rider
    // const img = new Image(); img.src = data.riderQrBase64; document.body.appendChild(img);
  } catch (err) {
    console.error('Error claiming order:', err);
    alert(err.message);
    if (buttonEl) { buttonEl.disabled = false; buttonEl.textContent = 'Claim Order'; }
  }
}

function setupRealtimeUpdates() {
  if (typeof io === 'undefined') return;
  const socket = io(FILE_BASE_URL, { transports: ['websocket', 'polling'] });
  // Join dispatcher role room (server also emits to role:rider; we subscribe to both events below)
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  if (user?._id) socket.emit('identify', { userId: user._id, role: 'dispatcher' });
  else socket.emit('identify', { role: 'dispatcher' });

  const handleDispatchEvent = (payload) => {
    const groupId = payload?.orderGroupId;
    const id = payload?.id || payload?.orderId || payload?._id;
    if (!window.__shownDispatchRequests) window.__shownDispatchRequests = new Set();

    if (groupId) {
      const key = `g:${groupId}`;
      if (window.__shownDispatchRequests.has(key)) return;
      window.__shownDispatchRequests.add(key);
      loadReadyOrders();
      addEphemeralNotification({ title: 'Multiâ€‘vendor pickup', message: `Collect from ${payload?.pickupCount || 1} vendors. First to accept wins.` });
      try { showGroupAcceptPopup({
        groupId,
        pickupCount: payload?.pickupCount,
        pickupLocations: payload?.pickupLocations,
        totalAmount: payload?.totalAmount,
        message: payload?.message || 'Multiâ€‘vendor delivery request'
      }); } catch {}
      return;
    }

    if (!id) {
      loadReadyOrders();
      addEphemeralNotification({ title: 'New pickup request', message: 'Order ready for pickup.' });
      return;
    }

    const key = `o:${id}`;
    if (window.__shownDispatchRequests.has(key)) return;
    window.__shownDispatchRequests.add(key);
    loadReadyOrders();
    addEphemeralNotification({ title: 'New pickup request', message: 'A vendor marked an order ready. Tap to accept.' });
    try { showDispatchAcceptPopup({
      id,
      vendorName: payload?.vendor?.businessName,
      totalAmount: payload?.totalAmount || payload?.subtotal,
      pickupCount: payload?.pickupCount || 1,
      message: payload?.message || 'New delivery request'
    }); } catch {}
  };

  socket.on('dispatch:request', handleDispatchEvent);
  // Legacy/alternate event name also used by server
  socket.on('new_delivery_request', handleDispatchEvent);
  // Follow-up personal notifications (e.g., delivered)
  socket.on('notification:new', (n) => {
    if (!n) return;
    addEphemeralNotification({ title: n.title || 'Notification', message: n.message || '' });
  });
  // Someone else took it â†’ dismiss
  socket.on('delivery_taken', (payload = {}) => {
    const { orderId, orderGroupId } = payload;
    const key = orderGroupId ? `g:${orderGroupId}` : (orderId ? `o:${orderId}` : null);
    if (key && window.__shownDispatchRequests) window.__shownDispatchRequests.delete(key);
    try {
      const modalEl = document.getElementById('dispatcherRequestModal');
      if (modalEl) {
        const body = modalEl.querySelector('#dispatcherRequestBody');
        const txt = 'Another dispatcher already accepted this delivery.';
        if (body) body.insertAdjacentHTML('beforeend', `<div class="alert alert-warning mt-3">${txt}</div>`);
        const modal = bootstrap.Modal.getInstance(modalEl);
        if (modal) setTimeout(() => modal.hide(), 1000);
      }
    } catch {}
    addEphemeralNotification({ title: 'Taken by another', message: 'This delivery has been accepted by someone else.' });
    loadReadyOrders();
  });
  // Expose for location streaming
  window.__qs_socket = socket;
}

// Live location sharing
let watchId = null;
function startLocationSharing(orderId) {
  try {
    const socket = window.__qs_socket;
    if (!socket || !('geolocation' in navigator)) return;
    if (watchId) navigator.geolocation.clearWatch(watchId);
    // Mark in-transit (starts ETA on consumer side)
    fetch(`${API_BASE_URL}/orders/${orderId}/in-transit`, { method: 'POST', headers: { 'Authorization': `Bearer ${token}` } }).catch(()=>{});
    watchId = navigator.geolocation.watchPosition((pos) => {
      const { latitude: lat, longitude: lng } = pos.coords;
      socket.emit('rider:location', { orderId, lat, lng, speed: pos.coords.speed });
    }, (err) => {
      console.warn('Geolocation error:', err.message);
    }, { enableHighAccuracy: true, maximumAge: 5000, timeout: 15000 });
  } catch {}
}

// Auto-refresh using config
let intervalId;
document.addEventListener('DOMContentLoaded', () => {
  loadReadyOrders();
  loadRiderEarnings();
  setupRealtimeUpdates();
  const ms = (CONFIG?.REFRESH_INTERVALS?.DISPATCHER) || 15000;
  intervalId = setInterval(() => { loadReadyOrders(); loadRiderEarnings(); }, ms);
  setupNotificationsUI();
  
  // Request notification permission immediately
  try { 
    ensureNotificationPermission();
    console.log('ðŸ”” Notification permission requested');
  } catch (e) {
    console.warn('Failed to request notification permission:', e);
  }
  
  // Also enable audio on first user interaction to bypass autoplay restrictions
  const enableAudio = () => {
    try {
      const testAudio = new Audio();
      testAudio.play().then(() => testAudio.pause()).catch(() => {});
      console.log('ðŸ”Š Audio enabled');
    } catch {}
    document.removeEventListener('click', enableAudio);
    document.removeEventListener('touchstart', enableAudio);
  };
  document.addEventListener('click', enableAudio, { once: true });
  document.addEventListener('touchstart', enableAudio, { once: true });
});

// ===== Ephemeral notifications for dispatcher =====
const ephemNotifs = [];
function addEphemeralNotification(n) {
  ephemNotifs.unshift({ ...n, createdAt: new Date().toISOString() });
  if (ephemNotifs.length > 50) ephemNotifs.pop();
  const badge = document.getElementById('notifCount');
  if (badge) badge.textContent = String(Number(badge.textContent||'0') + 1);
  renderEphemeralNotifs();
  
  // Play sound notification
  try { 
    playNotificationSound();
    console.log('ðŸ”” Notification sound played');
  } catch (e) {
    console.warn('Failed to play notification sound:', e);
  }
  
  // Show browser notification
  try {
    if (Notification.permission === 'granted') {
      new Notification(n.title || 'QuickServe', {
        body: n.message || '',
        icon: '/favicon.ico',
        badge: '/favicon.ico'
      });
    }
  } catch (e) {
    console.warn('Failed to show browser notification:', e);
  }
}
function renderEphemeralNotifs() {
  const list = document.getElementById('notifList');
  if (!list) return;
  if (!ephemNotifs.length) {
    list.innerHTML = '<div class="p-3 text-muted">No notifications yet</div>';
    return;
  }
  list.innerHTML = ephemNotifs.map(n => `<div class="list-group-item small"><div class="fw-semibold">${n.title}</div><div>${n.message}</div><div class="text-muted">${new Date(n.createdAt).toLocaleString()}</div></div>`).join('');
}
function setupNotificationsUI() {
  const btn = document.getElementById('notifBtn');
  const dd = document.getElementById('notifDropdown');
  const badge = document.getElementById('notifCount');
  
  if (btn && dd) {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const isVisible = dd.style.display === 'block';
      dd.style.display = isVisible ? 'none' : 'block';
      
      if (dd.style.display === 'block') {
        renderEphemeralNotifs();
        // Reset badge when opening
        if (badge) badge.textContent = '0';
      }
    });
    
    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
      if (!dd.contains(e.target) && e.target !== btn && !btn.contains(e.target)) {
        dd.style.display = 'none';
      }
    });
  }
}

// ===== Popup to accept a dispatch (first-come-first-serve) =====
function ensureModalContainer() {
  let el = document.getElementById('dispatcherRequestModal');
  if (el) return el;
  el = document.createElement('div');
  el.id = 'dispatcherRequestModal';
  el.className = 'modal fade';
  el.innerHTML = `
    <div class="modal-dialog modal-dialog-centered">
      <div class="modal-content">
        <div class="modal-header bg-warning">
          <h5 class="modal-title">New Pickup Request</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div id="dispatcherRequestBody"></div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Dismiss</button>
          <button type="button" id="dispatcherAcceptBtn" class="btn btn-primary">Accept</button>
        </div>
      </div>
    </div>`;
  document.body.appendChild(el);
  return el;
}

function showDispatchAcceptPopup({ id, vendorName, totalAmount, pickupCount, message }) {
  const modalEl = ensureModalContainer();
  const body = modalEl.querySelector('#dispatcherRequestBody');
  const acceptBtn = modalEl.querySelector('#dispatcherAcceptBtn');
  body.innerHTML = `
    <div class="mb-2">${message || 'New delivery request'}</div>
    <ul class="list-unstyled small mb-0">
      <li><strong>Order:</strong> ${String(id).slice(-6)}</li>
      ${vendorName ? `<li><strong>Vendor:</strong> ${vendorName}</li>` : ''}
      ${typeof totalAmount !== 'undefined' ? `<li><strong>Amount:</strong> â‚¦${Number(totalAmount||0).toLocaleString()}</li>` : ''}
      ${pickupCount ? `<li><strong>Pickups:</strong> ${pickupCount}</li>` : ''}
    </ul>`;
  acceptBtn.disabled = false;
  acceptBtn.textContent = 'Accept';
  acceptBtn.onclick = async () => {
    acceptBtn.disabled = true; acceptBtn.textContent = 'Accepting...';
    try {
      await claimOrder(id);
      // Close modal on success
      const modal = bootstrap.Modal.getInstance(modalEl) || new bootstrap.Modal(modalEl);
      modal.hide();
    } catch (e) {
      // claimOrder already shows alert; re-enable to allow retry in case of other errors
      acceptBtn.disabled = false; acceptBtn.textContent = 'Accept';
    }
  };
  const modal = new bootstrap.Modal(modalEl);
  modal.show();
}

function showGroupAcceptPopup({ groupId, pickupCount, pickupLocations = [], totalAmount, message }) {
  const modalEl = ensureModalContainer();
  const body = modalEl.querySelector('#dispatcherRequestBody');
  const acceptBtn = modalEl.querySelector('#dispatcherAcceptBtn');
  const listHtml = (pickupLocations || []).map((p, idx) => `
    <li>${idx+1}. ${p?.vendor?.businessName || 'Vendor'} â€” â‚¦${Number(p?.subtotal||0).toLocaleString()}</li>`).join('');
  body.innerHTML = `
    <div class="mb-2">${message || 'Multiâ€‘vendor delivery request'}</div>
    <ul class="small mb-2">${listHtml}</ul>
    <ul class="list-unstyled small mb-0">
      <li><strong>Group:</strong> ${groupId}</li>
      ${pickupCount ? `<li><strong>Pickups:</strong> ${pickupCount}</li>` : ''}
      ${typeof totalAmount !== 'undefined' ? `<li><strong>Total:</strong> â‚¦${Number(totalAmount||0).toLocaleString()}</li>` : ''}
    </ul>`;
  acceptBtn.disabled = false;
  acceptBtn.textContent = 'Accept';
  acceptBtn.onclick = async () => {
    acceptBtn.disabled = true; acceptBtn.textContent = 'Accepting...';
    try {
      await acceptGroupDelivery(groupId);
      const modal = bootstrap.Modal.getInstance(modalEl) || new bootstrap.Modal(modalEl);
      modal.hide();
    } catch (e) {
      acceptBtn.disabled = false; acceptBtn.textContent = 'Accept';
    }
  };
  const modal = new bootstrap.Modal(modalEl);
  modal.show();
}

async function acceptGroupDelivery(groupId) {
  const res = await fetch(`/api/dispatchers/accept/${groupId}`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    alert(data?.error || 'Failed to accept group delivery');
    throw new Error(data?.error || 'accept-failed');
  }
  alert(data?.message || 'Multiâ€‘vendor delivery accepted!');
  await loadReadyOrders();
}
 
