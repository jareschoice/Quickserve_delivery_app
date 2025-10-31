# Contributing

We use GitHub for all collaboration: Issues for tasks/questions, pull requests for changes, and (optionally) Discussions for longer threads.

## Branches
- `main`: release-ready, protected
- `develop`: integration branch
- Feature branches: `feat/<short-name>`, `fix/<short-name>`

## Workflow
1. Create an Issue (bug/feature/question) and describe the scope and acceptance criteria.
2. Create a branch off `develop`: `feat/<short-name>`.
3. Commit changes with conventional commits (e.g., `feat: add vendor packaging UI`).
4. Push and open a PR into `develop`. Fill the PR template, link the Issue.
5. CI must pass (Backend CI / Flutter CI). Request review.
6. Merge with squash/rebase as preferred. Periodically PR `develop` → `main` for releases.

## Where to talk
- Questions: open an Issue using the “Bug/Question” template and label `question`.
- Feature ideas: open a Feature request Issue.
- Code discussion: use PR comments and reviews.
- Longer/lighter topics: enable Discussions in repo settings, then use the appropriate category.

## Local dev quickstart
- Backend: Node 20+, `cd backend && npm ci`, run dev script.
- Flutter: stable channel, `cd frontend && flutter pub get && flutter analyze && flutter run`.

## Commit style
- Conventional commits recommended: `feat|fix|chore|docs|refactor|test: ...`

## Security
- Never commit secrets. Use env files locally (gitignored). Rotate any leaked tokens.
