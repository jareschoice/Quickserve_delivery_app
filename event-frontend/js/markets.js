import { API_BASE_URL } from './config.js';

const searchInput = document.getElementById('search');
const listEl = document.getElementById('list');

let vendors = [];

function isMarketVendor(v) {
  const name = (v.businessName || v.name || '').toLowerCase();
  const tags = (v.tags || []).map(t => String(t).toLowerCase());
  const categories = (v.categories || []).map(c => String(c).toLowerCase());
  return name.includes('market') || tags.includes('market') || categories.includes('market');
}

function render(vs){
  listEl.innerHTML = '';
  if(!vs.length){
    listEl.innerHTML = `<div class="text-center text-muted py-5">No local markets found</div>`;
    return;
  }
  for(const v of vs){
    const img = v.logoUrl || v.coverImage || 'https://images.unsplash.com/photo-1519860053410-64a93db511aa?w=800';
    const distance = v.distanceKm ? `${v.distanceKm.toFixed(1)} km` : '';
    const address = v.address || v.location || '';
    const id = v._id || v.id;

    const card = document.createElement('div');
    card.className = 'market-card';
    card.innerHTML = `
      <div class="market-image" style="background-image:url('${img}')"></div>
      <div class="market-body">
        <div class="d-flex align-items-center justify-content-between">
          <div>
            <div class="fw-semibold">${v.businessName || v.name || 'Local Market'}</div>
            <div class="text-muted small">${address}</div>
          </div>
          <div class="small text-nowrap text-muted">${distance}</div>
        </div>
      </div>
    `;
    card.addEventListener('click', ()=>{
      if(!id) return;
      window.location.href = `vendor.html?id=${encodeURIComponent(id)}`;
    });
    listEl.appendChild(card);
  }
}

function applyFilter(){
  const q = (searchInput.value || '').toLowerCase().trim();
  const filtered = vendors.filter(v => {
    if(!isMarketVendor(v)) return false;
    if(!q) return true;
    const hay = [v.businessName, v.name, v.address, v.location].filter(Boolean).join(' ').toLowerCase();
    return hay.includes(q);
  });
  render(filtered);
}

async function init(){
  try{
    const res = await fetch(`${API_BASE_URL}/vendors`);
    const data = await res.json();
    vendors = Array.isArray(data?.vendors) ? data.vendors : (Array.isArray(data) ? data : []);
    // If none tagged as market, heuristically include large vendors that sell groceries/foodstuff based on categories
    if(!vendors.some(isMarketVendor)){
      vendors = vendors.map(v => {
        const categories = (v.categories || []).map(c => String(c).toLowerCase());
        if(categories.some(c => ['groceries','foodstuff','vegetables','provisions'].includes(c))){
          return { ...v, tags: [...(v.tags||[]), 'market'] };
        }
        return v;
      });
    }
    applyFilter();
  }catch(err){
    console.error('Failed to load markets', err);
    listEl.innerHTML = `<div class="alert alert-danger m-3">Unable to load markets. Please try again.</div>`;
  }
}

searchInput.addEventListener('input', applyFilter);
init();
