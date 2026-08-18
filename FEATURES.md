# Feature Backlog

Post-MVP feature ideas, organized by phase. Current MVP scope lives in [README.md](README.md) — this list is for planning what comes after Week 1.

---

## Phase 2 (Post-MVP Stabilization)

Things that were explicitly deferred from MVP and are the most likely next additions.

### Backend
- ~~Manual admin review/approval workflow for the ID card photo captured at signup~~ — **done**: `/admin/users` list + approve/reject, `requireApproved` gate, `GET /auth/status`. See [API_CONTRACT.md](API_CONTRACT.md#admin). Still open from this item: an admin *panel* (reviewers currently drive the API directly), and admin creation beyond `prisma/seed.js`
- Audit history of review decisions — `User.reviewed_at`/`reviewed_by_id` keep only the latest decision, not a log
- "Verified" / "Pending" status field on **profiles**, surfaced via API — `User.status` gates access but is never exposed on another user's public profile
- Real OTP provider integration (Twilio or MSG91) replacing hardcoded/mock OTP
- Rate limiting on OTP request endpoints (abuse prevention)
- Pagination on directory search and feed endpoints
- Soft-delete / account deactivation

### Frontend
- Verification status UI (pending/verified indicator)
- Pull-to-refresh and infinite scroll on feed and directory
- Offline handling / retry queue for failed requests (connectivity_plus is already declared)
- Basic onboarding flow (multi-step profile creation)

---

## Phase 3 (Engagement Features)

- Direct messaging between connections
- Likes / reactions on posts
- Comments on posts
- Rich media posts (images, later video)
- Push notifications (connection requests, new posts from network)
- Post editing / deletion

---

## Phase 4 (Trust & Compliance)

- Aadhaar / DigiLocker government ID verification (requires API access + compliance review)
- Report / block user
- Content moderation tooling for admins
- Audit log of admin actions (approvals, removals)

---

## Phase 5 (Platform Growth)

- iOS build
- Web admin dashboard (dedicated app, not bare-bones page)
- Advanced directory filters (years in service, cadre batch, cross-department search)
- Officer "suggested connections" (same department/state/service)
- Export/download own data
- Multi-language support

---

## Cross-cutting / Infra (any phase, as needed)

- CI/CD pipeline for backend deploys
- Structured logging + error monitoring (e.g. Sentry)
- API request validation coverage audit (zod schemas per endpoint)
- Backend test suite (unit + integration)
- Flutter widget/integration test suite
- Analytics (basic usage metrics, privacy-conscious)

---

*Use this list to pick what goes into the next sprint — nothing here is committed until pulled into an active milestone.*
