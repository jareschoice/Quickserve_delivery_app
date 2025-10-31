# LAN connectivity guide (phone ↔ PC backend)

Use this checklist to make your Android device reach the backend on your Windows PC.

## 1) Confirm server is listening on all interfaces
- In `backend/server.js`, ensure it binds to `0.0.0.0` (not `127.0.0.1`).
- Start server and note the LAN IP and port (e.g., `http://192.168.x.x:5555`).

## 2) Put PC network on Private profile
- Windows Settings → Network & Internet → Properties of your Wi‑Fi/Ethernet → set Network profile = Private.

## 3) Allow inbound port in Windows Firewall
- Windows Security → Firewall & network protection → Advanced settings → Inbound Rules → New Rule…
  - Rule type: Port → TCP → Specific local ports: 5555 → Allow → Profile: Private → Name: QuickServe 5555.

## 4) Verify phone can reach the server
- On the phone, connect to the same Wi‑Fi SSID as the PC.
- Open the mobile browser → visit `http://<PC-LAN-IP>:5555`.
  - If it loads, LAN is reachable.
  - If it times out, re-check firewall (step 3) and IP.

## 5) Android app allowances (Flutter)
- AndroidManifest: include `<uses-permission android:name="android.permission.INTERNET"/>`.
- For HTTP (non-HTTPS) during LAN tests, set `android:usesCleartextTraffic="true"`.

## 6) App base URL wiring
- Ensure the Flutter app points to the LAN base URL.
  - We use a SharedPreferences override (key: `api_base_override`), set at app start.
  - Verify device logs: it should print the resolved API base.

## 7) Socket.IO alignment
- Socket client should use the same base host and port as HTTP.
- Confirm logs show the socket endpoint using the LAN host.

## 8) Quick diagnostics
- From the PC: `curl http://0.0.0.0:5555/health` (or your health endpoint) to confirm local.
- From the phone: browser → `http://<PC-LAN-IP>:5555/health`.
- If only sockets fail, check CORS and Transport (polling/websocket) and that port 5555 isn’t blocked by router AP isolation.

## 9) Router/AP isolation
- Some routers isolate devices on Wi‑Fi (client isolation). Disable AP/client isolation or use another network.

## 10) After testing
- You can revert cleartext to false before production builds, or keep it only on debug/profiling flavors.
