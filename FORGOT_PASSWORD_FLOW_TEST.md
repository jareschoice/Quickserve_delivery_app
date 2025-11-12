# QuickServe Forgot Password Flow — Local Test Guide

Use this to validate the end-to-end reset flow without changing any backend code.

## Prereqs
- Backend running on http://127.0.0.1:5555 (as per `backend/server.js` default)
- `.env` in `backend/` with email credentials (for real email delivery):
  - EMAIL_HOST, EMAIL_PORT, EMAIL_SECURE, EMAIL_USER, EMAIL_PASS, EMAIL_FROM
  - JWT_SECRET, MONGO_URI, PORT=5555
- Event frontend served statically (e.g., http://localhost:8080) or via backend mount at `/event-frontend`.

Note: The backend also mounts the static `event-frontend` at `/event-frontend`. You can open:
- Forgot:  http://127.0.0.1:5555/event-frontend/forgot-password.html
- Reset:   http://127.0.0.1:5555/event-frontend/reset-password.html?token=<token>

## Steps (Staff login page)
1) Open `event-frontend/login.html` (or via http server):
   - Click "Forgot Password?" → goes to `forgot-password.html`.
2) Enter the email used for that account and submit.
3) Check your inbox for the reset email; click the link.
4) The link opens `reset-password.html?token=...` where you can set a new password.

## Steps (Customer sign-in page)
1) Open `event-frontend/signin.html`.
2) Click "Forgot Password?" → `forgot-password.html`.
3) Follow the same flow as above.

## Steps (Admin Panel)
1) Start admin panel (`admin-panel/` → `npm run dev`).
2) Visit the login screen. Under the password field, click "Forgot Password?".
   - This opens the backend-served page: `http://127.0.0.1:5555/event-frontend/forgot-password.html`.
3) Complete the email + token reset flow as above.

## Troubleshooting
- Server exits on start (Exit Code 1): ensure `backend/.env` contains `MONGO_URI` and other required keys. See `backend/README.md`.
- No email received: verify `EMAIL_*` config and SMTP reachability. For local-only validation, you can still test the reset page by visiting `reset-password.html?token=<token>` with a valid token (from DB) if available.
- Ports mismatch: backend default is 5555; event-frontend local server often uses 8080.
- CORS: Not applicable for navigating to the static pages; API calls in those pages target `http://127.0.0.1:5555/api`.

## Relevant files
- Frontend pages:
  - `event-frontend/forgot-password.html` → POST `/api/auth/forgot-password`
  - `event-frontend/reset-password.html` → POST `/api/auth/reset-password/:token`
  - `event-frontend/signin.html` → has "Forgot Password?" link
  - `event-frontend/login.html` → now includes "Forgot Password?" link for staff
- Admin panel:
  - `admin-panel/src/pages/Login.jsx` → added link that opens the same forgot page
- Backend routes (mounted):
  - `/api/auth` for auth, including `forgot-password` and `reset-password/:token`
