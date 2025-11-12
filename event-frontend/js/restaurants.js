// restaurants.js
import { API_BASE_URL } from './config.js';

let all = [];

document.addEventListener('DOMContentLoaded', () => {
  load();
  const s = document.getElementById('search');
  s?.addEventListener('input', () => render(filter(s.value)));
});

function matchCategory(v){
  const c = (v.category || v.businessType || '').toString().toLowerCase();
  return c.includes('restaurant') || c.includes('food') || c.includes('grill') || c.includes('shawarma');
}

async function load(){
  try{
    const r = await fetch(`${API_BASE_URL}/vendors`);
    const d = await r.json();
    all = d.vendors || [];
    // Prefer only vendors that look like restaurants
    const filtered = all.filter(matchCategory);
    render(filtered.length?filtered:all);
  }catch(e){
    document.getElementById('list').innerHTML = '<div class="p-3 text-muted">Failed to load vendors.</div>';
  }
}

function filter(q=''){
  const s = q.trim().toLowerCase();
  if(!s) return all.filter(matchCategory);
  return all.filter(v => (v.businessName||v.storeName||'').toLowerCase().includes(s));
}

function render(items){
  const box = document.getElementById('list');
  if(!items || !items.length){ box.innerHTML = placeholders('Restaurant'); return; }
  box.innerHTML = items.map(v => card(v)).join('');
  box.querySelectorAll('[data-id]')?.forEach(el=>{
    el.addEventListener('click',()=>{
      const id = el.getAttribute('data-id');
      if(id) window.location.href = `vendor.html?id=${id}`;
    });
  })
}

function card(v){
  const name = v.businessName || v.storeName || 'Restaurant';
  const eta = v.minimumOrder ? `From â‚¦${v.minimumOrder}`: '';
  return `<div class="vendor-card" data-id="${v._id}">
    <div class="vendor-thumb">${name[0]}</div>
    <div class="vendor-body">
      <div class="d-flex justify-content-between">
        <div class="fw-semibold">${name}</div>
        <div class="rating"><i class="bi bi-star-fill"></i> ${(v.rating||4.3).toFixed(1)}</div>
      </div>
      <div class="text-muted small">${eta} â€¢ ${(v.eta || '15 - 30 min')}</div>
    </div>
  </div>`;
}

function placeholders(label){
  const n = 6;
  return Array.from({length:n}).map((_,i)=>`
    <div class="vendor-card position-relative" aria-disabled="true">
      <div class="vendor-thumb">${label[0] || 'R'}</div>
      <div class="vendor-body">
        <div class="d-flex justify-content-between">
          <div class="fw-semibold text-muted">${label} Coming Soon ${i+1}</div>
          <span class="badge bg-secondary">Coming soon</span>
        </div>
        <div class="text-muted small">Launching shortly</div>
      </div>
      <span class="position-absolute top-0 end-0 badge rounded-pill bg-dark opacity-75 m-2">Closed</span>
    </div>
  `).join('');
}
