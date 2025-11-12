# Copilot instructions for QuickServe_delivery_app

These rules make AI agents productive in this monorepo. Keep guidance concrete and specific to this codebase.

## Big picture
- Monorepo with Node/Express backend (`backend/`), web admin (`admin-panel/` React+Vite), an event web frontend (`event-frontend/` static HTML/JS), and Flutter apps (`frontend/`, `QuickVendor/`, `quickride/`).
- Backend exposes both legacy v1 routes (e.g., `/auth`, `/vendors`) and the consolidated v2 API under `/api/*` (preferred). Socket.IO is used for realtime order/dispatcher updates.
- Backends serve health at `/health`, static files under `/public`, and mounts `event-frontend` at `/event-frontend`.

## How to run locally (Windows dev default)
- Backend: from `backend/` use `npm ci` then `npm run dev` (nodemon) or `npm start`. Server binds to `0.0.0.0` on `PORT` (default 5555). Health: `GET /health`.
- Quick start helpers: `QUICK_START.ps1` and `RUN_TESTS.ps1` automate deps, test-data, and launch of a simple static server for `event-frontend` on port 8080.
- Admin panel: from `admin-panel/` run `npm install` then `npm run dev` (Vite, default http://localhost:3000). Requires an admin user: run `node backend/create-admin.js`.
- Flutter apps: use `BUILD-APPS.ps1` or `BUILD_ALL_APPS.ps1` in repo root to build three APK targets: consumer (`lib/consumer_main.dart`), vendor (`lib/vendor_main.dart`), rider (`lib/rider_main.dart`).

## Environment and connectivity
- Put `.env` in `backend/` root; loaded by `server.js` and `src/config/db.js`. Required keys: `MONGO_URI`, `JWT_SECRET`, `PAYSTACK_*`, `EMAIL_*`, `PORT` (see `backend/README.md`).
- LAN testing from a phone: follow `docs/lan-connectivity.md` (bind 0.0.0.0, firewall rule on 5555, use LAN IP the server prints, allow cleartext in Android debug). Socket and HTTP share the same host/port.

## Auth, email, and password flows
- Registration and login live under `/api/auth` (`src/routes/auth.routes.js`).
- Email verification: `GET /api/auth/verify-email/:token` marks `isVerified=true`.
- Password reset: `POST /api/auth/forgot-password` sends a link that uses `FRONTEND_URL` (defaults to `http://127.0.0.1:5500/event-frontend`) to `reset-password.html`; `POST /api/auth/reset-password/:token` completes the reset.

## API and route conventions
- Prefer v2 namespaced routes mounted in `server.js`:
  - Auth `/api/auth` (file: `src/routes/auth.routes.js`), Products `/api/products`, Orders `/api/orders`, Payments `/api/payments`, Vendors `/api/vendors`, Riders `/api/riders`, Admin `/api/admin`, KYC `/api/kyc`, Notifications `/api/notifications`, Webhooks `/api/paystack`.
  - Event system extras: Dispatchers `/api/dispatchers`, Reviews `/api/reviews`.
- Legacy v1 routes remain for backward compatibility (`/auth`, `/vendors`, `/riders`, `/payments`, `/api/email`). Do not reintroduce `orders` under v1 (comment notes intentionally removed).
- Health, not-found, and error handlers are already wired; add new routers via `app.use('/api/<name>', router)` and export routers from `src/routes/*`.

## Data, payments, and status flows
- MongoDB via Mongoose; connection is centralized in `src/config/db.js` (`connectToMongoDB()` with retry and exit on failure). Use `process.env.MONGO_URI`.
- Order lifecycle: `pending → accepted → preparing → ready → out_for_delivery → delivered`. Real-time updates use Socket.IO rooms (`order:<id>`, `role:<role>`, `admin_room`).
- Payment best-practice: initialize payment first, verify via webhook, then mark order as placed. See `backend/PAYMENT_FLOW_DOCUMENTATION.md` for the current gap and recommended endpoints.

## Socket.IO patterns
- Rooms and identities: join `user:<id>`, `role:<role>`, `order:<id>` as needed. Admin listeners use `admin_room`.
- Emit examples: `io.to(\`order:${orderId}\`).emit('order:updated', payload)`; broadcast admin events with `io.to('admin_room').emit('user:online', data)`.
- Handlers live in `src/socketHandlers.js`; additional inline listeners are set up in `server.js`.

## Testing and diagnostics
- Postman collection: `backend/QuickServe_Postman_Collection.json` (and root `QuickServe-API-Postman-Collection.json`).
- Tiny health checks: `GET /`, `GET /health` return service and Mongo status.
- Sample scripts: `backend/create-event-test-data.js`, `setup-test-vendors.js`, `setup-test-dispatchers.js`, `test_mongo_ping.cjs`.

## CI and automation
- Backend CI: `.github/workflows/backend-ci.yml` (Node 20, `npm ci`, optional `lint/test/build`).
- Flutter CI: `.github/workflows/flutter-ci.yml` (stable channel, `flutter analyze`, tests if present).

## Gotchas
- Port mismatch in docs: `server.js` defaults to `5555` (preferred). Some older docs say `5000`. Set `PORT` in `backend/.env` to align all clients.
- Env naming: use `MONGO_URI` (not `MONGODB_URI`). Missing it causes process exit in `src/config/db.js`.
- Static content: backend serves `public/` and mounts `/event-frontend`; avoid path conflicts when adding files.

## Patterns to follow (when adding code)
- Use ES modules (`"type": "module"`); import paths are relative. Keep new APIs under `/api/*` and colocate route/controller/model under `backend/src`.
- Respect CORS/helmet CSP already configured in `server.js` (note the allowed `connectSrc` for 5555). If you add new frontends/ports, extend CSP and CORS origins.
- When integrating Socket.IO events, prefer room-based broadcasts and reuse existing room keys (`order:<id>`, `user:<id>`, `role:<role>`). Wire new listeners in `src/socketHandlers.js`.
- For admin features, prefer building against `admin-panel/` routes already documented in `admin-panel/README.md` (`/api/admin/*`, `/api/kyc/verify`).

## Examples from this repo
- New API router pattern: see `backend/src/routes/product.routes.js` and how it’s mounted in `server.js` at `/api/products`.
- Scripted setup flows: `QUICK_START.ps1` asks for `.env`, installs deps, optionally seeds 20 vendors + 10 dispatchers, and suggests serving `event-frontend` via `http-server`.
- LAN prints: server logs `http://<LAN-IP>:5555` at startup for phone testing.

## Branching and PRs
- Branches: `main` (release), `develop` (integration), and feature branches `feat/<name>` or `fix/<name>` → PR to `develop`.

If anything here is unclear or missing (e.g., exact v2 endpoints you want emphasized, or additional workflows you rely on), tell me and I’ll refine these rules.