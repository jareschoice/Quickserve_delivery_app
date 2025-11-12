// Chat widget wiring for QuickServe Event Edition
// Injects/uses a minimal widget and connects to Socket.IO
import { API_BASE_URL, FILE_BASE_URL } from './config.js';

function ensureSocketClientLoaded() {
  return new Promise((resolve) => {
    if (typeof window.io !== 'undefined') return resolve();
    const s = document.createElement('script');
    s.src = 'https://cdn.jsdelivr.net/npm/socket.io-client@4.7.5/dist/socket.io.min.js';
    s.onload = () => resolve();
    document.head.appendChild(s);
  });
}

function ensureWidget() {
  if (document.getElementById('chat-widget')) return;
  const wrap = document.createElement('div');
  wrap.id = 'chat-widget';
  wrap.innerHTML = `
    <button id="chat-toggle" aria-label="Open chat" title="Chat">
      ðŸ’¬
      <span id="chat-unread" class="chat-unread" aria-hidden="true"></span>
    </button>
    <div id="chat-box" aria-live="polite" aria-label="QuickServe chat" role="region">
      <div class="chat-header">Chat with Muhammed</div>
      <div id="chat-messages" class="chat-messages"></div>
      <div class="chat-quick-replies" id="chat-quick-replies" aria-label="Quick replies"></div>
      <div class="chat-input">
        <input id="chat-input" type="text" placeholder="Type your messageâ€¦" />
      </div>
    </div>`;
  document.body.appendChild(wrap);
}

function appendMessage(text, from='system', animate=false) {
  const box = document.getElementById('chat-messages');
  if (!box) return;
  const p = document.createElement('div');
  p.className = `msg msg-${from}`;
  p.textContent = text;
  if (animate) p.classList.add('slide-in');
  box.appendChild(p);
  box.scrollTop = box.scrollHeight;
}

function welcomeOnce() {
  const key = '__qs_chat_welcomed';
  if (sessionStorage.getItem(key)) return;
  appendMessage('Hello, welcome to QuickServe â€” we\'re here to serve you best. ðŸ˜Š', 'system', true);
  setTimeout(() => {
    appendMessage("My name is Muhammed, I\'m here to assist you. What can I help you with?", 'system', true);
  }, 350);
  sessionStorage.setItem(key, '1');
}

function getOrCreateGuestId() {
  try {
    let gid = sessionStorage.getItem('__qs_guest_id');
    if (!gid) {
      gid = 'guest-' + Math.random().toString(36).slice(2, 10);
      sessionStorage.setItem('__qs_guest_id', gid);
    }
    return gid;
  } catch {
    return 'guest-' + Math.random().toString(36).slice(2, 10);
  }
}

async function initWidget() {
  ensureWidget();
  await ensureSocketClientLoaded();

  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const senderId = user?._id || getOrCreateGuestId();
  const socket = window.io ? window.io(FILE_BASE_URL, { transports: ['websocket','polling'] }) : null;
  if (socket) {
    // identify by role/id for routing
    if (senderId || user?.role) socket.emit('identify', { userId: senderId, role: user.role || 'guest' });
  }
  // UI handlers
  const toggle = document.getElementById('chat-toggle');
  const box = document.getElementById('chat-box');
  const input = document.getElementById('chat-input');
  const unread = document.getElementById('chat-unread');
  const quick = document.getElementById('chat-quick-replies');
  toggle?.addEventListener('click', () => {
    const visible = box.style.display === 'block';
    box.style.display = visible ? 'none' : 'block';
    if (!visible) welcomeOnce();
    if (!visible && unread) unread.textContent = '';
  });
  input?.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
      const msg = input.value.trim();
      if (!msg) return;
      input.value = '';
      appendMessage(`You: ${msg}`, 'you');
      // Send to admin role for centralized support
      if (socket) socket.emit('chat:message', { from: senderId, fromRole: user?.role || 'guest', toRole: 'admin', content: msg, ts: Date.now() });
      // Lightweight bot assist
      botAutoReply(msg);
    }
  });
  // Receive messages
  if (socket) {
    socket.on('chat:message', (m) => {
      if (!m || !m.content) return;
      const sender = m.fromRole === 'admin' ? 'Admin' : (m.from || 'User');
      appendMessage(`${sender}: ${m.content}`, 'remote');
      // If chat is hidden, bump unread indicator
      const hidden = box.style.display !== 'block';
      if (hidden && unread) {
        const n = Number(unread.textContent || '0') + 1;
        unread.textContent = String(n);
      }
    });
  }

  // Expose controls and wire support triggers
  window.QuickServeChat = {
    open: () => {
      box.style.display = 'block';
      welcomeOnce();
      if (unread) unread.textContent = '';
      ensureQuickReplies();
    },
    send: (text) => {
      input.value = text;
      const evt = new KeyboardEvent('keypress', { key: 'Enter' });
      input.dispatchEvent(evt);
    }
  };

  // Make any element with [data-open-chat] open the chat
  document.querySelectorAll('[data-open-chat]').forEach(el => {
    el.addEventListener('click', (e) => { e.preventDefault(); window.QuickServeChat.open(); });
  });
  // Heuristic: bottom nav Support items
  document.querySelectorAll('.bottom-nav .nav-item, .bottom-nav a').forEach(a => {
    const txt = (a.textContent || '').trim().toLowerCase();
    if (txt.includes('support')) {
      a.setAttribute('data-open-chat', '1');
      a.addEventListener('click', (e) => { e.preventDefault(); window.QuickServeChat.open(); });
    }
  });

  function ensureQuickReplies() {
    if (!quick) return;
    if (quick.childElementCount) return;
    const replies = ['Track my order', 'Payment issue', 'Menu & prices', 'Delivery time', 'Talk to admin'];
    replies.forEach(r => {
      const b = document.createElement('button');
      b.className = 'qr-chip';
      b.type = 'button';
      b.textContent = r;
      b.addEventListener('click', () => {
        window.QuickServeChat.send(r);
      });
      quick.appendChild(b);
    });
  }

  function botAutoReply(text) {
    const t = text.toLowerCase();
    const replies = [];
    if (t.includes('track') || t.includes('where')) {
      replies.push("You can track your order on the Track page. If you share your seat/ticket ID, I can check status for you.");
    }
    if (t.includes('pay') || t.includes('payment')) {
      replies.push('For Paystack payments: make sure your card is enabled for online payments. You can also try another card or bank transfer.');
    }
    if (t.includes('menu') || t.includes('price')) {
      replies.push('Explore vendors and menus on Home. Tap any vendor to view their menu and current prices.');
    }
    if (t.includes('deliver') || t.includes('time')) {
      replies.push('Delivery usually takes 10â€“25 minutes depending on prep time and dispatch queue.');
    }
    if (!replies.length) {
      replies.push('Thanks! An admin will respond shortly. You can keep chatting here.');
    }
    setTimeout(() => replies.forEach(r => appendMessage(`Assistant: ${r}`, 'system', true)), 300);
  }
}

// Auto-init after DOM loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initWidget);
} else {
  initWidget();
}
