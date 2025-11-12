// Shared notification utilities (ES module)
// Provides: playNotificationSound, showBrowserNotification, ensureNotificationPermission

// Use a single Audio instance to avoid overlapping issues on some browsers
const _audio = new Audio('data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBDGJ0fPTgjMGHm7A7+OZUQ0PVKzo7adXEwlEmuTxwmwhBDGH0PPTgjQGHm6/7+OZTQ0PVK3o7KdXEwlFmeXwwmwhBDKI0PPTgjQGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KdXFApFmeXwwmsgBDKJ0fPSgjMGHm7A7+OYTw0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm6/7+OZTQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7KhWFApFmeXwwmwhBDKJ0fPSgjMGHm7A7+OZUQ0PVKzo7A==');

export function playNotificationSound() {
  try {
    _audio.currentTime = 0;
    _audio.play().catch(() => {});
  } catch {}
}

export function showBrowserNotification(title, body, icon) {
  if (!('Notification' in window)) return;
  if (Notification.permission !== 'granted') return;
  try {
    new Notification(title, {
      body,
      icon: icon || '/favicon.ico',
      badge: '/favicon.ico',
      vibrate: [200, 100, 200],
    });
  } catch {}
}

export function ensureNotificationPermission() {
  if (!('Notification' in window)) return;
  if (Notification.permission === 'default') {
    Notification.requestPermission().catch(() => {});
  }
}
