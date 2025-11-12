// Configuration - use auto-generated env-config for correct host/port
import { AUTH_API_URL } from './env-config.js';

// Handle login form submission
document.getElementById('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();

  const email = document.getElementById('email').value;
  const password = document.getElementById('password').value;
  const role = document.getElementById('role').value;

  if (!role) {
    showError('Please select a role');
    return;
  }

  try {
    console.log('ðŸ” Attempting login...');
    console.log('Email:', email);
    console.log('Role:', role);
  console.log('API URL:', `${AUTH_API_URL}/login`);
    
  const response = await fetch(`${AUTH_API_URL}/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ email, password })
    });

    console.log('Response status:', response.status);
    const data = await response.json();
    console.log('Response data:', data);

    if (response.ok && data.token) {
      // Verify role matches
      if (data.user.role !== role) {
        showError(`You are registered as ${data.user.role}, not ${role}`);
        return;
      }

      // Store token
      localStorage.setItem('token', data.token);
      localStorage.setItem('eventToken', data.token); // Also store as eventToken for compatibility
      localStorage.setItem('user', JSON.stringify(data.user));

      console.log('âœ… Login successful! Redirecting...');

      // Redirect based on role
      switch (role) {
        case 'vendor':
          window.location.href = 'vendor-dashboard.html';
          break;
        case 'dispatcher':
          window.location.href = 'dispatcher.html';
          break;
        case 'admin':
          window.location.href = 'admin.html';
          break;
        default:
          window.location.href = 'index.html';
      }
    } else {
      showError(data.message || 'Login failed. Please check your credentials.');
    }
  } catch (error) {
    console.error('âŒ Login error:', error);
    showError('Network error: ' + error.message + '. Check if server is running on port 5555.');
  }
});

// Show error message
function showError(message) {
  const errorDiv = document.getElementById('error-message');
  errorDiv.textContent = message;
  errorDiv.style.display = 'block';
  
  setTimeout(() => {
    errorDiv.style.display = 'none';
  }, 5000);
}
