// Vendor dashboard (ES module)
import { API_BASE_URL, FILE_BASE_URL } from './config.js';
import socket from './socket.js';

// Get token from localStorage
const token = localStorage.getItem('eventToken');

// Notification Sound System
const notificationSound = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBDGJ0fPTgjMGHm7A7+OZUQ0PVKzo7adXEwlEmuTxwmwhBDGH0PPTgjQGHm6/7+OZTQ0PVK3o7KdXEwlFmeXwwmwhBDKI0PPTgjQGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OYTw0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm6/7+OZTQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7A==');

// Play notification sound
function playNotificationSound() {
  try {
    notificationSound.play().catch(err => {
      console.log('Sound play failed (user interaction required):', err);
    });
  } catch (error) {
    console.log('Sound not supported:', error);
  }
}

// Show browser notification (if permitted)
async function showBrowserNotification(title, body, icon) {
  if ('Notification' in window && Notification.permission === 'granted') {
    try {
      new Notification(title, {
        body: body,
        icon: icon || '/favicon.ico',
        badge: '/favicon.ico',
        vibrate: [200, 100, 200],
        requireInteraction: true
      });
    } catch (error) {
      console.log('Browser notification failed:', error);
    }
  }
}

// Request notification permission on first user interaction (required by some browsers)
document.addEventListener('click', function oneTimePermissionAsk() {
  try {
    if ('Notification' in window && Notification.permission === 'default') {
      Notification.requestPermission().catch(() => {});
    }
  } catch {}
  document.removeEventListener('click', oneTimePermissionAsk);
}, { once: true });

// Load vendor orders
async function loadVendorOrders() {
  try {
    // Use the vendor-specific endpoint on the backend
    const response = await fetch(`${API_BASE_URL}/vendor/orders`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    const data = await safeParseJson(response);
    if (response.ok && data && (data.items || data.orders)) {
      const items = data.items || data.orders || [];
      displayOrders(items);
      updateExpectingCount(items || []);
    } else {
      document.getElementById('vendor-orders').innerHTML = '<p class="text-muted">No orders yet</p>';
    }
  } catch (error) {
    console.error('Error loading orders:', error);
    document.getElementById('vendor-orders').innerHTML = '<p class="text-danger">Error loading orders</p>';
  }
}

// Display orders
function displayOrders(orders) {
  const orderList = document.getElementById('vendor-orders');
  
  if (orders.length === 0) {
    orderList.innerHTML = '<p class="text-muted">No orders yet</p>';
    return;
  }

  let html = '';
  
  orders.forEach(order => {
    html += `
      <div class="card mb-3">
        <div class="card-header">
          <div class="d-flex justify-content-between align-items-center">
            <span><strong>Order #${order._id.slice(-6)}</strong></span>
            <div>
              ${order.isMultiVendor ? '<span class="badge bg-info me-2" title="Multi-vendor order">ðŸ›’ Multi-Vendor</span>' : ''}
              <span class="status-badge status-${order.status}">${formatStatus(order.status)}</span>
            </div>
          </div>
        </div>
        <div class="card-body">
          ${order.isMultiVendor && order.orderGroupId ? `
            <div class="alert alert-info py-2 mb-3">
              <small><strong>ðŸ”— Group Order:</strong> ${order.orderGroupId}</small><br>
              <small id="groupStatus-${order._id}">Checking other vendors...</small>
            </div>
          ` : ''}
          ${order.deliveryAddress ? `<p><strong>Delivery:</strong> ${order.deliveryAddress}</p>` : ''}
          <p><strong>Items:</strong></p>
          <ul>
            ${(order.items || []).map(item => `<li>${item.name} x${item.qty} - â‚¦${(item.price * item.qty).toLocaleString()}</li>`).join('')}
          </ul>
          <p><strong>Subtotal:</strong> â‚¦${Number(order.subtotal || 0).toLocaleString()}</p>
          <p><strong>Payment Status:</strong> ${order?.payment?.paid ? 'âœ… Paid' : 'âŒ Unpaid'}</p>
          
          <div class="btn-group" role="group">
            ${order.status === 'placed' ? `<button class="btn btn-success" onclick="updateStatus('${order._id}', 'accepted')">Accept</button>` : ''}
            ${order.status === 'accepted' ? `<button class="btn btn-warning" onclick="updateStatus('${order._id}', 'preparing')">Start Preparing</button>` : ''}
            ${order.status === 'preparing' ? `<button class="btn btn-primary" onclick="updateStatus('${order._id}', 'ready')">Mark Ready</button>` : ''}
            ${order.status === 'placed' || order.status === 'accepted' ? `<button class="btn btn-danger" onclick="updateStatus('${order._id}', 'cancelled')">Cancel</button>` : ''}
          </div>
        </div>
      </div>
    `;
    
    // ðŸ†• Fetch group status if multi-vendor
    if (order.isMultiVendor && order.orderGroupId) {
      fetchGroupStatus(order.orderGroupId, order._id);
    }
  });
  
  orderList.innerHTML = html;
}

// Format status
function formatStatus(status) {
  const statusMap = {
    'placed': 'Placed',
    'accepted': 'Accepted',
    'preparing': 'Preparing',
    'ready': 'Ready',
    'waiting_pickup': 'Waiting Pickup',
    'assigned': 'Assigned',
    'in_transit': 'In Transit',
    'arrived_customer': 'Arrived',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled'
  };
  return statusMap[status] || status;
}

// Update order status
async function updateStatus(orderId, newStatus) {
  try {
    // Prefer same-origin relative paths to avoid localhost/127.0.0.1 mismatches
    let endpoint = '';
    if (newStatus === 'accepted') endpoint = `/api/orders/${orderId}/accept`;
    else if (newStatus === 'preparing') endpoint = `/api/orders/${orderId}/status`;
    else if (newStatus === 'ready') endpoint = `/api/orders/${orderId}/pack`;
    else if (newStatus === 'cancelled') endpoint = `/api/orders/${orderId}/reject`;

    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(newStatus === 'preparing' ? { status: 'preparing' } : {})
    });
    const data = await response.json();
    if (response.ok) {
      loadVendorOrders();
      loadEarnings();
    } else {
      alert(data.error || 'Failed to update');
    }
  } catch (error) {
    console.error('Error updating status:', error);
    alert('Error updating status. Please try again.');
  }
}

