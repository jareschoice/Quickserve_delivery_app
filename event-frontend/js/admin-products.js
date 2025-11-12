// Admin Product Management System
import { API_BASE_URL, FILE_BASE_URL } from './config.js';
import socket from './socket.js';
// Token and user are needed across functions; set them on DOMContentLoaded
let token = null;
let user = {};

let selectedVendor = null;
let currentProducts = [];
let productModal, stockModal;

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    // Check authentication (support both token keys)
    token = localStorage.getItem('token') || localStorage.getItem('eventToken');
    try { user = JSON.parse(localStorage.getItem('user') || localStorage.getItem('eventUser') || '{}'); } catch(e){ user = {}; }
    
    if (!token || user.role !== 'admin') {
        alert('Admin access required!');
        window.location.href = 'login.html';
        return;
    }

    // Initialize modals
    productModal = new bootstrap.Modal(document.getElementById('productModal'));
    stockModal = new bootstrap.Modal(document.getElementById('stockModal'));

    // Load vendors
    loadVendors();

    // Event listeners
    document.getElementById('addProductBtn').addEventListener('click', () => openProductModal());
    document.getElementById('saveProductBtn').addEventListener('click', saveProduct);
    document.getElementById('saveStockBtn').addEventListener('click', saveStockAdjustment);
    document.getElementById('vendorSearch').addEventListener('input', filterVendors);
    document.getElementById('logoutBtn').addEventListener('click', logout);

    // Stock modal preview
    ['stockAdd', 'stockReduce', 'stockSet'].forEach(id => {
        document.getElementById(id).addEventListener('change', updateStockPreview);
    });
    document.getElementById('stockAmount').addEventListener('input', updateStockPreview);

    // Image preview
    document.getElementById('productImage').addEventListener('change', previewImage);
});

