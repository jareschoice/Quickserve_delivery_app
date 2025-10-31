# Quickserve_delivery_app

Food delivery app (monorepo: Node/Express backend + Flutter apps)

![Backend CI](https://github.com/jareschoice/Quickserve_delivery_app/actions/workflows/backend-ci.yml/badge.svg)
![Flutter CI](https://github.com/jareschoice/Quickserve_delivery_app/actions/workflows/flutter-ci.yml/badge.svg)

## Repo layout

- `backend/` — Node.js/Express API, MongoDB/Mongoose, Socket.IO
- `frontend/` — Flutter app(s) with role-based flows (consumer/vendor/rider)
- `quickride/`, `QuickVendor/`, `quickride/android` — platform-specific or legacy app modules

## Branching model

- `main` — protected, release-ready
- `develop` — integration branch for active work
- feature branches — `feat/<short-name>`, `fix/<short-name>` → PR into `develop`

## Local development

Backend
- Node 20+ recommended
- From `backend/`: `npm ci`; start server as per `package.json` scripts (dev/prod)

Flutter
- Flutter stable channel
- From `frontend/`: `flutter pub get`; `flutter run` (pick flavor/target as needed)

Connectivity guides
- See `docs/lan-connectivity.md` to make the phone reach your PC backend over LAN.

## CI

GitHub Actions run on pushes and PRs:
- Backend CI: install, lint, test, build (if scripts present)
- Flutter CI: `pub get`, `analyze`, tests (if present)

## Contributing and where to “chat”

Use GitHub as the source of truth for all conversations:
- Questions / help: open an Issue with label `question`
- Features / proposals: open an Issue (Feature request template)
- Code review discussion: continue in PR comments
- Longer threads: enable Discussions in repo settings (Settings → General → Features → Discussions), then use the Q&A category

See `CONTRIBUTING.md` for the workflow and conventions.

## Security

Do not commit secrets. Use environment variables and `.env` files locally (ignored by git). If a token was exposed, rotate it immediately in GitHub.

## License

TBD
