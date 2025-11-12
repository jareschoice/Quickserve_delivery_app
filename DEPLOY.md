QuickServe Deployment Notes

This document gives minimal steps to bring the QuickServe app live on a server (Ubuntu example).

Prerequisites
- Node 20+ and npm
- MongoDB connection (remote or local)
- Nginx for reverse proxy and SSL
- PM2 (recommended) to manage Node process

Environment
- Create a `.env` file in `backend/` with keys required by `src/config/db.js` and `server.js` (MONGO_URI, JWT_SECRET, PORT, EMAIL_*, PAYSTACK_* etc.).

Backend (systemd/PM2)
1. Install dependencies

```powershell
# On the server (Linux example shown for commands, adapt for Windows server)
cd /path/to/quickserve/backend
npm ci
```

2. Start with PM2 (recommended)

```powershell
# install pm2 globally
npm install -g pm2
# start app
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

3. Check logs

```powershell
pm2 logs quickserve-backend --lines 200
```

Nginx (reverse proxy)
- Proxy HTTP/HTTPS to the backend on PORT (default 5555).
- Example server block (Ubuntu) — place in `/etc/nginx/sites-enabled/quickserve` and enable.

```
server {
  listen 80;
  server_name yourdomain.com;

  location / {
    proxy_pass http://127.0.0.1:5555;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }

  location /event-frontend/ {
    alias /path/to/quickserve/event-frontend/;
    try_files $uri $uri/ =404;
  }
}
```

Then secure with certbot for HTTPS.

Frontend static files
- Serve `event-frontend/` with Nginx (see alias above) or from the backend (the backend already serves static files under `/public` and mounts event-frontend; ensure paths are correct).

Socket.IO notes
- Ensure Nginx passes WebSocket upgrades (see proxy_set_header lines above).
- If using a different port, set `BACKEND_HTTP`/`SOCKET_URL` in `event-frontend/js/env-config.js` or let the frontend auto-detect.

Runtime tips
- Use `pm2 restart quickserve-backend` after env changes.
- Check `GET /health` for health status.

If you want, I can generate a systemd unit file, a sample `nginx` config with SSL, and a One-Click deploy PowerShell script for Windows servers. Let me know your target host OS.