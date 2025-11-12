// Checkout script (ES module)
import CONFIG, { API_BASE_URL } from './config.js';
const PAYSTACK_PUBLIC_KEY = CONFIG.PAYSTACK_PUBLIC_KEY;

// Load cart from localStorage
let cart = JSON.parse(localStorage.getItem('cart')) || [];
// Legacy single-vendor id retained if present
let vendorId = localStorage.getItem('vendorId');

// Auto-fill user info if signed in
document.addEventListener('DOMContentLoaded', () => {
  displayCart();
  autoFillUserInfo();
});

function autoFillUserInfo() {
  const user = JSON.parse(localStorage.getItem('eventUser') || '{}');
  
  if (user.phone) {
    document.getElementById('phone').value = user.phone;
  }
  
  if (user.seatNumber) {
    document.getElementById('seat').value = user.seatNumber;
  }
}

// Display cart summary
function displayCart() {
  const cartSummary = document.getElementById('cart-summary');
  const cartTotal = document.getElementById('cart-total');
  
  if (cart.length === 0) {
    cartSummary.innerHTML = '<p>Your cart is empty</p>';
    cartTotal.textContent = 'â‚¦0';
    return;
  }

  // Group by vendor for multi-vendor orders
  const groups = cart.reduce((acc, it) => {
    const key = it.vendorId || 'unknown';
    if (!acc[key]) acc[key] = { vendorName: it.vendorName || 'Vendor', items: [] };
    acc[key].items.push(it);
    return acc;
  }, {});

  let subtotal = 0;
  let html = '';
  Object.values(groups).forEach(group => {
    html += `<div class="card mb-3"><div class="card-header bg-warning-subtle fw-semibold">${group.vendorName}</div><ul class="list-group list-group-flush">`;
    group.items.forEach(item => {
      const itemTotal = item.price * item.qty;
      subtotal += itemTotal;
      html += `<li class="list-group-item d-flex justify-content-between"><span>${item.name} <span class="text-muted">(x${item.qty})</span></span><strong>â‚¦${itemTotal.toLocaleString()}</strong></li>`;
    });
    html += `</ul></div>`;
  });

  cartSummary.innerHTML = html;
  
  const serviceCharge = 100;
  const total = subtotal + serviceCharge;
  cartTotal.textContent = `â‚¦${subtotal.toLocaleString()}`;
  
  // Update final total if element exists
  const finalTotalElement = document.getElementById('final-total');
  if (finalTotalElement) {
    finalTotalElement.textContent = `â‚¦${total}`;
  }
}

// Pay now with Paystack
async function payNow() {
  const phone = document.getElementById('phone').value;
  const seat = document.getElementById('seat').value;

  if (!phone || !seat) {
    alert('Please enter your phone number and seat/ticket ID');
    return;
  }

  if (cart.length === 0) {
    alert('Your cart is empty');
    return;
  }

  // Prefer logged-in customer; guest allowed if EVENT_GUEST_CHECKOUT
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const token = localStorage.getItem('token');

  // Group items by vendor user id (single order per vendor)
  const groupsMap = cart.reduce((acc, it) => {
    const key = it.vendorUserId || it.vendorId || 'unknown';
    if (!acc[key]) acc[key] = { vendorName: it.vendorName || 'Vendor', items: [] };
    acc[key].items.push({ name: it.name, price: Number(it.price), qty: Number(it.qty) });
    return acc;
  }, {});

  const orders = Object.entries(groupsMap)
    .filter(([k]) => k !== 'unknown')
    .map(([vendorUserId, data]) => ({ vendorUserId, vendorName: data.vendorName, items: data.items }));

  // ðŸ†• Generate orderGroupId if multi-vendor cart
  const isMultiVendor = orders.length > 1;
  const orderGroupId = isMultiVendor ? `OG-${Date.now()}-${Math.random().toString(36).slice(2, 8)}` : null;

  try {
    if (CONFIG.EVENT_DEMO_MODE) {
      // DEMO: create orders without payment
      const res = await fetch(`${API_BASE_URL}/orders/demo-create-batch`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { 'Authorization': `Bearer ${token}` } : {})
        },
        body: JSON.stringify({ 
          phone, 
          seatNumber: seat, 
          orders,
          orderGroupId,  // ðŸ†• Pass orderGroupId for multi-vendor
          isMultiVendor  // ðŸ†• Flag for multi-vendor orders
        })
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Failed to place order');
      localStorage.removeItem('cart');
      const first = (data.created || [])[0];
      if (first && first._id) {
        // Use absolute path from current origin to ensure correct redirect
        const trackUrl = `${window.location.origin}${window.location.pathname.replace(/[^/]*$/, '')}track.html?orderId=${first._id}`;
        window.location.href = trackUrl;
      } else {
        alert('Order placed in demo mode.');
      }
      return;
    }

    // ðŸ†• MULTI-VENDOR SUPPORT: Process all vendors
    if (isMultiVendor) {
      // Show info about multi-vendor order
      const vendorNames = orders.map(o => o.vendorName).join(', ');
      const confirmed = confirm(
        `ðŸ›’ Multi-Vendor Order Detected!\n\n` +
        `You're ordering from ${orders.length} vendors:\n${vendorNames}\n\n` +
        `âœ… All items will be delivered together\n` +
        `âœ… One dispatcher will collect from all vendors\n` +
        `âœ… You'll be notified as each vendor prepares your order\n\n` +
        `Proceed with payment?`
      );
      if (!confirmed) return;
    }

    const res = await fetch(`${API_BASE_URL}/payments/init-multi-vendor-payment`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
      },
      body: JSON.stringify({
        orders: orders.map(o => ({
          vendorId: o.vendorUserId,
          items: o.items
        })),
        orderGroupId,     // ðŸ†• Link all orders together
        isMultiVendor,    // ðŸ†• Flag for backend processing
        deliveryAddress: seat ? `Seat ${seat}` : 'Event Venue',
        deliveryFee: 0,
        notes: phone ? `Phone: ${phone}` : undefined,
        seatNumber: seat,
        guestPhone: phone
      })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to initialize payment');

    // Store orderGroupId for tracking
    if (orderGroupId) {
      localStorage.setItem('lastOrderGroupId', orderGroupId);
    }

    // Redirect to Paystack checkout
    window.location.href = data.authorization_url;
  } catch (err) {
    alert(err.message);
  }
}
// Wire the pay button
window.payNow = payNow;
