// admin.js - QuickServe Admin Dashboard
import CONFIG, { API_BASE_URL, FILE_BASE_URL } from './config.js';
import { playNotificationSound, ensureNotificationPermission, showBrowserNotification } from './notify.js';

const token = localStorage.getItem('eventToken') || localStorage.getItem('token');
// Local caches for derived analytics
let __ADMIN_LAST_ORDERS__ = [];
let __ADMIN_ONLINE_CACHE__ = { users: [], summary: { total: 0, vendors: 0, dispatchers: 0, customers: 0, admins: 0 } };

// Initialize dashboard
document.addEventListener('DOMContentLoaded', () => {
    if (!token) {
        window.location.href = 'login.html';
        return;
    }
    // Ask for notification permission on first user interaction
    document.addEventListener('click', function oneTimePerm() {
        try { ensureNotificationPermission(); } catch {}
        document.removeEventListener('click', oneTimePerm);
    }, { once: true });
    
    loadDashboardData();
    setupRealtime();
    startAutoRefresh();
    setupNotificationsUI();
});

// Load all dashboard data
async function loadDashboardData() {
    await Promise.all([
        loadStats(),
        loadMultiVendorGroups(),
        loadOnlineUsers(),
        loadLiveOrders()
    ]);
    // Derive charts and figures that depend on orders
    try { updateDerivedFromOrders(); } catch {}
}

// Load dashboard stats
async function loadStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/admin/stats`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.ok) {
            const data = await response.json();
            const mapped = {
                totalOrders: data.orders || 0,             // Today
                totalOrdersAll: data.ordersTotal || 0,      // All-time
                totalRevenue: 0,
                activeVendors: data.vendors || 0,          // Active vendors only
                activeDispatchers: data.riders || 0,        // Count of rider accounts (not online)
                pendingOrders: data.pending || 0,
                deliveredToday: data.deliveredToday || 0,
                serviceCharges: data.adminFees || 0
            };
            updateStats(mapped);
        }
    } catch (error) {
        console.error('Error loading stats:', error);
    }
}

// Update stats display
function updateStats(data) {
    document.getElementById('totalOrders').textContent = data.totalOrders || 0;
    document.getElementById('totalRevenue').textContent = `â‚¦${formatMoney(data.totalRevenue || 0)}`;
    document.getElementById('activeVendors').textContent = data.activeVendors || 0;
    document.getElementById('activeDispatchers').textContent = data.activeDispatchers || 0;
    document.getElementById('service-charge-total').textContent = `â‚¦${formatMoney(data.serviceCharges || 0)}`;
    document.getElementById('pendingCount').textContent = data.pendingOrders || 0;
    document.getElementById('deliveredCount').textContent = data.deliveredToday || 0;
    
    const successRate = data.totalOrders > 0 
        ? Math.round((data.deliveredToday / data.totalOrders) * 100) 
        : 0;
    document.getElementById('successRate').textContent = `${successRate}%`;
}

// Load live orders
async function loadLiveOrders() {
    try {
        const response = await fetch(`${API_BASE_URL}/admin/orders`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.ok) {
            const data = await response.json();
            __ADMIN_LAST_ORDERS__ = Array.isArray(data.orders) ? data.orders : [];
            displayOrders(__ADMIN_LAST_ORDERS__);
            updateDerivedFromOrders();
        } else {
            document.getElementById('live-orders').innerHTML = 
                '<div class="alert alert-warning">Failed to load orders. Please refresh.</div>';
        }
    } catch (error) {
        console.error('Error loading orders:', error);
        document.getElementById('live-orders').innerHTML = 
            '<div class="alert alert-danger">Error connecting to server.</div>';
    }
}

// Compute service charge (â‚¦100 per delivered order), total revenue and vendor earnings from current orders
function updateDerivedFromOrders() {
    const orders = __ADMIN_LAST_ORDERS__ || [];
    const delivered = orders.filter(o => o.status === 'delivered');
    const deliveredCount = delivered.length;
    const SERVICE_CHARGE_NGN = Number(CONFIG?.SERVICE_CHARGE || 100);
    const serviceCharges = deliveredCount * SERVICE_CHARGE_NGN;
    const totalRevenue = orders.reduce((sum, o) => sum + Number(o.total || o.subtotal || 0), 0);
    const totalEarnings = Math.max(0, totalRevenue - serviceCharges);

    const scEl = document.getElementById('service-charge-total');
    if (scEl) scEl.textContent = `â‚¦${formatMoney(serviceCharges)}`;

    const revEl = document.getElementById('totalRevenue');
    if (revEl) revEl.textContent = `â‚¦${formatMoney(totalRevenue)}`;

    const ordEl = document.getElementById('totalOrdersAll');
    if (ordEl) ordEl.textContent = String(orders.length);

    const earnEl = document.getElementById('totalEarnings');
    if (earnEl) earnEl.textContent = `â‚¦${formatMoney(totalEarnings)}`;

    // Update vendor earnings table
    renderVendorEarningsFromOrders(orders);
}

// Display orders in table
function displayOrders(orders) {
    const container = document.getElementById('live-orders');
    
    if (orders.length === 0) {
        container.innerHTML = '<p class="text-center text-muted py-4">No orders yet today</p>';
        return;
    }
    
    let html = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Order ID</th>
                        <th>Customer</th>
                        <th>Vendor</th>
                        <th>Items</th>
                        <th>Total</th>
                        <th>Status</th>
                        <th>Time</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
    `;
    
    orders.forEach(order => {
        const orderTime = new Date(order.createdAt).toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
        });
        
        html += `
            <tr>
                <td><strong>#${order._id.slice(-6)}</strong></td>
                <td>${order.userId?.name || 'Guest'}</td>
                <td>${order.vendorId?.businessName || 'N/A'}</td>
                <td>${order.items?.length || 0} items</td>
                <td><strong>â‚¦${formatMoney(order.total)}</strong></td>
                <td>${getStatusBadge(order.status)}</td>
                <td>${orderTime}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="viewOrderDetails('${order._id}')">
                        <i class="bi bi-eye"></i>
                    </button>
                </td>
            </tr>
        `;
    });
    
    html += `
                </tbody>
            </table>
        </div>
    `;
    
    container.innerHTML = html;
}

