// AutofestXTradeExpo - Dispatcher Dashboard Script
import socket from './socket.js';

// Check authentication (accept both token/eventToken and user/eventUser formats)
const token = localStorage.getItem('token') || localStorage.getItem('eventToken');
let userRole = localStorage.getItem('userRole');
if (!userRole) {
    try {
        const parsed = JSON.parse(localStorage.getItem('user') || localStorage.getItem('eventUser') || 'null');
        userRole = parsed?.role;
    } catch (e) {}
}

if (!token || userRole !== 'dispatcher') {
    window.location.href = 'login.html';
}

// Use imported socket (socket is a safe proxy even if real socket not available)

// Small notification helpers (inline to avoid converting this file to ESM)
function playNotificationSound() {
    try {
        const _audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBDGJ0fPTgjMGHm7A7+OZUQ0PVKzo7adXEwlEmuTxwmwhBDGH0PPTgjQGHm6/7+OZTQ0PVK3o7KdXEwlFmeXwwmwhBDKI0PPTgjQGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OYTw0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm6/7+OZTQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7A==' );
        _audio.currentTime = 0;
        _audio.play().catch(() => {});
    } catch {}
}

function showToast(message, type = 'info') {
    try {
        const existing = document.getElementById('toastContainer');
        const container = existing || (function(){ const c = document.createElement('div'); c.id='toastContainer'; c.className='toast-container position-fixed top-0 end-0 p-3'; c.style.zIndex='9999'; document.body.appendChild(c); return c; })();
        const toast = document.createElement('div');
        toast.className = `toast align-items-center text-white bg-${type} border-0`;
        toast.setAttribute('role','alert');
        toast.innerHTML = `<div class="d-flex"><div class="toast-body">${message}</div><button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button></div>`;
        container.appendChild(toast);
        const bsToast = new bootstrap.Toast(toast); bsToast.show(); setTimeout(()=>toast.remove(),5000);
    } catch (e) {}
}

// Safe JSON parser used across dispatcher pages
async function safeParseJson(response) {
    try {
        const contentType = response.headers.get('content-type') || '';
        if (contentType.includes('application/json')) return await response.json();
        const text = await response.text();
        try { return JSON.parse(text); } catch { console.warn('safeParseJson: non-JSON response', text && text.slice ? text.slice(0,120) : text); return null; }
    } catch (e) { console.error('safeParseJson error', e); return null; }
}

socket.on('connect', () => {
    console.log('âœ… Socket connected:', socket.id);
    socket.emit('join_dispatcher_room');
});

socket.on('disconnect', () => {
    console.log('âŒ Socket disconnected');
});

// React to user online/offline events to update dispatcher availability indicator
socket.on('user:online', (p) => {
    try {
        const dot = document.getElementById('dispatcherStatusDot');
        if (dot && p?.userId && p.userId === (window.currentDispatcherId || '')) {
            dot.className = 'status-indicator online';
            dot.title = 'Online';
        }
    } catch (e) {}
});
socket.on('user:offline', (p) => {
    try {
        const dot = document.getElementById('dispatcherStatusDot');
        if (dot && p?.userId && p.userId === (window.currentDispatcherId || '')) {
            dot.className = 'status-indicator offline';
            dot.title = 'Offline';
        }
    } catch (e) {}
});

