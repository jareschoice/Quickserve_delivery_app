// pharmacies.js
import { API_BASE_URL } from './config.js';

let all = [];

document.addEventListener('DOMContentLoaded', () => {
  load();
  const s = document.getElementById('search');
  s?.addEventListener('input', () => render(filter(s.value)));
});

function looksPharmacy(v){
  const c = [v.category, v.businessType].map(x=> (x||'').toString().toLowerCase()).join(' ');
  return /pharmacy|drug|med|chemist/.test(c);
}

async function load(){
  try{
    const r = await fetch(`${API_BASE_URL}/vendors`);
    const d = await r.json();
    all = d.vendors || [];
    const items = all.filter(looksPharmacy);
    render(items.length?items:[]);
  }catch(e){
    document.getElementById('list').innerHTML = '<div class="p-3 text-muted">Failed to load pharmacies.</div>';
  }
}

function filter(q=''){
  const s = q.trim().toLowerCase();
  return (all.filter(looksPharmacy)).filter(v => (v.businessName||v.storeName||'').toLowerCase().includes(s));
}

function render(items){
  const box = document.getElementById('list');
  if(!items || !items.length){ box.innerHTML = placeholders('Pharmacy'); return; }
  box.innerHTML = items.map(v => card(v)).join('');
}

function card(v){
  const name = v.businessName || v.storeName || 'Pharmacy';
  return `<div class="pharm-card">
    <div class="pharm-banner"><div class="fw-bold">${name}</div></div>
    <div class="pharm-body">
      <div class="d-flex justify-content-between">
        <div class="text-muted">Open â€¢ 14 - 24 min</div>
        <div class="text-warning"><i class="bi bi-star-fill"></i> ${(v.rating||4.9).toFixed(1)}</div>
      </div>
    </div>
  </div>`;
}

function placeholders(label){
  const n = 6;
  return Array.from({length:n}).map((_,i)=>`
    <div class="pharm-card position-relative" aria-disabled="true">
      <div class="pharm-banner"><div class="fw-bold text-muted">${label} Coming Soon ${i+1}</div></div>
      <div class="pharm-body">
        <div class="d-flex justify-content-between">
          <div class="text-muted">Launching shortly</div>
          <span class="badge bg-secondary">Coming soon</span>
        </div>
      </div>
      <span class="position-absolute top-0 end-0 badge rounded-pill bg-dark opacity-75 m-2">Closed</span>
    </div>
  `).join('');
}
