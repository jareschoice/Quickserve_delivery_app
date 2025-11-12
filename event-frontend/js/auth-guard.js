// Auth Guard + Banner Redirect for protected dashboards
// Usage: import { requireAuth } from './js/auth-guard.js'; requireAuth('vendor'|'dispatcher'|'admin');

export function requireAuth(expectedRole) {
  // Support both legacy keys and new keys used across the frontend:
  // - 'token' + 'user'
  // - 'eventToken' + 'eventUser'
  const token = localStorage.getItem('token') || localStorage.getItem('eventToken');
  const userRaw = localStorage.getItem('user') || localStorage.getItem('eventUser') || '{}';
  let user = {};
  try { user = JSON.parse(userRaw || '{}'); } catch (err) { user = {}; }

  if (!token) {
    showBanner('Login required. Redirecting to login…');
    setTimeout(() => { window.location.href = 'login.html'; }, 1200);
    return false;
  }
  if (expectedRole && user?.role && user.role !== expectedRole) {
    showBanner(`Insufficient permissions for ${expectedRole}. Redirecting…`, true);
    setTimeout(() => { window.location.href = 'login.html'; }, 1200);
    return false;
  }

  // Identify user/role for sockets or other modules
  window.__qs_authUser = user;
  window.__qs_token = token;
  return true;
}

function showBanner(message, danger=false) {
  let bar = document.getElementById('auth-banner');
  if (!bar) {
    bar = document.createElement('div');
    bar.id = 'auth-banner';
    bar.style.position = 'fixed';
    bar.style.top = '0';
    bar.style.left = '0';
    bar.style.right = '0';
    bar.style.zIndex = '2000';
    bar.style.padding = '10px 16px';
    bar.style.textAlign = 'center';
    bar.style.fontWeight = '600';
    bar.style.color = '#fff';
    bar.style.boxShadow = '0 2px 8px rgba(0,0,0,0.2)';
    document.body.appendChild(bar);
  }
  bar.style.background = danger ? '#dc3545' : '#ff6b00';
  bar.textContent = message;
}
