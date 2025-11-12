import { API_BASE_URL } from './config.js';
import './auth-guard.js';

async function requireAdmin() {
  const mod = await import('./auth-guard.js');
  await mod.requireAuth('admin');
}

const listEl = document.getElementById('list');
const searchEl = document.getElementById('search');
const tpl = document.getElementById('rowTpl');

let items = [];

function shape(v) {
  return {
    id: v._id,
    name: v.businessName || v.storeName || 'Vendor',
    address: v.businessAddress || '',
    phone: v.businessPhone || v.user?.profile?.businessPhone || '',
    category: v.category || 'Other',
    email: v.user?.email || '',
    isActive: v.isActive !== false,
  };
}

function render(rows) {
  listEl.innerHTML = '';
  rows.forEach(v => {
    const node = tpl.content.firstElementChild.cloneNode(true);
    node.querySelector('[data-name]').textContent = v.name;
    node.querySelector('[data-address]').textContent = v.address;
    node.querySelector('[data-email]').textContent = v.email;
    const badge = node.querySelector('[data-badge]');
    badge.textContent = v.isActive ? 'Active' : 'Inactive';
    badge.className = `me-2 badge ${v.isActive ? 'bg-success' : 'bg-secondary'}`;
    node.querySelector('[data-category]').textContent = v.category;

    const form = node.querySelector('[data-form]');
    const editBtn = node.querySelector('[data-edit]');
    const delBtn = node.querySelector('[data-delete]');
    const saveBtn = node.querySelector('[data-save]');

    editBtn.addEventListener('click', () => {
      form.classList.toggle('d-none');
      form.businessName.value = v.name;
      form.category.value = v.category;
      form.businessAddress.value = v.address;
      form.businessPhone.value = v.phone;
      form.isActive.checked = v.isActive;
    });

    saveBtn.addEventListener('click', async () => {
      const body = {
        businessName: form.businessName.value.trim(),
        category: form.category.value.trim(),
        businessAddress: form.businessAddress.value.trim(),
        businessPhone: form.businessPhone.value.trim(),
        isActive: !!form.isActive.checked,
      };
      await updateVendor(v.id, body);
    });

    delBtn.addEventListener('click', async () => {
      if (!confirm('Delete this vendor? This cannot be undone.')) return;
      await deleteVendor(v.id);
    });

    listEl.appendChild(node);
  });
}

function applyFilter() {
  const q = (searchEl.value || '').toLowerCase();
  const rows = items.filter(v => `${v.name} ${v.address} ${v.email}`.toLowerCase().includes(q));
  render(rows);
}

async function load() {
  await requireAdmin();
  const token = localStorage.getItem('token');
  const res = await fetch(`${API_BASE_URL}/admin/vendors`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  const data = await res.json();
  items = (data.vendors || []).map(shape);
  applyFilter();
}

async function updateVendor(id, payload) {
  const token = localStorage.getItem('token');
  const res = await fetch(`${API_BASE_URL}/admin/vendors/${id}`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });
  if (!res.ok) {
    alert('Failed to update vendor');
    return;
  }
  await load();
}

async function deleteVendor(id) {
  const token = localStorage.getItem('token');
  const res = await fetch(`${API_BASE_URL}/admin/vendors/${id}`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (!res.ok) {
    alert('Failed to delete vendor');
    return;
  }
  await load();
}

searchEl.addEventListener('input', applyFilter);
load();
