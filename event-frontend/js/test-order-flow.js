// Frontend test harness: simulate an event order lifecycle end-to-end
// Usage: click the "Run test order flow" button on home.html

import { API_BASE_URL } from './env-config.js';

const logElId = 'testFlowLog';
const btnId = 'runTestFlowBtn';

function log(msg, obj) {
  const container = document.getElementById(logElId) || createLogArea();
  const line = document.createElement('div');
  line.className = 'small mb-1';
  line.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;
  container.prepend(line);
  if (obj) {
    const p = document.createElement('pre');
    p.className = 'small text-muted';
    try { p.textContent = JSON.stringify(obj, null, 2); } catch (e) { p.textContent = String(obj); }
    container.prepend(p);
  }
  console.log(msg, obj || '');
}

function createLogArea() {
  // Add a small log area under the product feed if missing
  const feed = document.getElementById('productFeed') || document.body;
  const wrapper = document.createElement('div');
  wrapper.id = 'testFlowWrapper';
  wrapper.className = 'mt-3';
  const title = document.createElement('h6');
  title.textContent = 'Test order flow logs';
  title.className = 'mb-2';
  const logArea = document.createElement('div');
  logArea.id = logElId;
  logArea.style.maxHeight = '240px';
  logArea.style.overflow = 'auto';
  logArea.style.background = '#fff8e6';
  logArea.style.border = '1px solid #ffe7b3';
  logArea.style.padding = '12px';
  wrapper.appendChild(title);
  wrapper.appendChild(logArea);
  feed.parentNode.insertBefore(wrapper, feed.nextSibling);
  return logArea;
}

async function fetchJson(url, opts = {}) {
  const res = await fetch(url, opts);
  const text = await res.text();
  try { return { ok: res.ok, status: res.status, data: JSON.parse(text) }; } catch (e) { return { ok: res.ok, status: res.status, data: text }; }
}

async function tryLoginMany(credsList) {
  for (const c of credsList) {
    try {
      const r = await fetchJson(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: c.email, password: c.password })
      });
      if (r.ok && r.data && r.data.token) return r.data;
      log(`login failed for ${c.email} (status ${r.status})`, r.data || r);
    } catch (e) {
      log(`login error for ${c.email}`, e.message || e);
    }
  }
  return null;
}

async function runTestFlow() {
  const btn = document.getElementById(btnId);
  if (btn) btn.disabled = true;
  log('Starting test order flow...');

  try {
    // 1) choose first vendor
    const vendorsResp = await fetchJson(`${API_BASE_URL}/event/vendors`);
    if (!vendorsResp.ok) {
      log('Failed to fetch vendors', vendorsResp);
      return;
    }
    const vendors = vendorsResp.data && vendorsResp.data.vendors ? vendorsResp.data.vendors : [];
    if (vendors.length === 0) { log('No vendors found'); return; }
    const vendor = vendors[0];
    log('Selected vendor', vendor);

    // 2) create order (public)
    log('Creating order...');
    const createResp = await fetchJson(`${API_BASE_URL}/event/orders`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone: '0800000001', seatNumber: 'A1', vendorId: vendor._id || vendor._id, items: [{ name: 'Demo Item', qty: 1, price: 500 }] })
    });
    log('Create order response', createResp);
    if (!createResp.ok) { log('Order creation failed'); return; }
    const orderId = createResp.data.order && createResp.data.order._id ? createResp.data.order._id : (createResp.data._id || null);
    if (!orderId) { log('Could not determine order id'); return; }

    // 3) vendor login
    log('Logging in as vendor to accept order...');
    const vendorCreds = [
      { email: vendor.email, password: `Vendor${(vendor.email.match(/vendor(\d+)/)||[,1])[1]}!` },
      { email: vendor.email, password: 'Vendor1!' }
    ];
    const vendorAuth = await tryLoginMany(vendorCreds);
    if (!vendorAuth) { log('Vendor login failed - cannot progress vendor steps'); return; }
    log('Vendor logged in', { user: vendorAuth.user });

    // 4) vendor accepts
    log('Vendor: accepting order...');
    const acceptResp = await fetchJson(`${API_BASE_URL}/event/vendor/orders/${orderId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + vendorAuth.token },
      body: JSON.stringify({ status: 'accepted' })
    });
    log('Accept response', acceptResp);
    if (!acceptResp.ok) return;

    // 5) vendor marks ready
    await new Promise(r => setTimeout(r, 800));
    log('Vendor: marking order ready...');
    const readyResp = await fetchJson(`${API_BASE_URL}/event/vendor/orders/${orderId}/status`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + vendorAuth.token },
      body: JSON.stringify({ status: 'ready' })
    });
    log('Ready response', readyResp);
    if (!readyResp.ok) return;

    // 6) dispatcher login (try common test accounts)
    log('Logging in as dispatcher to claim...');
    const dispatchersToTry = [
      { email: 'dispatcher1@quickserve.test', password: 'dispatcher123' },
      { email: 'dispatcher1@quickserve.com', password: 'Dispatcher1!' },
      { email: 'dispatcher1@event.test', password: 'dispatcher123' }
    ];
    const dispatcherAuth = await tryLoginMany(dispatchersToTry);
    if (!dispatcherAuth) { log('Dispatcher login failed - cannot progress claim'); return; }
    log('Dispatcher logged in', dispatcherAuth.user);

    // 7) claim order
    log('Dispatcher: claiming order...');
    const claimResp = await fetchJson(`${API_BASE_URL}/event/dispatcher/claim`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + dispatcherAuth.token },
      body: JSON.stringify({ orderId })
    });
    log('Claim response', claimResp);
    if (!claimResp.ok) return;

    // 8) fetch order to get qr token
    await new Promise(r => setTimeout(r, 700));
    log('Fetching order (to read QR token)...');
    const trackResp = await fetchJson(`${API_BASE_URL}/event/orders/${orderId}`);
    log('Track response', trackResp);
    if (!trackResp.ok) return;
    const qrToken = trackResp.data && trackResp.data.order && trackResp.data.order.deliveryConfirmationToken ? trackResp.data.order.deliveryConfirmationToken : null;
    if (!qrToken) { log('Could not read QR token from track response — aborting confirm'); return; }

    // 9) confirm delivery
    log('Dispatcher: confirming delivery with QR token...');
    const confirmResp = await fetchJson(`${API_BASE_URL}/event/dispatcher/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + dispatcherAuth.token },
      body: JSON.stringify({ orderId, qrToken })
    });
    log('Confirm response', confirmResp);

    log('Test flow finished. Check vendor/dispatcher dashboards and server logs for emitted socket events.');
  } catch (e) {
    log('Test flow error', e && e.message ? e.message : e);
  } finally {
    const btn = document.getElementById(btnId);
    if (btn) btn.disabled = false;
  }
}

function wire() {
  const btn = document.getElementById(btnId);
  if (!btn) return;
  btn.addEventListener('click', () => {
    // ensure log area exists
    createLogArea();
    runTestFlow();
  });
}

document.addEventListener('DOMContentLoaded', wire);

export default { runTestFlow };