// Expose updateStatus to global scope for inline onclick handlers
window.updateStatus = updateStatus;

// Update expecting orders metric (new or in-progress)
function updateExpectingCount(orders) {
  try {
    const expecting = (orders || []).filter(o => ['placed','accepted','preparing','ready','waiting_pickup','assigned','in_transit','arrived_customer'].includes(o.status)).length;
    const el = document.getElementById('expecting-orders');
    if (el) el.textContent = String(expecting);
  } catch {}
}

// Load vendor products
async function loadVendorProducts() {
  const tbody = document.getElementById('vendor-products');
  if (!tbody) return;
  try {
  const res = await fetch(`${API_BASE_URL}/products/mine`, { headers: { 'Authorization': `Bearer ${token}` } });
  const data = await safeParseJson(res);
  if (!res.ok) throw new Error((data && data.error) || 'Failed to load products');
    const items = data.items || [];
    if (!items.length) {
      tbody.innerHTML = '<tr><td colspan="4" class="text-muted">No products yet</td></tr>';
      return;
    }
    tbody.innerHTML = items.map(p => `
      <tr>
        <td>
          ${p.imageUrl ? `<img src="${p.imageUrl}" alt="${p.name}" class="me-2" style="width:40px;height:40px;object-fit:cover;border-radius:6px;">` : ''}
          ${p.name}
        </td>
        <td>â‚¦${Number(p.price||0).toLocaleString()}</td>
        <td>${p.quantity ?? 0}</td>
        <td>${p.unit || (p.quantity ? p.quantity : 'â€”')}</td>
      </tr>`).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="4" class="text-danger">${e.message}</td></tr>`;
  }
}

// Load earnings (READ-ONLY for transparency)
async function loadEarnings() {
  try {
    const response = await fetch(`${API_BASE_URL}/vendors/wallet`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    const data = await safeParseJson(response);
    if (response.ok && data) {
      // Display total sales (not "earnings" - it's read-only)
      const totalSales = data.totalSales || 0;
      const completedSales = data.completedSales || 0;
      const pendingSales = data.pendingSales || 0;
      
      document.getElementById('total-earnings').textContent = `â‚¦${Number(totalSales).toLocaleString()}`;
      
      // Update label to reflect it's sales record, not withdrawable balance
      const earningsLabel = document.querySelector('label[for="total-earnings"]');
      if (earningsLabel) {
        earningsLabel.innerHTML = '<i class="bi bi-cash-stack"></i> Total Sales (Record Only)';
      }
      
      // Add info message if not already present
      const earningsCard = document.getElementById('total-earnings')?.closest('.card');
      if (earningsCard && !earningsCard.querySelector('.sales-info')) {
        const info = document.createElement('small');
        info.className = 'text-muted sales-info d-block mt-2';
        info.innerHTML = `<i class="bi bi-info-circle"></i> Completed: â‚¦${completedSales.toLocaleString()} | Pending: â‚¦${pendingSales.toLocaleString()}<br>Admin will process payout after event.`;
        earningsCard.querySelector('.card-body').appendChild(info);
      }
      
      // Recompute total orders from list
      const orders = document.querySelectorAll('#vendor-orders .card');
      document.getElementById('total-orders').textContent = String(orders.length);
    }
  } catch (error) {
    console.error('Error loading sales data:', error);
  }
}

// Auto-refresh every 15 seconds
setInterval(() => {
  loadVendorOrders();
  loadEarnings();
}, 15000);

// Load data when page loads
document.addEventListener('DOMContentLoaded', () => {
  loadVendorProfile();
  loadVendorOrders();
  loadEarnings();
  loadVendorProducts();
  setupRealtime();
  setupNotificationsUI();
  setupProfileDropdown(); // NEW: Setup profile dropdown
  setupLogout();
  setupRealtime(); // Initialize real-time features
});

// Global socket instance
let globalSocket = null;
let currentUserId = null;

// Safe JSON parser: only attempt json() when server responds with JSON content-type
async function safeParseJson(response) {
  try {
    const contentType = response.headers.get('content-type') || '';
    if (contentType.includes('application/json')) {
      return await response.json();
    }
    // Fallback: try to parse text and return as an object if possible
    const text = await response.text();
    try {
      return JSON.parse(text);
    } catch {
      // Not JSON - return null so caller can handle gracefully
      console.warn('safeParseJson: response not JSON', text && text.slice ? text.slice(0,120) : text);
      return null;
    }
  } catch (e) {
    console.error('safeParseJson error', e);
    return null;
  }
}

function setupRealtime() {
  if (typeof io === 'undefined') return;
  try {
    const user = JSON.parse(localStorage.getItem('user') || '{}');
    currentUserId = user._id;
    
    globalSocket = io(FILE_BASE_URL, { transports: ['websocket','polling'] });
    
    // Identify with server
    if (user?._id) {
      globalSocket.emit('identify', { userId: user._id, role: 'vendor' });
    } else {
      globalSocket.emit('identify', { role: 'vendor' });
    }
    
    // Connection status
    globalSocket.on('connect', () => {
      console.log('âœ… Socket connected');
      updateOnlineStatus(true);
    });
    
    globalSocket.on('disconnect', () => {
      console.log('âŒ Socket disconnected');
      updateOnlineStatus(false);
    });
    
    // Order updates
    const refresh = () => { 
      loadVendorOrders(); 
      loadEarnings(); 
    };
    
    globalSocket.on('order:update', (data) => {
      console.log('Order update:', data);
      refresh();
      if (data.message) {
        showToast(data.message, 'info');
        playNotificationSound(); // Play sound for order updates
      }
    });
    
    globalSocket.on('order:new', (data) => {
      console.log('New order:', data);
      refresh();
      showToast('ðŸ”” New order received!', 'success');
      playNotificationSound();
      showBrowserNotification(
        'QuickServe - New Order!', 
        'You have a new order. Check your dashboard!',
        '/favicon.ico'
      );
    });
    
    // Auto-show "Call Dispatcher" popup when order accepted
    globalSocket.on('order:accepted_show_dispatcher', (data) => {
      console.log('Order accepted, showing dispatcher popup:', data);
      showCallDispatcherPopup(data.orderId);
      playNotificationSound(); // Play sound when showing popup
    });
    
    // Dispatcher assigned notification
    globalSocket.on('order:dispatcher_assigned', (data) => {
      console.log('Dispatcher assigned:', data);
      showToast(data.message || 'ðŸš´ Dispatcher on the way to pickup!', 'success');
      refresh();
      closeCallDispatcherPopup();
      playNotificationSound(); // Play sound when dispatcher assigned
      showBrowserNotification(
        'QuickServe - Dispatcher Assigned!',
        data.message || 'A dispatcher is on the way to collect your order!',
        '/favicon.ico'
      );
    });
    
    // Generic order notification (friendly messages from server)
    globalSocket.on('order:notification', (payload) => {
      try {
        console.log('order:notification', payload);
        if (payload && payload.orderId) {
          showToast(payload.message || 'Order update', 'info');
          playNotificationSound();
          showBrowserNotification('Order Notification', payload.message || 'Order update');
          // Refresh if this vendor's order is affected
          refresh();
        }
      } catch (e) { console.error(e); }
    });

    // Update online/offline status when server broadcasts
    globalSocket.on('user:online', (p) => {
      try {
        if (p?.userId && p.userId === currentUserId) updateOnlineStatus(true);
      } catch (e) {}
    });
    globalSocket.on('user:offline', (p) => {
      try {
        if (p?.userId && p.userId === currentUserId) updateOnlineStatus(false);
      } catch (e) {}
    });

    // When order is ready (dispatchers should pick up)
    globalSocket.on('order:ready', (payload) => {
      try {
        showToast(payload.message || 'Order ready for pickup', 'warning');
        playNotificationSound();
        refresh();
      } catch (e) { console.error(e); }
    });
    
  } catch (e) {
    console.warn('Vendor socket setup failed:', e.message);
  }
}

// Update online/offline indicator
function updateOnlineStatus(isOnline) {
  const statusIndicator = document.getElementById('onlineStatus');
  if (statusIndicator) {
    statusIndicator.className = `status-indicator ${isOnline ? 'online' : 'offline'}`;
    statusIndicator.title = isOnline ? 'Online' : 'Offline';
  }
}

// Show "Call Dispatcher" popup automatically
let dispatcherPopupOrderId = null;

function showCallDispatcherPopup(orderId) {
  dispatcherPopupOrderId = orderId;
  
  const popup = document.getElementById('callDispatcherModal');
  if (!popup) {
    // Create popup dynamically
    const modal = document.createElement('div');
    modal.id = 'callDispatcherModal';
    modal.className = 'modal fade';
    modal.innerHTML = `
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
          <div class="modal-header bg-success text-white">
            <h5 class="modal-title">Order Accepted!</h5>
            <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
          </div>
          <div class="modal-body text-center">
            <div class="mb-3">
              <i class="bi bi-check-circle text-success" style="font-size: 3rem;"></i>
            </div>
            <h5>Order #<span id="popupOrderId"></span></h5>
            <p class="text-muted">Start preparing the order. When ready, call a dispatcher for pickup.</p>
            <div class="alert alert-info">
              <i class="bi bi-info-circle me-2"></i>
              The "Call Dispatcher" button will appear here when order is ready.
            </div>
            <button id="markReadyBtn" class="btn btn-primary btn-lg w-100" onclick="markOrderReady()">
              <i class="bi bi-check2-circle me-2"></i>Mark Order Ready & Call Dispatcher
            </button>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modal);
  }
  
  // Update order ID
  const orderIdSpan = document.getElementById('popupOrderId');
  if (orderIdSpan) {
    orderIdSpan.textContent = orderId.slice(-6).toUpperCase();
  }
  
  // Show modal
  const modalInstance = new bootstrap.Modal(document.getElementById('callDispatcherModal'));
  modalInstance.show();
}