// Load all vendors
async function loadVendors() {
    try {
        const response = await fetch(`${API_BASE_URL}/admin/vendors`, {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const data = await response.json();

        if (response.ok && data.vendors) {
            displayVendors(data.vendors);
        } else {
            showError(data.message || data.error || 'Failed to load vendors');
        }
    } catch (error) {
        console.error('Error loading vendors:', error);
        showError('Failed to load vendors');
    }
}

// Display vendor list
function displayVendors(vendors) {
    const vendorList = document.getElementById('vendorList');
    
    if (vendors.length === 0) {
        vendorList.innerHTML = '<div class="alert alert-warning">No vendors found</div>';
        return;
    }

    vendorList.innerHTML = vendors.map(vendor => `
        <div class="card vendor-card mb-2" data-vendor-id="${vendor._id}" onclick="selectVendor('${vendor._id}')">
            <div class="card-body p-3">
                <h6 class="mb-1">${vendor.storeName || vendor.user?.name || 'Unnamed Vendor'}</h6>
                <small class="text-muted">${vendor.user?.email || ''}</small>
                ${vendor.category ? `<br><small class="badge bg-secondary mt-1">${vendor.category}</small>` : ''}
            </div>
        </div>
    `).join('');
}

// Filter vendors by search
function filterVendors() {
    const searchTerm = document.getElementById('vendorSearch').value.toLowerCase();
    const vendorCards = document.querySelectorAll('.vendor-card');

    vendorCards.forEach(card => {
        const text = card.textContent.toLowerCase();
        card.style.display = text.includes(searchTerm) ? '' : 'none';
    });
}

// Select a vendor
window.selectVendor = async function(vendorId) {
    try {
        // Update UI
        document.querySelectorAll('.vendor-card').forEach(card => {
            card.classList.remove('active');
        });
        document.querySelector(`[data-vendor-id="${vendorId}"]`).classList.add('active');

        // Get vendor details from list in DOM to avoid extra request
        // For a robust app you'd cache the vendors from loadVendors
        const card = document.querySelector(`[data-vendor-id="${vendorId}"]`);
        if (card) {
            selectedVendor = { _id: vendorId, name: card.querySelector('h6')?.textContent };
        }
        
        if (selectedVendor) {
            
            // Show vendor info
            document.getElementById('selectedVendorInfo').style.display = 'block';
            document.getElementById('selectedVendorName').textContent = selectedVendor.name || 'Unnamed Vendor';
            document.getElementById('selectedVendorEmail').textContent = '';
            
            // Enable add button
            document.getElementById('addProductBtn').disabled = false;

            // Load products
            loadProducts(vendorId);
        }
    } catch (error) {
        console.error('Error selecting vendor:', error);
        showError('Failed to select vendor');
    }
}

// Load products for selected vendor
async function loadProducts(vendorId) {
    const container = document.getElementById('productsContainer');
    container.innerHTML = '<div class="text-center py-4"><div class="spinner-border text-primary"></div></div>';

    try {
    const response = await fetch(`${API_BASE_URL}/products?vendorId=${vendorId}`);
        const data = await response.json();

        if (response.ok && (data.items || []).length >= 0) {
            currentProducts = data.items || [];
            displayProducts(currentProducts);
        }
    } catch (error) {
        console.error('Error loading products:', error);
        container.innerHTML = '<div class="alert alert-danger">Failed to load products</div>';
    }
}

// Display products grid
function displayProducts(products) {
    const container = document.getElementById('productsContainer');

    if (products.length === 0) {
        container.innerHTML = `
            <div class="alert alert-info">
                <i class="bi bi-info-circle"></i> No products yet. Click "Add New Product" to get started!
            </div>
        `;
        return;
    }

    container.innerHTML = `
        <div class="row g-3">
            ${products.map(product => `
                <div class="col-md-6 col-lg-4">
                    <div class="card h-100 shadow-sm">
                        ${product.image ? `
                            <img src="${FILE_BASE_URL}${product.image}" class="card-img-top" alt="${product.name}" style="height: 200px; object-fit: cover;">
                        ` : `
                            <div class="bg-light d-flex align-items-center justify-content-center" style="height: 200px;">
                                <i class="bi bi-image text-muted" style="font-size: 3rem;"></i>
                            </div>
                        `}
                        <div class="card-body">
                            <h5 class="card-title">${product.name}</h5>
                            <p class="card-text text-muted small">${product.description || 'No description'}</p>
                            
                            <div class="d-flex justify-content-between align-items-center mb-2">
                                <h4 class="text-primary mb-0">â‚¦${Number(product.price).toLocaleString()}</h4>
                                <span class="badge ${getStockBadgeClass(product.quantity)} stock-badge">
                                    ${product.quantity} ${product.unit || 'pcs'}
                                </span>
                            </div>

                            ${product.category ? `<span class="badge bg-secondary mb-2 me-1">${product.category}</span>` : ''}
                            ${Array.isArray(product.tags) && product.tags.length ? product.tags.map(t => `<span class="badge bg-info text-dark mb-2 me-1">${t}</span>`).join('') : ''}
                            
                            <div class="form-check form-switch mb-3">
                                <input class="form-check-input" type="checkbox" id="available_${product._id}" 
                                    ${product.available !== false ? 'checked' : ''} 
                                    onchange="toggleAvailability('${product._id}', this.checked)">
                                <label class="form-check-label" for="available_${product._id}">
                                    ${product.available !== false ? 'Available' : 'Unavailable'}
                                </label>
                            </div>

                            <div class="btn-group w-100" role="group">
                                <button class="btn btn-sm btn-warning" onclick="openStockModal('${product._id}')">
                                    <i class="bi bi-box"></i> Stock
                                </button>
                                <button class="btn btn-sm btn-primary" onclick="editProduct('${product._id}')">
                                    <i class="bi bi-pencil"></i> Edit
                                </button>
                                <button class="btn btn-sm btn-danger" onclick="deleteProduct('${product._id}')">
                                    <i class="bi bi-trash"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>
    `;
}

// Get stock badge color class
function getStockBadgeClass(quantity) {
    if (quantity === 0) return 'bg-danger stock-low';
    if (quantity < 10) return 'bg-warning stock-medium';
    return 'bg-success stock-high';
}

// Open product modal (add or edit)
function openProductModal(productId = null) {
    const form = document.getElementById('productForm');
    form.reset();
    
    document.getElementById('imagePreviewContainer').style.display = 'none';
    document.getElementById('productVendorId').value = selectedVendor._id;

    if (productId) {
        // Edit mode
        const product = currentProducts.find(p => p._id === productId);
        if (product) {
            document.getElementById('productModalTitle').innerHTML = '<i class="bi bi-pencil"></i> Edit Product';
            document.getElementById('productId').value = product._id;
            document.getElementById('productName').value = product.name;
            document.getElementById('productCategory').value = product.category || '';
            document.getElementById('productDescription').value = product.description || '';
            document.getElementById('productPrice').value = product.price;
            document.getElementById('productQuantity').value = product.quantity;
            document.getElementById('productUnit').value = product.unit || 'piece';
            document.getElementById('productAvailable').checked = product.available !== false;
            // Prefill section selector from first tag if present
            try {
                const tags = Array.isArray(product.tags) ? product.tags : [];
                const first = tags[0] || '';
                const sec = document.getElementById('productSection');
                if (sec && first) sec.value = first;
            } catch {}

            if (product.imageUrl || product.image) {
                document.getElementById('imagePreviewContainer').style.display = 'block';
                document.getElementById('imagePreview').src = product.imageUrl || `${FILE_BASE_URL}${product.image}`;
            }
        }
    } else {
        // Add mode
        document.getElementById('productModalTitle').innerHTML = '<i class="bi bi-plus-circle"></i> Add New Product';
        document.getElementById('productId').value = '';
    }

    productModal.show();
}

window.editProduct = function(productId) {
    openProductModal(productId);
}

// Preview image before upload
function previewImage() {
    const file = document.getElementById('productImage').files[0];
    if (file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            document.getElementById('imagePreviewContainer').style.display = 'block';
            document.getElementById('imagePreview').src = e.target.result;
        };
        reader.readAsDataURL(file);
    }
}

// Save product (add or edit)
async function saveProduct() {
    const form = document.getElementById('productForm');
    if (!form.checkValidity()) {
        form.reportValidity();
        return;
    }

    const productId = document.getElementById('productId').value;
    const formData = new FormData();
    if (selectedVendor && selectedVendor._id) {
        formData.append('vendorId', selectedVendor._id); // also support alias route
    }
    formData.append('name', document.getElementById('productName').value);
    const category = document.getElementById('productCategory').value;
    formData.append('category', category);
    formData.append('description', document.getElementById('productDescription').value);
    formData.append('price', Number(document.getElementById('productPrice').value));
    formData.append('quantity', Number(document.getElementById('productQuantity').value));
    formData.append('unit', document.getElementById('productUnit').value);
    formData.append('available', document.getElementById('productAvailable').checked);
    // Optional: tags/sections (single select; backend accepts string or array)
    const sectionEl = document.getElementById('productSection');
    const section = sectionEl ? sectionEl.value : '';
    if (section) {
        formData.append('tags', section);
    }
    const imageFile = document.getElementById('productImage').files[0];
    if (imageFile) {
        formData.append('image', imageFile);
    }

    const saveBtn = document.getElementById('saveProductBtn');
    saveBtn.disabled = true;
    saveBtn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Saving...';

    try {
        const url = productId 
            ? `${API_BASE_URL}/admin/products/${productId}`
            : `${API_BASE_URL}/admin/vendors/${selectedVendor._id}/products`;
        
        const method = productId ? 'PUT' : 'POST';

        const response = await fetch(url, {
            method,
            headers: {
                'Authorization': `Bearer ${token}`
            },
            body: formData
        });

        const data = await response.json().catch(() => ({ error: 'Invalid JSON from server' }));

        if (response.ok && (data.success || data.product)) {
            showSuccess(productId ? 'Product updated successfully!' : 'Product added successfully!');
            productModal.hide();
            loadProducts(selectedVendor._id);
        } else {
            if (response.status === 401) {
                showError('Unauthorized: please log in again.');
            } else if (response.status === 403) {
                showError('Forbidden: admin role required to manage products. Please sign in as admin.');
            } else {
                showError((data && (data.message || data.error)) ? `${data.message || data.error}` : `Failed to save product (HTTP ${response.status})`);
            }
        }
    } catch (error) {
        console.error('Error saving product:', error);
        showError('Failed to save product');
    } finally {
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="bi bi-save"></i> Save Product';
    }
}

// Delete product
window.deleteProduct = async function(productId) {
    if (!confirm('Are you sure you want to delete this product? This action cannot be undone.')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/admin/products/${productId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        const data = await response.json();

        if (data.success) {
            showSuccess('Product deleted successfully!');
            loadProducts(selectedVendor._id);
        } else {
            showError(data.message || 'Failed to delete product');
        }
    } catch (error) {
        console.error('Error deleting product:', error);
        showError('Failed to delete product');
    }
}

// Toggle product availability
window.toggleAvailability = async function(productId, available) {
    try {
        const response = await fetch(`${API_BASE_URL}/admin/products/${productId}/availability`, {
            method: 'PATCH',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ available })
        });

        const data = await response.json();

        if (data.success) {
            showSuccess(`Product ${available ? 'enabled' : 'disabled'} successfully!`);
        } else {
            showError(data.message || 'Failed to update availability');
            // Revert checkbox
            document.getElementById(`available_${productId}`).checked = !available;
        }
    } catch (error) {
        console.error('Error toggling availability:', error);
        showError('Failed to update availability');
        document.getElementById(`available_${productId}`).checked = !available;
    }
}

// Open stock adjustment modal
window.openStockModal = function(productId) {
    const product = currentProducts.find(p => p._id === productId);
    if (!product) return;

    document.getElementById('stockProductId').value = product._id;
    document.getElementById('stockCurrentQty').value = product.quantity;
    document.getElementById('stockProductName').textContent = product.name;
    document.getElementById('stockCurrentDisplay').textContent = product.quantity;
    document.getElementById('stockUnit').textContent = product.unit || 'pcs';
    document.getElementById('stockNewUnit').textContent = product.unit || 'pcs';
    document.getElementById('stockAmount').value = '';
    document.getElementById('stockReason').value = '';
    document.getElementById('stockPreview').style.display = 'none';

    stockModal.show();
}

// Update stock preview
function updateStockPreview() {
    const currentQty = parseInt(document.getElementById('stockCurrentQty').value);
    const amount = parseInt(document.getElementById('stockAmount').value) || 0;
    const action = document.querySelector('input[name="stockAction"]:checked').value;

    let newQty;
    if (action === 'add') {
        newQty = currentQty + amount;
    } else if (action === 'reduce') {
        newQty = Math.max(0, currentQty - amount);
    } else {
        newQty = amount;
    }

    document.getElementById('stockNewValue').textContent = newQty;
    document.getElementById('stockPreview').style.display = amount > 0 ? 'block' : 'none';
}

// Save stock adjustment
async function saveStockAdjustment() {
    const productId = document.getElementById('stockProductId').value;
    const currentQty = parseInt(document.getElementById('stockCurrentQty').value);
    const amount = parseInt(document.getElementById('stockAmount').value);
    const action = document.querySelector('input[name="stockAction"]:checked').value;
    const reason = document.getElementById('stockReason').value;

    if (!amount || amount <= 0) {
        alert('Please enter a valid amount');
        return;
    }

    let newQty;
    if (action === 'add') {
        newQty = currentQty + amount;
    } else if (action === 'reduce') {
        newQty = Math.max(0, currentQty - amount);
    } else {
        newQty = amount;
    }

    const saveBtn = document.getElementById('saveStockBtn');
    saveBtn.disabled = true;
    saveBtn.innerHTML = '<span class="spinner-border spinner-border-sm"></span> Updating...';

    try {
        const response = await fetch(`${API_BASE_URL}/admin/products/${productId}/stock`, {
            method: 'PATCH',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ 
                quantity: newQty,
                action,
                amount,
                reason
            })
        });

        const data = await response.json();

        if (data.success) {
            showSuccess('Stock updated successfully!');
            stockModal.hide();
            loadProducts(selectedVendor._id);
        } else {
            showError(data.message || 'Failed to update stock');
        }
    } catch (error) {
        console.error('Error updating stock:', error);
        showError('Failed to update stock');
    } finally {
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="bi bi-check-circle"></i> Update Stock';
    }
}

// Utility functions
function showSuccess(message) {
    // You can use a toast library or custom implementation
    alert(message);
}

function showError(message) {
    alert('Error: ' + message);
}

function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('eventToken');
    localStorage.removeItem('user');
    localStorage.removeItem('eventUser');
    window.location.href = 'login.html';
}
