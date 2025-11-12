// ===== public-banner.js (QuickServe refined) =====
// Automatically runs for guest users, shows login banner,
// and loads promotional banners dynamically (e.g., Zaddy’s Creamery).

import { API_BASE_URL, FILE_BASE_URL } from '/event-frontend/js/env-config.js';

document.addEventListener('DOMContentLoaded', async () => {
  try {
    const token = localStorage.getItem('eventToken') || localStorage.getItem('token');
    if (token) return; // Skip banner for logged-in users

    // Avoid duplicate banners
    if (document.getElementById('public-login-banner')) return;

    // 🔸 Create login reminder banner
    const bar = document.createElement('div');
    bar.id = 'public-login-banner';
    bar.setAttribute('role', 'region');
    bar.setAttribute('aria-label', 'Login prompt');
    bar.style.cssText = `
      position: fixed;
      top: 0; left: 0; right: 0;
      z-index: 2000;
      padding: 10px 14px;
      display: flex; gap: 12px;
      align-items: center; justify-content: center;
      background: linear-gradient(135deg, #FF6B00, #FFD700);
      color: #fff; font-weight: 600;
      box-shadow: 0 2px 10px rgba(0,0,0,0.2);
    `;

    const msg = document.createElement('div');
    msg.textContent = "You're browsing as a guest. Login for faster checkout and order tracking.";

    const btn = document.createElement('button');
    btn.textContent = 'Login';
    btn.style.cssText = `
      background:#1a1a1a; border:none;
      color:#fff; padding:8px 14px;
      border-radius:10px; cursor:pointer;
    `;
    btn.addEventListener('click', () => window.location.href = 'login.html');

    bar.appendChild(msg);
    bar.appendChild(btn);
    document.body.appendChild(bar);

    // 🔸 Load promotional banners dynamically
    const bannerContainer = document.getElementById('banner-container');
    if (bannerContainer) {
      const res = await fetch(${API_BASE_URL}/banners);
      const banners = await res.json();

      if (Array.isArray(banners) && banners.length > 0) {
        bannerContainer.innerHTML = banners.map((b, i) => `
          <div class="carousel-item ${i === 0 ? 'active' : ''}">
            <img src="${FILE_BASE_URL}${b.image}" 
                 alt="${b.title || ''}" 
                 class="d-block w-100" 
                 style="object-fit:cover; height:180px; border-radius:10px;" />
          </div>
        `).join('');
        console.log('✅ Public banners loaded successfully.');
      } else {
        console.warn('⚠ No promo banners found.');
      }
    }
  } catch (err) {
    console.warn('⚠ public-banner.js error:', err);
  }
});