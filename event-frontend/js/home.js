// ===============================
// ðŸ  home.js - QuickServe Home Page Functionality
// ===============================

// ===============================
// 🌍 QuickServe Home.js (Auto-synced)
// ===============================
import { BACKEND_HTTP, API_BASE_URL, AUTH_API_URL, SOCKET_URL } from '/event-frontend/js/env-config.js';
import socket from '/event-frontend/js/socket-client.js';
import { CATEGORY_OPTIONS } from '/event-frontend/js/config.js';

// Global data caches
let allVendors = [];
let allProducts = [];
let cartItems = JSON.parse(localStorage.getItem('cart')) || [];
let currentCategory = 'all';

// Initialize on page load
// ===== START PATCH: Safe async init =====
document.addEventListener('DOMContentLoaded', async () => {
  console.log('🚀 QuickServe Home initializing...');

  try {
    await Promise.all([loadVendors(), loadProducts()]);
    updateCartBadge();
    await checkUserProfile();
    initializeEventListeners();
    initPromoSlider();
    detectCurrentLocation();
    setupZaddyImage();
    console.log('✅ Home page fully loaded.');
  } catch (e) {
    console.error('❌ Error during page init:', e);
  }
});
// ===== END PATCH =====

// ===============================
// 🧑‍🤝‍🧑 Check and display user profile initials
// ===============================
async function checkUserProfile() {
  const profileAvatar = document.getElementById('profileAvatar');
  const token = localStorage.getItem('eventToken');

  if (token) {
    try {
      const response = await fetch(`${API_BASE_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (response.ok) {
        const data = await response.json();
        const initials = data.user?.name
          ? data.user.name.split(' ').map((n) => n[0]).join('').toUpperCase()
          : 'U';
        profileAvatar.textContent = initials;
        return;
      }
    } catch (error) {
      console.error('âš  Auto-login error:', error);
    }
  }

  const user = JSON.parse(localStorage.getItem('eventUser') || '{}');
  if (user.name) {
    const initials = user.name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase();
    profileAvatar.textContent = initials;
  }
}

// ===============================
// ðŸª Load vendors from backend
// ===============================
async function loadVendors() {
  try {
    const response = await fetch(`${API_BASE_URL}/vendors`);
    const data = await response.json();
    const vendors = data.vendors || data.items || data || [];

    if (Array.isArray(vendors) && vendors.length > 0) {
      allVendors = vendors;
      updateSectionDisplays();
      console.log('✅ Loaded ' + vendors.length + ' vendors');
    } else {
      console.warn('âš  No vendors found:', data);
      document.getElementById('exploreVendors').innerHTML =
        '<p style="padding: 0 16px; color: #666;">No vendors available</p>';
      document.getElementById('featuredVendors').innerHTML =
        '<p style="padding: 0 16px; color: #666;">No featured vendors</p>';
    }
  } catch (error) {
    console.error('âŒ Error loading vendors:', error);
  }
}

// ===============================
// ðŸ² Load and render products
// ===============================
async function loadProducts() {
  try {
    const resp = await fetch(`${API_BASE_URL}/products`);
    const data = await resp.json();
    const products = data.items || data.products || data || [];

    if (Array.isArray(products) && products.length > 0) {
      allProducts = products;
      updateSectionDisplays();
      const key = normalizeCategory(currentCategory);
      const prod =
        key && key !== 'all'
          ? allProducts.filter((p) => normalizeCategory(p.category) === key)
          : allProducts;
      renderProductFeed(prod);
      console.log('✅ Loaded ' + products.length + ' products');
    } else {
      console.warn('âš  No products found:', data);
    }
  } catch (e) {
    console.error('âŒ Error loading products:', e);
  }
}

// ===============================
// ðŸŽ¯ Normalize & Filter Categories
// ===============================
function normalizeCategory(key) {
  if (!key) return '';
  const k = String(key).trim().toLowerCase();
  if (['nigerian', 'localfood', 'local food'].includes(k)) return 'Restaurant';
  return k.charAt(0).toUpperCase() + k.slice(1);
}

function filterByCategory(category) {
  currentCategory = category;

  document.querySelectorAll('.category-card').forEach((card) => {
    card.classList.remove('active');
    if (card.dataset.category === category) card.classList.add('active');
  });

  const key = normalizeCategory(category);
  const filtered =
    key === 'all'
      ? allVendors
      : allVendors.filter((v) => normalizeCategory(v.category) === key);

  displayExploreVendors(filtered);
  displayFeaturedVendors(filtered.slice(0, 8));

  if (Array.isArray(allProducts) && allProducts.length) {
    const prod =
      key === 'all'
        ? allProducts
        : allProducts.filter((p) => normalizeCategory(p.category) === key);
    renderProductFeed(prod);
  }
}

// ===============================
// ðŸ§­ Vendor Display Logic
// ===============================
function displayExploreVendors(vendors) {
  const container = document.getElementById('exploreVendors');
  if (!vendors.length) {
    container.innerHTML =
      '<p style="padding: 0 16px; color: #666;">No vendors found</p>';
    return;
  }
  container.innerHTML = vendors
    .map(
      (v) => `
      <div class="vendor-circle" onclick="viewVendor('${v._id}')">
        <div class="vendor-avatar">${
          (v.businessName || v.storeName || 'V')[0].toUpperCase()
        }</div>
        <div class="vendor-name">${
          v.businessName || v.storeName || 'Vendor'
        }</div>
      </div>`
    )
    .join('');
}

function displayFeaturedVendors(vendors) {
  const container = document.getElementById('featuredVendors');
  if (!vendors.length) {
    container.innerHTML =
      '<p style="padding: 0 16px; color: #666;">No featured vendors</p>';
    return;
  }
  const emojis = ['ðŸ•', 'ðŸ”', 'ðŸœ', 'ðŸ±', 'ðŸŒ®', 'ðŸ£', 'ðŸ¥˜', 'ðŸ›'];
  container.innerHTML = vendors
    .map(
      (v, i) => `
      <div class="featured-card" onclick="viewVendor('${v._id}')">
        <div class="featured-image">${emojis[i % emojis.length]}</div>
        <div class="featured-content">
          <div class="featured-name">${
            v.businessName || v.storeName || 'Vendor'
          }</div>
          <div class="featured-price">From â‚¦${v.minimumOrder || 1000}</div>
        </div>
      </div>`
    )
    .join('');
}

// ===============================
// ðŸ§¾ Product Feed Renderer
// ===============================
function renderProductFeed(products) {
  const feed = document.getElementById('productFeed');
  if (!feed) return;

  if (!products.length) {
    feed.innerHTML =
      '<p class="text-muted" style="padding:0 16px">No products yet</p>';
    return;
  }

  const foodCourt = products.filter(
    (p) => Array.isArray(p.tags) && p.tags.includes('FoodCourt')
  );
  const list = foodCourt.length ? foodCourt : products;

  feed.innerHTML = `
    <div class="row g-3" style="padding: 0 12px;">
      ${list
        .slice(0, 12)
        .map(
          (p) => `
        <div class="col-6 col-md-3">
          <a class="text-decoration-none" href="vendor.html?id=${p.vendorId}">
            <div class="card h-100">
              ${
                p.imageUrl || p.image
                  ? `<img src="${p.imageUrl || (FILE_BASE_URL ? FILE_BASE_URL + p.image : p.image)}" class="card-img-top" style="height:140px;object-fit:cover" />`
                  : `<div class="bg-light d-flex align-items-center justify-content-center" style="height:140px"><i class="bi bi-image"></i></div>`
              }
              <div class="card-body p-2">
                <div class="fw-semibold small">${p.name}</div>
                <div class="text-primary fw-bold">â‚¦${Number(
                  p.price
                ).toLocaleString()}</div>
                <div class="text-muted small">${p.quantity || 1} ${
            p.unit || 'pcs'
          } ${p.prepDurationMins ? `• ${p.prepDurationMins}m` : ''}</div>
              </div>
            </div>
          </a>
        </div>`
        )
        .join('')}
    </div>`;
}

// ===============================
// ðŸš€ Navigation & Helpers
// ===============================
function viewVendor(vendorId) {
  window.location.href = `vendor.html?id=${vendorId}`;
}

function updateCartBadge() {
  const count = cartItems.reduce((sum, i) => sum + i.quantity, 0);
  ['cartCount', 'navCartCount'].forEach((id) => {
    const el = document.getElementById(id);
    if (el) {
      if (count > 0) {
        el.textContent = count;
        el.style.display = 'block';
      } else {
        el.style.display = 'none';
      }
    }
  });
}

function initializeEventListeners() {
  const btn = document.getElementById('locationBtn');
  if (btn) btn.addEventListener('click', detectCurrentLocation);

  document.querySelectorAll('.category-card').forEach((card) => {
    card.addEventListener('click', () => {
      filterByCategory(card.dataset.category);
    });
  });

  window.addEventListener('storage', (e) => {
    if (e.key === 'cart') {
      cartItems = JSON.parse(e.newValue || '[]');
      updateCartBadge();
    }
  });
}

window.viewVendor = viewVendor;
window.filterByCategory = filterByCategory;
window.selectLocation = () => {};

// ===============================
// ðŸŒ Location Detection
// ===============================
function detectCurrentLocation() {
  const el = document.getElementById('currentLocation');
  if (!('geolocation' in navigator)) return ipLocationFallback(el);

  el.textContent = 'Detectingâ€¦';
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const { latitude, longitude } = pos.coords;
      const pretty = `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
      el.textContent = pretty;
      localStorage.setItem('userLocation', JSON.stringify({ latitude, longitude }));
    },
    () => ipLocationFallback(el),
    { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 }
  );
}

async function ipLocationFallback(el) {
  try {
    el.textContent = 'Detecting via networkâ€¦';
    const resp = await fetch('https://ipapi.co/json/');
    const locationData = await resp.json();
    const label = `${locationData.city || ''}, ${locationData.region || locationData.country_name || ''}`.trim();
    el.textContent = label || 'Current Location';
    localStorage.setItem('userLocation', JSON.stringify({ lat: locationData.latitude, lng: locationData.longitude }));
  } catch {
    el.textContent = 'Current Location';
  }
}

// Recompute Explore/Featured vendors based on product tags
function updateSectionDisplays() {
  try {
    const byVendor = new Map(); // vendorId -> { hasExplore, hasFeatured }

    (allProducts || []).forEach(p => {
      const vId = String(p.vendorId?._id || p.vendorId || '');
      if (!vId) return;
      const tags = Array.isArray(p.tags)
        ? p.tags.map(t => String(t).toLowerCase())
        : [];
      if (!byVendor.has(vId))
        byVendor.set(vId, { hasExplore: false, hasFeatured: false });

      const row = byVendor.get(vId);
      if (tags.includes('explore') || tags.includes('popular'))
        row.hasExplore = true;
      if (tags.includes('featured') || tags.includes('popular'))
        row.hasFeatured = true;
    });

    const exploreVendorIds = Array.from(byVendor.entries())
      .filter(([_, v]) => v.hasExplore)
      .map(([id]) => id);

    const featuredVendorIds = Array.from(byVendor.entries())
      .filter(([_, v]) => v.hasFeatured)
      .map(([id]) => id);

    const explore =
      exploreVendorIds.length > 0
        ? allVendors.filter(v => exploreVendorIds.includes(String(v._id)))
        : allVendors;

    const featured =
      featuredVendorIds.length > 0
        ? allVendors.filter(v => featuredVendorIds.includes(String(v._id)))
        : allVendors.slice(0, 8);

    displayExploreVendors(explore);
    displayFeaturedVendors(featured);
  } catch (e) {
    console.error('updateSectionDisplays error:', e);
  }
}
// ===============================
// 🏷 Promo Banner + Zaddy’s Creamery Auto-Link
// ===============================
let promoIndex = 0;
let zaddyVendorId = null;

function setPromoActive(idx) {
  const banners = document.querySelectorAll('.promo-banner');
  banners.forEach((el, i) => el.classList.toggle('active', i === idx));

  if (idx === 1) {
    const el = document.getElementById('promoZaddy');
    if (el) {
      el.classList.remove('pulse');
      el.offsetWidth;
      el.classList.add('pulse');
    }
  }
}

function initPromoSlider() {
  const trySetVendor = () => {
    if (allVendors.length) {
      const zaddy = allVendors.find((v) =>
        /zaddy/i.test(v.businessName || v.storeName || '')
      );
      if (zaddy) zaddyVendorId = zaddy._id;
    }
  };
  trySetVendor();
  setTimeout(trySetVendor, 600);

  setPromoActive(0);
  const cycle = () => {
    setTimeout(() => {
      promoIndex = promoIndex === 0 ? 1 : 0;
      setPromoActive(promoIndex);
      cycle();
    }, promoIndex === 0 ? 3000 : 9000);
  };
  cycle();

  const zaddy = document.getElementById('promoZaddy');
  if (zaddy)
    zaddy.addEventListener('click', () => {
      if (zaddyVendorId)
        window.location.href = `vendor.html?id=${zaddyVendorId}`;
    });
}

function setupZaddyImage() {
  const container = document.getElementById('promoZaddy');
  if (!container) return;
  const img = container.querySelector('img');
  if (!img) return;

  const candidates = [
    'images/zaddys-creamery.png',
    'images/Zaddys-Creamery.png',
    'images/zaddys-creamery.jpg',
    'images/Zaddys-Creamery.jpg',
  ];
  const fallback = 'https://images.unsplash.com/photo-1490474418585-ba9bad8fd0ea?w=300';
  const bust = `?v=${Date.now()}`;
  let i = 0;
  const tryNext = () => {
    if (i >= candidates.length) return (img.src = fallback);
    const url = candidates[i] + bust;
    const test = new Image();
    test.onload = () => (img.src = url);
    test.onerror = () => {
      i += 1;
      tryNext();
    };
    test.src = url;
  };
  tryNext();
}

console.log('âœ… QuickServe Home.js initialized');