// Get status badge HTML
function getStatusBadge(status) {
    const statusMap = {
        'pending': { class: 'badge-pending', text: 'Pending' },
        'preparing': { class: 'badge-preparing', text: 'Preparing' },
        'ready': { class: 'badge-ready', text: 'Ready' },
        'delivering': { class: 'badge-delivering', text: 'Delivering' },
        'delivered': { class: 'badge-delivered', text: 'Delivered' }
    };
    
    const statusInfo = statusMap[status] || { class: 'badge-pending', text: status };
    return `<span class="badge-status ${statusInfo.class}">${statusInfo.text}</span>`;
}

// Load vendor earnings
// Display vendor earnings from current orders snapshot
function renderVendorEarningsFromOrders(orders) {
    const container = document.getElementById('vendor-earnings');
    if (!container) return;

    if (!orders || !orders.length) {
        container.innerHTML = '<p class="text-center text-muted py-4">No vendors registered yet</p>';
        return;
    }
    // Group by vendor id
    const byVendor = new Map();
    orders.forEach(o => {
        const v = o.vendorId; // mapped in /api/admin/orders
        if (!v) return;
        const id = String(v._id || v);
        if (!byVendor.has(id)) byVendor.set(id, { name: v.businessName || 'Vendor', category: v.category || 'General', orders: 0, ready: 0, delivered: 0, revenue: 0 });
        const row = byVendor.get(id);
        row.orders += 1;
        row.revenue += Number(o.total || o.subtotal || 0);
        if (o.status === 'ready') row.ready += 1;
        if (o.status === 'delivered') row.delivered += 1;
    });

    const rows = Array.from(byVendor.values());
    let html = `
        <div class="table-responsive">
            <table class="table table-hover">
                <thead>
                    <tr>
                        <th>Vendor</th>
                        <th>Category</th>
                        <th>Orders</th>
                        <th>Ready</th>
                        <th>Delivered</th>
                        <th>Revenue</th>
                    </tr>
                </thead>
                <tbody>
    `;
    rows.forEach(r => {
        html += `
            <tr>
                <td><strong>${r.name}</strong></td>
                <td>${r.category}</td>
                <td>${r.orders}</td>
                <td>${r.ready}</td>
                <td>${r.delivered}</td>
                <td><strong>â‚¦${formatMoney(r.revenue)}</strong></td>
            </tr>
        `;
    });
    
    html += `
                </tbody>
            </table>
        </div>
    `;
    
    container.innerHTML = html;
}