// Close popup
function closeCallDispatcherPopup() {
  const modal = bootstrap.Modal.getInstance(document.getElementById('callDispatcherModal'));
  if (modal) {
    modal.hide();
  }
}

// Mark order ready and call dispatchers
async function markOrderReady() {
  if (!dispatcherPopupOrderId) return;
  
  const btn = document.getElementById('markReadyBtn');
  btn.disabled = true;
  btn.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Calling Dispatchers...';
  
  try {
    // Use pack endpoint (moves to waiting_pickup and notifies dispatchers)
    const response = await fetch(`/api/orders/${dispatcherPopupOrderId}/pack`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (response.ok) {
      const data = await response.json();
      showToast('Order marked ready! Broadcasting to all dispatchers...', 'success');
      
      // Update button to show waiting state
      btn.innerHTML = '<i class="bi bi-hourglass-split me-2"></i>Waiting for Dispatcher...';
      btn.className = 'btn btn-warning btn-lg w-100';
      
      // Refresh orders
      loadVendorOrders();
    } else {
      throw new Error('Failed to mark order ready');
    }
  } catch (error) {
    console.error('Error marking order ready:', error);
    showToast('Error calling dispatchers', 'danger');
    btn.disabled = false;
    btn.innerHTML = '<i class="bi bi-check2-circle me-2"></i>Mark Order Ready & Call Dispatcher';
  }
}

// Make function global
window.markOrderReady = markOrderReady;

// Note: playNotificationSound is defined at the top of this module.

// Show toast notification
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

// ===== Notifications UI (vendor) =====
async function fetchNotifications() {
  try {
    const token = localStorage.getItem('eventToken');
    const res = await fetch(`${API_BASE_URL}/notifications`, { headers: { 'Authorization': `Bearer ${token}` } });
    const data = await safeParseJson(res);
    if (res.ok && data) renderNotifications(data.items || [], data.unread || 0);
  } catch {}
}

function renderNotifications(items, unread) {
  const list = document.getElementById('notifList');
  const badge = document.getElementById('notifCount');
  if (badge) badge.textContent = String(unread || 0);
  if (!list) return;
  if (!items.length) {
    list.innerHTML = '<div class="p-3 text-muted">No notifications yet</div>';
    return;
  }
  list.innerHTML = items.map(n => `<div class="list-group-item small"><div class="fw-semibold">${n.title||'Notification'}</div><div>${n.message||''}</div><div class="text-muted">${new Date(n.createdAt).toLocaleString()}</div></div>`).join('');
}

// Load vendor profile info and populate UI
async function loadVendorProfile() {
  try {
    const res = await fetch(`${API_BASE_URL}/vendors/profile`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await safeParseJson(res);
    
    if (res.ok) {
      const vendorId = data.vendorId || 'VEN-000';
      const businessName = data.businessName || 'My Business';
      const ownerName = data.ownerName || 'Vendor Owner';
      const category = data.category || 'Restaurant';
      const availabilityStatus = data.availabilityStatus || 'online';
      
  // Update welcome banner (use business name)
      const welcomeNameEl = document.getElementById('welcomeName');
      const welcomeVendorIdEl = document.getElementById('welcomeVendorId');
  if (welcomeNameEl) welcomeNameEl.textContent = businessName;
      if (welcomeVendorIdEl) welcomeVendorIdEl.textContent = vendorId;
      
      // Update status indicator
      const onlineStatusEl = document.getElementById('onlineStatus');
      if (onlineStatusEl) {
        onlineStatusEl.className = `status-indicator ${availabilityStatus}`;
        onlineStatusEl.title = availabilityStatus.charAt(0).toUpperCase() + availabilityStatus.slice(1);
      }
      // Top heading display
      const vendorTopName = document.getElementById('vendorTopName');
      const vendorTopStatus = document.getElementById('vendorTopStatus');
      if (vendorTopName) vendorTopName.textContent = businessName;
      if (vendorTopStatus) {
        vendorTopStatus.innerHTML = `<span class="status-indicator ${availabilityStatus}" style="width:12px;height:12px;border-radius:50%;display:inline-block;margin-left:6px;vertical-align:middle;"></span> <small class="text-muted ms-2">${availabilityStatus === 'online' ? 'Online' : 'Offline'}</small>`;
      }
      
      // Update profile dropdown
      const profileNameEl = document.getElementById('profileName');
      const profileVendorIdEl = document.getElementById('profileVendorId');
      const profileOwnerNameEl = document.getElementById('profileOwnerName');
      const profileBusinessNameEl = document.getElementById('profileBusinessName');
      const profileCategoryEl = document.getElementById('profileCategory');
      
      if (profileNameEl) profileNameEl.textContent = businessName;
      if (profileVendorIdEl) profileVendorIdEl.textContent = vendorId;
      if (profileOwnerNameEl) profileOwnerNameEl.textContent = ownerName;
      if (profileBusinessNameEl) profileBusinessNameEl.textContent = businessName;
      if (profileCategoryEl) profileCategoryEl.textContent = category;
    }
  } catch (error) {
    console.error('Error loading vendor profile:', error);
  }
}

// Setup profile dropdown toggle
function setupProfileDropdown() {
  const profileBtn = document.getElementById('profileBtn');
  const profileMenu = document.getElementById('profileMenu');
  
  if (profileBtn && profileMenu) {
    profileBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      profileMenu.classList.toggle('show');
    });
    
    // Close dropdown when clicking outside
    document.addEventListener('click', (e) => {
      if (!profileMenu.contains(e.target) && !profileBtn.contains(e.target)) {
        profileMenu.classList.remove('show');
      }
    });
  }
}

