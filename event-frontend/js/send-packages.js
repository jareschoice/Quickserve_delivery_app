import { API_BASE_URL } from './config.js';

const sendCard = document.getElementById('sendCard');
const requestCard = document.getElementById('requestCard');
const formWrap = document.getElementById('formWrap');
const pickup = document.getElementById('pickup');
const dropoff = document.getElementById('dropoff');
const size = document.getElementById('size');
const notes = document.getElementById('notes');
const submitBtn = document.getElementById('submitBtn');
const estimateEl = document.getElementById('estimate');

function showForm() {
  formWrap.hidden = false;
  formWrap.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

sendCard?.addEventListener('click', showForm);
requestCard?.addEventListener('click', showForm);

async function getEstimate() {
  const pick = pickup.value.trim();
  const drop = dropoff.value.trim();
  if (!pick || !drop) {
    alert('Please fill pickup and dropoff addresses');
    return;
  }
  submitBtn.disabled = true;
  submitBtn.textContent = 'Calculatingâ€¦';
  estimateEl.hidden = true;
  try {
    // Try optional fare estimate if available; otherwise mock locally
    let estimate = null;
    try {
      const qs = new URLSearchParams({ from: pick, to: drop, size: size.value });
      const r = await fetch(`${API_BASE_URL}/orders/fare-estimate?${qs}`);
      if (r.ok) {
        const data = await r.json();
        estimate = data?.fare || null;
      }
    } catch {}
    if (!estimate) {
      // simple heuristic
      const base = 600; // â‚¦600 base
      const multiplier = size.value === 'large' ? 1.6 : size.value === 'medium' ? 1.3 : 1.0;
      estimate = Math.round(base * multiplier);
    }
    estimateEl.hidden = false;
    estimateEl.textContent = `Estimated delivery fee: â‚¦${Number(estimate).toLocaleString()}. You will confirm and pay after login.`;
  } catch (e) {
    alert('Could not get estimate. Please try again.');
  } finally {
    submitBtn.disabled = false;
    submitBtn.textContent = 'Get estimate';
  }
}

submitBtn?.addEventListener('click', getEstimate);