// View order details
window.viewOrderDetails = function(orderId) {
    window.location.href = `track.html?orderId=${orderId}`;
}

// Format money
function formatMoney(amount) {
    return Number(amount).toLocaleString('en-NG', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    });
}

// Auto-refresh every 10 seconds
function startAutoRefresh() {
    setInterval(() => {
        loadDashboardData();
    }, 10000);
}

// Export for use in HTML
window.viewOrderDetails = viewOrderDetails;

// Socket realtime updates for admin
// ===== Realtime + Centralized Chat Wiring =====
let adminSocket = null;
const conversations = new Map(); // key: userId/guestId, value: { id, role, name, unread, messages: [] }
let selectedConvId = null;

function ensureSocketClientLoaded() {
    return new Promise((resolve) => {
        if (typeof window.io !== 'undefined') return resolve();
        const s = document.createElement('script');
        s.src = 'https://cdn.jsdelivr.net/npm/socket.io-client@4.7.5/dist/socket.io.min.js';
        s.onload = () => resolve();
        document.head.appendChild(s);
    });
}

function displayNameForConversation(conv) {
    if (!conv) return 'Unknown';
    const idSuffix = (conv.id || '').slice(-4) || 'anon';
    if (conv.role && conv.role !== 'user') return `${conv.role.toUpperCase()} â€¢ â€¦${idSuffix}`;
    return `User â€¢ â€¦${idSuffix}`;
}

function updateTotalUnreadBadge() {
    let total = 0;
    conversations.forEach(c => { total += Number(c.unread || 0); });
    const badge = document.getElementById('chatTotalUnread');
    if (badge) badge.textContent = String(total);
}

function renderConversationList() {
    const list = document.getElementById('chatList');
    if (!list) return;
    if (conversations.size === 0) {
        list.innerHTML = '<div class="p-3 text-muted small">No conversations yet</div>';
        return;
    }
    const items = Array.from(conversations.values()).sort((a,b) => {
        const at = a.messages?.[a.messages.length-1]?.ts || 0;
        const bt = b.messages?.[b.messages.length-1]?.ts || 0;
        return bt - at;
    }).map(conv => {
        const active = conv.id === selectedConvId ? 'active' : '';
        const unread = conv.unread ? `<span class="badge bg-danger ms-auto">${conv.unread}</span>` : '';
        return `<button class="list-group-item list-group-item-action d-flex align-items-center ${active}" data-id="${conv.id}">
            <div class="me-2 rounded-circle bg-warning" style="width:10px;height:10px"></div>
            <div class="flex-grow-1 text-start">
                <div class="fw-semibold small">${conv.name || displayNameForConversation(conv)}</div>
                <div class="text-muted small text-truncate" style="max-width:220px">${conv.messages?.[conv.messages.length-1]?.content || ''}</div>
            </div>
            ${unread}
        </button>`;
    }).join('');
    list.innerHTML = items;
    // bind clicks
    list.querySelectorAll('[data-id]').forEach(el => {
        el.addEventListener('click', () => {
            const id = el.getAttribute('data-id');
            if (!id) return;
            selectedConvId = id;
            const conv = conversations.get(id);
            if (conv) { conv.unread = 0; }
            updateTotalUnreadBadge();
            renderConversationList();
            renderMessages();
        });
    });
}