// Load dispatcher profile
async function loadDispatcherProfile() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/profile`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            const data = await safeParseJson(response);
            const dispatcher = data?.dispatcher;

            // Populate welcome banner
            document.getElementById('welcomeName').textContent = dispatcher.name;
            document.getElementById('welcomeDispatcherId').textContent = dispatcher.dispatcherId;
            // store current dispatcher id globally for socket matching
            window.currentDispatcherId = dispatcher._id || dispatcher.dispatcherId || '';
            // update status dot
            const dot = document.getElementById('dispatcherStatusDot');
            if (dot) {
                dot.className = `status-indicator ${dispatcher.isAvailable ? 'online' : 'offline'}`;
                dot.title = dispatcher.isAvailable ? 'Active' : 'Inactive';
            }

            // Populate profile dropdown
            document.getElementById('profileDispatcherId').textContent = dispatcher.dispatcherId;
            document.getElementById('profileName').textContent = dispatcher.name;
            document.getElementById('profilePhone').textContent = dispatcher.phone;

            // Set availability toggle
            const toggle = document.getElementById('availabilityToggle');
            toggle.checked = dispatcher.isAvailable;
            updateAvailabilityLabel(dispatcher.isAvailable);

        } else {
            console.error('Failed to load profile');
            showAlert('Failed to load profile', 'danger');
        }
    } catch (error) {
        console.error('Error loading profile:', error);
        showAlert('Error loading profile', 'danger');
    }
}

// Load wallet data
async function loadWallet() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/wallet`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            const data = await safeParseJson(response);
            const wallet = data?.wallet;

            document.getElementById('totalEarnings').textContent = `â‚¦${wallet.totalEarnings.toLocaleString()}`;
            document.getElementById('completedCount').textContent = wallet.completedDeliveries;

            // Update active status
            if (wallet.hasActiveDelivery) {
                document.getElementById('activeStatus').textContent = 'In Progress';
            } else {
                document.getElementById('activeStatus').textContent = 'None';
            }

        } else {
            console.error('Failed to load wallet');
        }
    } catch (error) {
        console.error('Error loading wallet:', error);
    }
}

// Load active delivery
async function loadActiveDelivery() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/active-delivery`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            const data = await safeParseJson(response);
            
            if (data && data.order) {
                displayActiveDelivery(data.order);
            } else {
                document.getElementById('activeDeliveryContainer').innerHTML = `
                    <div class="text-center py-5 text-muted">
                        <i class="bi bi-bicycle fs-1"></i>
                        <p class="mt-3">No active delivery. Enable availability to receive order notifications.</p>
                    </div>
                `;
            }
        }
    } catch (error) {
        console.error('Error loading active delivery:', error);
    }
}

// Display active delivery
function displayActiveDelivery(order) {
    const container = document.getElementById('activeDeliveryContainer');
    
    const statusText = order.status === 'assigned' ? 'Pickup from Vendor' : 'Deliver to Customer';
    const actionBtn = order.status === 'assigned' 
        ? `<button class="btn btn-success w-100" onclick="markInTransit('${order._id}')">
             <i class="bi bi-bicycle me-2"></i>Start Delivery
           </button>`
        : `<button class="btn btn-primary w-100" onclick="scanQR('${order._id}')">
             <i class="bi bi-qr-code me-2"></i>Scan QR Code
           </button>`;

    container.innerHTML = `
        <div class="delivery-card">
            <div class="d-flex justify-content-between align-items-center mb-3">
                <h5 class="mb-0">Order #${order._id.slice(-6).toUpperCase()}</h5>
                <span class="status-badge status-active">${statusText}</span>
            </div>
            
            <div class="row mb-3">
                <div class="col-md-6">
                    <h6><i class="bi bi-shop me-2"></i>Vendor</h6>
                    <p class="mb-1">${order.vendor?.businessName || 'Vendor'}</p>
                    <p class="text-muted small">${order.vendor?.address || 'Address not available'}</p>
                </div>
                <div class="col-md-6">
                    <h6><i class="bi bi-person me-2"></i>Customer</h6>
                    <p class="mb-1">${order.customer?.name || 'Customer'}</p>
                    <p class="text-muted small">${order.deliveryAddress || 'Address not available'}</p>
                </div>
            </div>

            <div class="border-top pt-3">
                <div class="d-flex justify-content-between mb-2">
                    <span>Order Total:</span>
                    <strong>â‚¦${order.totalAmount.toLocaleString()}</strong>
                </div>
                <div class="d-flex justify-content-between mb-3 text-success">
                    <span>Your Earning:</span>
                    <strong>â‚¦70</strong>
                </div>
                ${actionBtn}
            </div>
        </div>
    `;
}

// Load delivery history
async function loadHistory() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/history`, {
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            const data = await safeParseJson(response);
            displayHistory(data?.deliveries || []);
        }
    } catch (error) {
        console.error('Error loading history:', error);
    }
}

