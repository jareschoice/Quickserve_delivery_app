// ========================================
// ðŸ”Œ QuickServe Socket.IO Global Handler
// ========================================

import { SOCKET_URL } from './config.js';
import socket from './socket.js';

// Safely initialize Socket.IO
let socket;
try {
  socket = io(SOCKET_URL, {
    transports: ['websocket', 'polling'],
    reconnection: true,
    reconnectionAttempts: 5,
  });
  console.log('âœ… [Socket] Connected to', SOCKET_URL);
} catch (err) {
  console.error('ðŸ’¥ Socket connection error:', err);
}

// ========================================
// ðŸ”” Notification Helper
// ========================================
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
  toast.innerHTML = `
    <div class="d-flex">
      <div class="toast-body">
        <strong>${title}</strong><br>${message}
      </div>
      <button type="button" class="btn-close me-2 m-auto" data-bs-dismiss="toast"></button>
    </div>
  `;
  container.appendChild(toast);

  // Optional notification sound
  try {
    new Audio('/audio/notification.mp3').play().catch(() => {});
  } catch {}
}

// ========================================
// ðŸ“¦ Event Handlers (Universal)
// ========================================
if (socket) {
  // When a new order is placed
  socket.on('order:placed', (data) => {
    console.log('ðŸ†• [Socket] Order placed:', data);
    showToast('New Order', Order #${data?.id || 'N/A'} - â‚¦${data?.amount || ''});
  });

  // When vendor accepts an order
  socket.on('order:accepted', (data) => {
    console.log('ðŸ“¦ [Socket] Order accepted:', data);
    showToast('Order Accepted', Vendor ${data?.vendorName || ''} accepted the order.);
  });

  // When order is ready for pickup
  socket.on('order:ready', (data) => {
    console.log('ðŸ± [Socket] Order ready for pickup:', data);
    showToast('Order Ready', Order #${data?.id || ''} is ready for pickup.);
  });

  // When dispatcher starts delivery
  socket.on('order:in_transit', (data) => {
    console.log('ðŸšš [Socket] Order in transit:', data);
    showToast('Order In Transit', Dispatcher picked up order #${data?.id || ''}.);
  });

  // When order is completed
  // When order is completed / delivered
socket.on('order:delivered', (data) => {
  console.log('âœ… [Socket] Order delivered:', data);
  showToast('Order Delivered', Order #${data?.id || ''} has been delivered.);

  // Play soft delivery sound
  try { new Audio('/audio/success.mp3').play().catch(() => {}); } catch {}

  // Show Review Popup (for consumers)
  if (document.body && !document.getElementById('reviewModal')) {
    const modalHTML = `
      <div class="modal fade" id="reviewModal" tabindex="-1">
        <div class="modal-dialog modal-dialog-centered">
          <div class="modal-content border-0 shadow">
            <div class="modal-header bg-success text-white">
              <h5 class="modal-title">Rate Your Experience</h5>
              <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
              <p class="mb-2">How was your order from <strong>${data?.vendorName || 'the vendor'}</strong>?</p>
              <div id="stars" class="mb-3 text-center">
                ${[1,2,3,4,5].map(i => <i class="bi bi-star fs-3 mx-1" data-val="${i}" style="cursor:pointer;"></i>).join('')}
              </div>
              <textarea id="reviewText" class="form-control mb-3" placeholder="Write your feedback..." rows="3"></textarea>
              <button id="submitReview" class="btn btn-success w-100">Submit Review</button>
            </div>
          </div>
        </div>
      </div>
    `;
    document.body.insertAdjacentHTML('beforeend', modalHTML);

    // Bootstrap modal trigger
    const modal = new bootstrap.Modal(document.getElementById('reviewModal'));
    modal.show();

    // Handle star selection
    let selected = 0;
    document.querySelectorAll('#stars i').forEach(star => {
      star.addEventListener('click', () => {
        selected = parseInt(star.dataset.val);
        document.querySelectorAll('#stars i').forEach(s => s.classList.remove('text-warning', 'bi-star-fill'));
        for (let i = 0; i < selected; i++) {
          document.querySelectorAll('#stars i')[i].classList.add('text-warning', 'bi-star-fill');
        }
      });
    });

    // Handle submit
document.getElementById('submitReview').addEventListener('click', async () => {
  const comment = document.getElementById('reviewText').value.trim();
  if (!selected) return alert('Please select an overall rating.');
  
  try {
    const payload = {
      orderId: data.id,                  // from socket payload
      vendorId: data.vendorId || null,   // vendor ID
      dispatcherId: data.dispatcherId || null,
      overallRating: selected,
      foodRating: selected,              // optional (you can later split UI into separate sliders)
      deliveryRating: selected,
      comment,
    };

    const token = localStorage.getItem('token'); // assuming user is logged in

    const res = await fetch(${API_BASE_URL}/reviews, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ? Bearer ${token} : '',
      },
      body: JSON.stringify(payload)
    });

    const dataRes = await res.json();

    if (res.ok && dataRes.success) {
      modal.hide();
      showToast('âœ… Thank You!', 'Your feedback has been submitted successfully.');
      new Audio('/audio/success.mp3').play().catch(() => {});
    } else {
      console.error('Review submit failed:', dataRes);
      alert(dataRes.error || 'Error submitting review');
    }
  } catch (err) {
    console.error('ðŸ’¥ Review submit error:', err);
    alert('Something went wrong. Please try again later.');
  }
});

  // When wallet updates
  socket.on('wallet:update', (data) => {
    console.log('ðŸ’° [Socket] Wallet updated:', data);
    showToast('Wallet Update', New balance: â‚¦${data?.balance?.toFixed(2) || 0});
    const walletElement = document.getElementById('walletBalance');
    if (walletElement && data?.balance !== undefined) {
      walletElement.textContent = data.balance.toFixed(2);
    }
  });

  // Admin-side â€” live vendor/dispatcher activity
  socket.on('system:online_users', (list) => {
    console.log('ðŸŸ¢ [Socket] Active users updated:', list);
  });
}

// ========================================
// ðŸš€ Export Socket for other modules
// ========================================
export default socket;