function renderMessages() {
    const box = document.getElementById('chatMessages');
    const input = document.getElementById('chatInput');
    if (!box) return;
    const conv = selectedConvId ? conversations.get(selectedConvId) : null;
    if (!conv) {
        box.innerHTML = '<div class="p-3 text-muted small">Select a conversation</div>';
        if (input) input.placeholder = 'Replyâ€¦ (select a conversation first)';
        return;
    }
    const html = (conv.messages || []).map(m => {
        const who = m.fromRole === 'admin' ? 'You' : (m.fromRole || 'User');
        const align = m.fromRole === 'admin' ? 'text-end' : 'text-start';
        return `<div class="${align}"><span class="badge bg-light text-dark border">${who}:</span> ${escapeHtml(m.content)}</div>`;
    }).join('');
    box.innerHTML = html || '<div class="p-3 text-muted small">No messages yet</div>';
    box.scrollTop = box.scrollHeight;
    if (input) input.placeholder = 'Replyâ€¦ (Enter to send)';
}

function escapeHtml(s='') {
    return String(s)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function upsertConversationFromMessage(m) {
    const isFromAdmin = m.fromRole === 'admin';
    const id = isFromAdmin ? (m.to || m.toUserId || m.userId) : (m.from || m.userId);
    const role = isFromAdmin ? (m.toRole || 'user') : (m.fromRole || 'user');
    if (!id) return null; // cannot thread without id
    let conv = conversations.get(id);
    if (!conv) {
        conv = { id, role, name: '', unread: 0, messages: [] };
        conversations.set(id, conv);
    }
    conv.role = role || conv.role;
    conv.name = conv.name || displayNameForConversation(conv);
    conv.messages.push({ from: m.from, fromRole: m.fromRole, content: m.content, ts: m.ts || Date.now() });
    if (selectedConvId !== id && !isFromAdmin) {
        conv.unread = (conv.unread || 0) + 1;
    }
    return conv;
}

async function setupRealtime() {
    try {
        await ensureSocketClientLoaded();
        adminSocket = window.io ? window.io(FILE_BASE_URL, { transports: ['websocket', 'polling'] }) : null;
        if (!adminSocket) return;
        adminSocket.emit('identify', { role: 'admin' });

        const refresh = () => { loadLiveOrders(); loadStats(); };
        adminSocket.on('order:update', (p) => { refresh(); playNotificationSound(); showBrowserNotification('Order Updated', 'An order status just changed.'); });
        adminSocket.on('order:new', (p) => { refresh(); playNotificationSound(); showBrowserNotification('New Order', 'A new order has been placed.'); });
    adminSocket.on('order:notification', (payload) => { try { refresh(); playNotificationSound(); showBrowserNotification('Order Notification', payload?.message || 'Order update'); } catch (e) {} });
        adminSocket.on('notification:admin', () => {
            loadDashboardData();
            const c = document.getElementById('notifCount');
            if (c) c.textContent = String(Number(c.textContent||'0') + 1);
            fetchNotifications();
            playNotificationSound();
            showBrowserNotification('Admin Notification', 'You have a new notification.');
        });
        adminSocket.on('dispatch:request', () => { loadLiveOrders(); playNotificationSound(); showBrowserNotification('Dispatcher Request', 'A vendor called for pickup.'); });

    // Centralized chat listeners
        adminSocket.on('chat:message', (m={}) => {
            try {
                if (!m || !m.content) return;
                const conv = upsertConversationFromMessage(m);
                updateTotalUnreadBadge();
                renderConversationList();
                if (conv && conv.id === selectedConvId) renderMessages();
                // Also bump bell for visibility if from non-admin
                if ((m.fromRole && m.fromRole !== 'admin') || (!m.fromRole && m.from !== 'admin')) {
                    const c = document.getElementById('notifCount');
                    if (c) c.textContent = String(Number(c.textContent||'0') + 1);
                    playNotificationSound();
                    showBrowserNotification('New Message', m.content || 'New chat message');
                }
            } catch {}
        });

        // Send handler
        const input = document.getElementById('chatInput');
        input?.addEventListener('keypress', (e) => {
            if (e.key !== 'Enter') return;
            const msg = input.value.trim();
            if (!msg || !selectedConvId) return;
            input.value = '';
            const payload = { fromRole: 'admin', to: selectedConvId, content: msg, ts: Date.now() };
            adminSocket.emit('chat:message', payload);
            // reflect locally
            upsertConversationFromMessage({ ...payload, from: 'admin' });
            renderMessages();
            renderConversationList();
        });

        // Live user presence updates
        adminSocket.on('user:online', () => { loadOnlineUsers(); });
        adminSocket.on('user:offline', () => { loadOnlineUsers(); });
    } catch (e) {
        console.warn('Admin socket setup failed:', e?.message || e);
    }
}

// ===== Multi-Vendor Order Groups Monitoring =====
async function loadMultiVendorGroups() {
    try {
        const response = await fetch(`${API_BASE_URL}/admin/orders`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        
        if (response.ok) {
            const data = await response.json();
            const orders = data.orders || [];
            
            // Group orders by orderGroupId
            const groups = {};
            orders.forEach(order => {
                if (order.orderGroupId && order.isMultiVendor) {
                    if (!groups[order.orderGroupId]) {
                        groups[order.orderGroupId] = [];
                    }
                    groups[order.orderGroupId].push(order);
                }
            });
            
            displayMultiVendorGroups(groups);
        }
    } catch (error) {
        console.error('Error loading multi-vendor groups:', error);
    }
}

function displayMultiVendorGroups(groups) {
    const container = document.getElementById('multi-vendor-groups');
    const countBadge = document.getElementById('multiVendorCount');
    
    const groupCount = Object.keys(groups).length;
    if (countBadge) countBadge.textContent = groupCount;
    
    if (groupCount === 0) {
        container.innerHTML = '<p class="text-center text-muted py-4">No multi-vendor orders at the moment</p>';
        return;
    }
    
    let html = '';
    for (const [groupId, orders] of Object.entries(groups)) {
        const totalVendors = orders.length;
        const acceptedCount = orders.filter(o => ['accepted', 'preparing', 'ready', 'in_transit', 'delivered'].includes(o.status)).length;
        const readyCount = orders.filter(o => o.status === 'ready').length;
        const allReady = readyCount === totalVendors;
        
        const progressPercent = (acceptedCount / totalVendors) * 100;
        const statusClass = allReady ? 'success' : acceptedCount > 0 ? 'warning' : 'secondary';
        
        html += `
            <div class="card mb-3 border-${statusClass}">
                <div class="card-body">
                    <div class="d-flex justify-content-between align-items-start mb-3">
                        <div>
                            <h6 class="mb-1">
                                <i class="bi bi-cart-check text-${statusClass}"></i>
                                Group: ${groupId}
                            </h6>
                            <small class="text-muted">
                                ${totalVendors} vendor${totalVendors > 1 ? 's' : ''}
                            </small>
                        </div>
                        <span class="badge bg-${statusClass}">
                            ${allReady ? 'âœ… All Ready!' : `${readyCount}/${totalVendors} Ready`}
                        </span>
                    </div>
                    
                    <div class="progress mb-3" style="height: 8px;">
                        <div class="progress-bar bg-${statusClass}" 
                             role="progressbar" 
                             style="width: ${progressPercent}%"></div>
                    </div>
                    
                    <div class="row g-2">
        `;
        
        orders.forEach((order, idx) => {
            const statusIcon = order.status === 'ready' ? 'âœ…' : 
                             order.status === 'accepted' || order.status === 'preparing' ? 'ðŸ•' : 'â³';
            const statusText = order.status === 'ready' ? 'Ready' :
                             order.status === 'accepted' ? 'Accepted' :
                             order.status === 'preparing' ? 'Preparing' : 'Pending';
            
            html += `
                        <div class="col-md-4">
                            <div class="border rounded p-2 ${order.status === 'ready' ? 'bg-success bg-opacity-10' : ''}">
                                <div class="d-flex align-items-center gap-2">
                                    <span style="font-size: 24px;">${statusIcon}</span>
                                    <div class="flex-grow-1">
                                        <div class="fw-semibold small">Vendor ${idx + 1}</div>
                                        <div class="text-muted" style="font-size: 11px;">${statusText}</div>
                                        <div class="text-muted" style="font-size: 11px;">â‚¦${formatMoney(order.total)}</div>
                                    </div>
                                </div>
                            </div>
                        </div>
            `;
        });
        
        html += `
                    </div>
                </div>
            </div>
        `;
    }
    
    container.innerHTML = html;
}

// ===== Online Users Monitoring =====
async function loadOnlineUsers() {
    try {
        const res = await fetch(`${API_BASE_URL.replace('/api','')}/api/system/online-users`);
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'Failed to load online users');
        __ADMIN_ONLINE_CACHE__ = data;
        renderOnlineUsers();
    } catch (error) {
        console.error('Error loading online users:', error);
    }
}

function renderOnlineUsers() {
    const users = Array.isArray(__ADMIN_ONLINE_CACHE__?.users) ? __ADMIN_ONLINE_CACHE__.users : [];
    const vendors = users.filter(u => u.role === 'vendor');
    const dispatchers = users.filter(u => u.role === 'dispatcher');
    const vendorsEl = document.getElementById('online-vendors');
    const dispatchersEl = document.getElementById('online-dispatchers');
    document.getElementById('onlineVendorsCount').textContent = String(vendors.length);
    document.getElementById('onlineDispatchersCount').textContent = String(dispatchers.length);
    if (vendorsEl) vendorsEl.innerHTML = vendors.length ? vendors.map(v => `<div class="small">â€¢ ${String(v.userId).slice(-6)} <span class="text-muted">(${new Date(v.lastSeen).toLocaleTimeString()})</span></div>`).join('') : '<p class="text-muted small">No vendors online</p>';
    if (dispatchersEl) dispatchersEl.innerHTML = dispatchers.length ? dispatchers.map(v => `<div class="small">â€¢ ${String(v.userId).slice(-6)} <span class="text-muted">(${new Date(v.lastSeen).toLocaleTimeString()})</span></div>`).join('') : '<p class="text-muted small">No dispatchers online</p>';
    const activeUsersEl = document.getElementById('activeUsers');
    if (activeUsersEl) activeUsersEl.textContent = String(users.length);
}

// ===== Notifications UI =====
async function fetchNotifications() {
    try {
        const token = localStorage.getItem('eventToken') || localStorage.getItem('token');
        const res = await fetch(`${API_BASE_URL}/notifications`, { headers: { 'Authorization': `Bearer ${token}` } });
        const data = await res.json();
        if (res.ok) renderNotifications(data.items || [], data.unread || 0);
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

function setupNotificationsUI() {
    const btn = document.getElementById('notifBtn');
    const dd = document.getElementById('notifDropdown');
    const markAll = document.getElementById('markAllRead');
    if (btn && dd) {
        btn.addEventListener('click', async () => {
            dd.style.display = dd.style.display === 'block' ? 'none' : 'block';
            if (dd.style.display === 'block') await fetchNotifications();
        });
        document.addEventListener('click', (e) => {
            if (!dd.contains(e.target) && e.target !== btn) dd.style.display = 'none';
        });
    }
    if (markAll) {
        markAll.addEventListener('click', async () => {
            const token = localStorage.getItem('eventToken') || localStorage.getItem('token');
            await fetch(`${API_BASE_URL}/notifications/read-all`, { method: 'POST', headers: { 'Authorization': `Bearer ${token}` } });
            await fetchNotifications();
        });
    }
}
socket.on('new_review', (review) => {
  showToast('ðŸ“ New Customer Review', ${review.comment || 'New feedback received'} (â­${review.rating}));
  new Audio('/audio/notification.mp3').play().catch(() => {});
});