// Display delivery history
function displayHistory(deliveries) {
    const tbody = document.getElementById('historyTableBody');
    
    if (deliveries.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="7" class="text-center text-muted py-4">
                    No delivery history yet
                </td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = deliveries.map(order => `
        <tr>
            <td>${order._id.slice(-6).toUpperCase()}</td>
            <td>${order.vendor?.businessName || 'N/A'}</td>
            <td>${order.customer?.name || 'N/A'}</td>
            <td>â‚¦${order.totalAmount.toLocaleString()}</td>
            <td class="text-success">â‚¦70</td>
            <td>${new Date(order.deliveredAt).toLocaleDateString()}</td>
            <td>
                ${order.deliveryRating ? 
                    `<span class="text-warning">${'â˜…'.repeat(order.deliveryRating)}${'â˜†'.repeat(5 - order.deliveryRating)}</span>` 
                    : '<span class="text-muted">No rating</span>'}
            </td>
        </tr>
    `).join('');
}

// Toggle availability
async function toggleAvailability() {
    const toggle = document.getElementById('availabilityToggle');
    const isAvailable = toggle.checked;

    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/availability`, {
            method: 'PUT',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ isAvailable })
        });

        if (response.ok) {
            updateAvailabilityLabel(isAvailable);
            
            if (isAvailable) {
                showAlert('You are now available for deliveries', 'success');
                socket.emit('dispatcher_available');
            } else {
                showAlert('You are now unavailable', 'info');
                socket.emit('dispatcher_unavailable');
            }
        } else {
            toggle.checked = !isAvailable;
            showAlert('Failed to update availability', 'danger');
        }
    } catch (error) {
        console.error('Error toggling availability:', error);
        toggle.checked = !isAvailable;
        showAlert('Error updating availability', 'danger');
    }
}

// Update availability label
function updateAvailabilityLabel(isAvailable) {
    const label = document.getElementById('availabilityLabel');
    label.textContent = isAvailable ? 'Available' : 'Unavailable';
}

// Accept delivery
async function acceptDelivery(orderId) {
    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/accept/${orderId}`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            showAlert('Delivery accepted!', 'success');
            loadActiveDelivery();
            loadWallet();
        } else {
            const errObj = await safeParseJson(response);
            showAlert(errObj?.message || 'Failed to accept delivery', 'danger');
        }
    } catch (error) {
        console.error('Error accepting delivery:', error);
        showAlert('Error accepting delivery', 'danger');
    }
}

// Mark order as in transit
async function markInTransit(orderId) {
    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/in-transit/${orderId}`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (response.ok) {
            showAlert('Order marked as in transit', 'success');
            loadActiveDelivery();
            startGPSTracking();
        } else {
            const errObj = await safeParseJson(response);
            showAlert(errObj?.message || 'Failed to update status', 'danger');
        }
    } catch (error) {
        console.error('Error marking in transit:', error);
        showAlert('Error updating status', 'danger');
    }
}

// Scan QR code (placeholder for QR scanner integration)
function scanQR(orderId) {
    const qrCode = prompt('Enter QR code from customer:');
    if (qrCode && qrCode.includes(orderId)) {
        confirmDelivery(orderId, qrCode);
    } else {
        showAlert('Invalid QR code', 'danger');
    }
}

// Confirm delivery
async function confirmDelivery(orderId, qrCode) {
    try {
        const response = await fetch(`${API_BASE_URL}/api/dispatchers/confirm-delivery`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ orderId, qrCode })
        });

        if (response.ok) {
            showAlert('Delivery confirmed! â‚¦70 credited to your wallet.', 'success');
            loadActiveDelivery();
            loadWallet();
            loadHistory();
            stopGPSTracking();
        } else {
            const error = await safeParseJson(response);
            showAlert(error?.message || 'Failed to confirm delivery', 'danger');
        }
    } catch (error) {
        console.error('Error confirming delivery:', error);
        showAlert('Error confirming delivery', 'danger');
    }
}

// GPS Tracking
let gpsInterval;

function startGPSTracking() {
    if (!navigator.geolocation) {
        console.log('Geolocation not supported');
        return;
    }

    gpsInterval = setInterval(() => {
        navigator.geolocation.getCurrentPosition(
            (position) => {
                const location = {
                    latitude: position.coords.latitude,
                    longitude: position.coords.longitude
                };
                
                // Send location to server
                fetch(`${API_BASE_URL}/api/dispatchers/location`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`,
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify(location)
                }).catch(err => console.error('GPS update failed:', err));
                
                // Emit via socket for real-time tracking
                socket.emit('dispatcher_location_update', location);
            },
            (error) => {
                console.error('GPS error:', error);
            },
            {
                enableHighAccuracy: true,
                maximumAge: 5000,
                timeout: 10000
            }
        );
    }, 10000); // Update every 10 seconds
}

