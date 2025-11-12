// Vendor page (ES module)
import { API_BASE_URL, FILE_BASE_URL } from './config.js';
import socket from './socket.js';

// Get vendor ID from URL (we use ?id= in home.js)
const urlParams = new URLSearchParams(window.location.search);
const vendorId = urlParams.get('id');
let vendorUserId = null;
let vendorName = 'Vendor Menu';

// Cart storage
let cart = JSON.parse(localStorage.getItem('cart')) || [];

// Load vendor name from public vendors list
async function setVendorName() {
  try {
    const r = await fetch(`${API_BASE_URL}/vendors`);
    const data = await r.json();
    const v = (data.vendors || []).find(x => String(x._id) === String(vendorId));
    if (v) {
      vendorUserId = v.userId || null;
      vendorName = v.businessName || v.storeName || 'Vendor Menu';
      document.getElementById('vendor-name').textContent = vendorName;
    }
  } catch {}
}

// Load vendor products (public endpoint)
async function loadVendorProducts() {
  const list = document.getElementById('product-list');
  try {
    if (!vendorId) {
      list.innerHTML = '<div class="col-12"><div class="alert alert-danger">No vendor selected</div></div>';
      return;
    }
  const response = await fetch(`${API_BASE_URL}/products?vendorId=${vendorId}`);
  const data = await response.json();
  // Support multiple response shapes: { items: [...] }, { products: [...] }, array, or wrapped object
  const items = data.items || data.products || data || [];
  displayProducts(Array.isArray(items) ? items : []);
  } catch (error) {
    console.error('Error loading products:', error);
    list.innerHTML = '<div class="col-12"><div class="alert alert-danger">Failed to load products</div></div>';
  }
}

// Display products
function displayProducts(products) {
  const productList = document.getElementById('product-list');
  if (!products.length) {
    productList.innerHTML = '<div class="col-12"><div class="alert alert-warning">No products yet</div></div>';
    return;
  }
  productList.innerHTML = products.map(product => `
      <div class="col-md-4 col-sm-6 mb-4">
        <div class="card h-100 product-card">
          ${product.imageUrl || product.image ? `<img src="${product.imageUrl || (FILE_BASE_URL + product.image)}" class="product-img" alt="${product.name}">` : `
            <div class="bg-light d-flex align-items-center justify-content-center" style="height:180px"><i class="bi bi-image"></i></div>`}
          <div class="card-body">
            <h5 class="product-name">${product.name}</h5>
            <p class="text-muted small">${product.description || ''}</p>
            <div class="d-flex justify-content-between align-items-center mb-2">
              <div class="product-price">â‚¦${Number(product.price).toLocaleString()}</div>
              <div class="input-group input-group-sm" style="width:120px">
                <button class="btn btn-outline-secondary btn-qty" type="button" data-action="minus" data-id="${product._id}">-</button>
                <input type="text" class="form-control text-center qty-field" value="1" data-id="${product._id}">
                <button class="btn btn-outline-secondary btn-qty" type="button" data-action="plus" data-id="${product._id}">+</button>
              </div>
            </div>
            <div class="d-flex justify-content-end">
              <button class="btn btn-sm btn-add-cart" type="button" data-id="${product._id}" data-name="${(product.name || '').replace(/&/g,'&amp;').replace(/\"/g,'&quot;').replace(/</g,'&lt;')}" data-price="${Number(product.price)}">Add</button>
            </div>
          </div>
        </div>
      </div>
  `).join('');

  // Qty increment/decrement
  document.querySelectorAll('.btn-qty').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-id');
      const action = btn.getAttribute('data-action');
      const input = document.querySelector(`.qty-field[data-id="${id}"]`);
      let val = parseInt(input.value || '1', 10) || 1;
      val = action === 'plus' ? val + 1 : Math.max(1, val - 1);
      input.value = String(val);
    });
  });

  // Attach click handlers after render (more reliable than inline in module scope)
  document.querySelectorAll('.btn-add-cart').forEach(btn => {
    btn.addEventListener('click', () => {
      const id = btn.getAttribute('data-id');
      const name = btn.getAttribute('data-name');
      const price = Number(btn.getAttribute('data-price')) || 0;
      const qtyInput = document.querySelector(`.qty-field[data-id="${id}"]`);
      const qty = Math.max(1, parseInt(qtyInput?.value || '1', 10) || 1);
      window.addToCart(id, name, price, qty);
      // Tiny feedback
      btn.disabled = true;
      const prev = btn.textContent;
      btn.textContent = 'Added';
      setTimeout(() => { btn.disabled = false; btn.textContent = prev; }, 600);
    });
  });
}

// Add item to cart
window.addToCart = function (productId, name, price, qty = 1) {
  const existingItem = cart.find(item => item.productId === productId);
  if (existingItem) {
    existingItem.qty += qty;
  } else {
    cart.push({ productId, name, price, qty, vendorId, vendorUserId, vendorName });
  }
  localStorage.setItem('cart', JSON.stringify(cart));
  localStorage.setItem('vendorId', vendorId);
  const badge = document.getElementById('cartBadge');
  if (badge) badge.textContent = cart.reduce((s, i) => s + i.qty, 0);
};

// Init
document.addEventListener('DOMContentLoaded', async () => {
  await setVendorName();
  await loadVendorProducts();
  // Init badges
  const totalQty = cart.reduce((s, i) => s + i.qty, 0);
  const badge = document.getElementById('cartBadge');
  const badgeNav = document.getElementById('cartBadgeNav');
  if (badge) badge.textContent = totalQty;
  if (badgeNav) badgeNav.textContent = totalQty;
});
