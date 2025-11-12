// shops.js
import { API_BASE_URL } from './config.js';

let all = [];
let currentTab = 'all';

document.addEventListener('DOMContentLoaded', () => {
  load();
  const s = document.getElementById('search');
  s?.addEventListener('input', () => render(filter(s.value)));
  document.getElementById('tabs')?.querySelectorAll('.tab')?.forEach(t => {
    t.addEventListener('click', () => {
      document.querySelectorAll('.tab').forEach(x=>x.classList.remove('active'));
      t.classList.add('active');
      currentTab = t.getAttribute('data-k') || 'all';
      render(filter(s?.value||''));
    });
  });
});

function isShop(v){
  const c = [v.category, v.businessType].map(x=> (x||'').toString().toLowerCase()).join(' ');
  // Include shops, supermarkets, marts; exclude only explicit restaurants and pharmacies
  if (c.includes('restaurant') || c.includes('pharmacy')) return false;
  // Include anything with shop, market, mart, store, or general category
  return true;
}

function matchesTab(v){
  if(currentTab==='all') return true;
  const c = [v.category, v.businessType].map(x=> (x||'').toString().toLowerCase()).join(' ');
  return (
    (currentTab==='supermarket' && /supermarket|grocery|mart/.test(c)) ||
    (currentTab==='minimart' && /mini|mart/.test(c)) ||
    (currentTab==='deli' && /deli|butcher|cheese/.test(c)) ||
    (currentTab==='kiosk' && /kiosk|stall|booth/.test(c))
  );
}

async function load(){
  try{
    const r = await fetch(`${API_BASE_URL}/vendors`);
    const d = await r.json();
    all = (d.vendors || []).filter(isShop);
    render(all);
  }catch(e){
    document.getElementById('list').innerHTML = '<div class="p-3 text-muted">Failed to load shops.</div>';
  }
}

function filter(q=''){
  const s = q.trim().toLowerCase();
  let items = all;
  if(s) items = items.filter(v => (v.businessName||v.storeName||'').toLowerCase().includes(s));
  return items.filter(matchesTab);
}

function render(items){
  const box = document.getElementById('list');
  if(!items || !items.length){ 
    box.innerHTML = placeholders('Shops');
    return; 
  }
  box.innerHTML = items.map(v => card(v)).join('');
  box.querySelectorAll('[data-id]')?.forEach(el=>{
    el.addEventListener('click',()=>{
      const id = el.getAttribute('data-id');
      if(id) window.location.href = `vendor.html?id=${id}`;
    });
  })
}

function placeholders(label){
  const n = 6;
  const cards = Array.from({length:n}).map((_,i)=>`
    <div class="vendor-card position-relative" aria-disabled="true">
      <div class="vendor-thumb">${label[0] || 'S'}</div>
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
  return cards;
}

function card(v){
  const name = v.businessName || v.storeName || 'Shop';
  const subtitle = (v.category || v.businessType || 'General').toString();
  return `<div class="vendor-card" data-id="${v._id}">
    <div class="vendor-thumb">${name[0]}</div>
    <div class="vendor-body">
      <div class="d-flex justify-content-between">
        <div class="fw-semibold">${name}</div>
        <div class="text-muted small">${(v.distanceKm? v.distanceKm+' km':'')}</div>
      </div>
      <div class="text-muted small">${subtitle}</div>
    </div>
  </div>`;
}