function stopGPSTracking() {
    if (gpsInterval) {
        clearInterval(gpsInterval);
        gpsInterval = null;
    }
}

// Socket.IO listeners
socket.on('new_delivery_request', (data) => {
    showNotification('New Delivery Available!', data.message);
    playNotificationSound();
});

socket.on('delivery_cancelled', (data) => {
    showAlert('Delivery was cancelled', 'warning');
    loadActiveDelivery();
});

// Generic order notifications from server
socket.on('order:notification', (payload) => {
    try {
        console.log('Dispatcher received order:notification', payload);
        if (payload && payload.orderId) {
            showAlert(payload.message || 'Order update', 'info');
            playNotificationSound();
            // refresh active delivery if it matches
            loadActiveDelivery();
        }
    } catch (e) { console.error(e); }
});

// New namespaced events (keeps compatibility with older event names)
socket.on('order:dispatch_requested', (payload) => {
    try {
        console.log('order:dispatch_requested', payload);
        showNotification('Pickup Requested', payload.message || 'Pickup requested by vendor');
        playNotificationSound();
        // optionally refresh available deliveries
        loadAvailableDeliveries && loadAvailableDeliveries();
    } catch (e) { console.error(e); }
});

socket.on('order:assigned', (payload) => {
    try {
        console.log('order:assigned', payload);
        showAlert(payload.message || 'You have been assigned to a delivery', 'info');
        playNotificationSound();
        loadActiveDelivery();
    } catch (e) { console.error(e); }
});

socket.on('order:in_transit', (payload) => {
    try {
        console.log('order:in_transit', payload);
        showAlert(payload.message || 'Delivery is in transit', 'info');
        playNotificationSound();
        loadActiveDelivery();
    } catch (e) { console.error(e); }
});

socket.on('order:delivered', (payload) => {
    try {
        console.log('order:delivered', payload);
        showAlert(payload.message || 'Delivery confirmed', 'success');
        playNotificationSound();
        loadActiveDelivery();
    } catch (e) { console.error(e); }
});

// Profile dropdown
function setupProfileDropdown() {
    const profileBtn = document.getElementById('profileBtn');
    const profileMenu = document.getElementById('profileMenu');

    profileBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        profileMenu.classList.toggle('show');
    });

    document.addEventListener('click', () => {
        profileMenu.classList.remove('show');
    });
}

// Logout
document.getElementById('logoutBtn').addEventListener('click', () => {
    if (confirm('Are you sure you want to logout?')) {
        stopGPSTracking();
        localStorage.removeItem('token');
        localStorage.removeItem('userRole');
        window.location.href = 'login.html';
    }
});

// Availability toggle
document.getElementById('availabilityToggle').addEventListener('change', toggleAvailability);

// Notification sound
function playNotificationSound() {
    const audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBCty0fPTgjMGHm7A7+OZRA');
    audio.play().catch(() => console.log('Could not play sound'));
}

// Show notification
function showNotification(title, message) {
    if ('Notification' in window && Notification.permission === 'granted') {
        new Notification(title, { body: message });
    }
}

// Request notification permission
if ('Notification' in window && Notification.permission === 'default') {
    Notification.requestPermission();
}

// Show alert
function showAlert(message, type) {
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${type} alert-dismissible fade show position-fixed top-0 start-50 translate-middle-x mt-3`;
    alertDiv.style.zIndex = '9999';
    alertDiv.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    document.body.appendChild(alertDiv);
    
    setTimeout(() => alertDiv.remove(), 5000);
}

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    setupProfileDropdown();
    loadDispatcherProfile();
    loadWallet();
    loadActiveDelivery();
    loadHistory();
});