// Logout handler
function setupLogout() {
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', (e) => {
      e.preventDefault();
      localStorage.removeItem('eventToken');
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = 'login.html';
    });
  }
}

function setupNotificationsUI() {
  const btn = document.getElementById('notifBtn');
  const dd = document.getElementById('notifDropdown');
  if (btn && dd) {
    btn.addEventListener('click', async () => {
      dd.style.display = dd.style.display === 'block' ? 'none' : 'block';
      if (dd.style.display === 'block') await fetchNotifications();
    });
    document.addEventListener('click', (e) => {
      if (!dd.contains(e.target) && e.target !== btn) dd.style.display = 'none';
    });
  }
}

// ðŸ†• Fetch group status for multi-vendor orders
async function fetchGroupStatus(orderGroupId, currentOrderId) {
  try {
    const token = localStorage.getItem('eventToken') || localStorage.getItem('token');
    const response = await fetch(`${API_BASE_URL}/orders/group/${orderGroupId}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
  if (!response.ok) return;
  const parsed = await safeParseJson(response);
  if (!parsed) return;
  const { orders } = parsed;
    if (!orders || orders.length === 0) return;
    
    const readyCount = orders.filter(o => o.status === 'ready' || o.status === 'delivered').length;
    const totalCount = orders.length;
    const statusElement = document.getElementById(`groupStatus-${currentOrderId}`);
    
    if (statusElement) {
      if (readyCount === totalCount) {
        statusElement.innerHTML = `âœ… All ${totalCount} vendors ready! Waiting for dispatcher...`;
        statusElement.className = 'text-success fw-bold';
      } else {
        statusElement.innerHTML = `â³ ${readyCount}/${totalCount} vendors ready (including you)`;
        statusElement.className = 'text-warning';
      }
    }
  } catch (error) {
    console.error('Error fetching group status:', error);
  }
}

