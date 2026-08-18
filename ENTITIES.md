# Data Entities

Current data model for the MVP. `User`, `Profile`, `Connection`, and `Post` below all match the live `connectappbe/prisma/schema.prisma`.

---

## User

Core identity + auth record, plus the admin-approval state machine. Email + password auth and an ID card photo captured at signup, which an admin now reviews via `/admin/*` (implemented). No email verification, OTP, or gov-email gate; see [FEATURES.md](FEATURES.md) for those as deferred items.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| email | string | Unique, used for signup/login |
| password_hash | string | bcrypt hash, never returned by the API |
| id_card_photo_url | string | Cloudinary URL, uploaded server-side at signup. **Nullable** — only because seeded admin accounts have no ID card; signup still rejects a request without one. Returned **only** on `/admin/*` responses |
| role | enum (`user_role`) | `user` / `admin`, default `user`. Admins are seeded (`prisma/seed.js`), never created through signup |
| status | enum (`user_status`) | `pending` / `approved` / `rejected`, default `pending`. Gates every app feature |
| rejection_reason | string | Nullable — optional admin note, ≤500 chars. Cleared on approve |
| reviewed_at | timestamp | Nullable — stamped on each approve/reject |
| reviewed_by_id | UUID | Nullable — the reviewing admin's id. Deliberately **not** a FK: deleting an admin must neither cascade into nor block the applicants they reviewed |
| created_at | timestamp | |
| updated_at | timestamp | |

Notes:
- `status` is read from this row on every gated request, never from the JWT — a 7-day token stamped `pending` at signup would otherwise keep an approved user locked out until re-login.
- Seeded admins are created `status = approved`, so an admin never has to approve itself.
- The `(role, status)` index backs the `GET /admin/users?status=…` review queue.
- Pre-existing users are grandfathered to `approved` by `prisma/sql/005_add_admin_approval.sql`, so the change doesn't lock out accounts created before approval existed.

---

## Profile

Public-facing professional profile, one-to-one with User. Created together with User in the same signup request; editable afterward via `PUT /profile/me` (implemented — `GET/PUT /profile/*`, see [API_CONTRACT.md](API_CONTRACT.md)).

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| user_id | UUID | FK → User, unique |
| name | string | Required |
| photo_url | string | Nullable — Cloudinary URL, optional at signup |
| designation | string | Required, e.g. "District Magistrate" |
| service | string | Required, e.g. IAS / IPS / IFS / State Service |
| department | string | Required |
| state_or_cadre | string | Required |
| years_in_service | integer | Required |
| bio | string | Optional |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## Connection

Represents a connection request between two users and its state (implemented — `GET/POST/DELETE /connections/*`, see [API_CONTRACT.md](API_CONTRACT.md)).

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| requester_id | UUID | FK → User |
| recipient_id | UUID | FK → User |
| status | enum (`connection_status`) | `pending` / `accepted` / `declined` |
| created_at | timestamp | |
| updated_at | timestamp | |

Notes:
- Unique constraint on (requester_id, recipient_id) — but request creation also checks the reverse pair `(recipient_id, requester_id)` in application code, so only one `Connection` row can ever exist between two users regardless of direction.
- DB check constraint `requester_id <> recipient_id` — can't connect to yourself.
- Any existing row (any status) blocks a new request between the same pair, **unless** it's deleted first via `DELETE /connections/:connectionId` — the row must be explicitly removed to re-request; there's no separate "reset" operation.
- `DELETE /connections/:connectionId`: `pending` → only the requester may delete (cancel their own outgoing request); `accepted`/`declined` → either party may delete.
- "My Network" view (`GET /connections`) = all Connections where status = accepted and the current user is either requester or recipient.

---

## Post

Feed post authored by a user: text + an optional photo (implemented — `GET/POST /feed`, see [API_CONTRACT.md](API_CONTRACT.md)).

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| author_id | UUID | FK → User |
| content | text | Required, 1-2000 chars (trimmed) |
| photo_url | text | Nullable — Cloudinary URL, optional per post |
| created_at | timestamp | Used for chronological feed ordering |
| updated_at | timestamp | |

Notes:
- No likes/comments tables in MVP (explicitly out of scope) — feed reads are author + connections only.
- Feed query (`GET /feed`) = Posts where author_id is in the current user's accepted Connections, **plus the current user's own posts**.

---

## Relationships Summary

```
User 1---1 Profile
User 1---N Post (as author)
User 1---N Connection (as requester)
User 1---N Connection (as recipient)
```

---

## Deferred / Not in MVP Schema

These were considered but are out of scope per the current MVP (see [FEATURES.md](FEATURES.md)):

- Gov-email OTP/magic-link verification fields on `User` (`gov_email`, `is_gov_email_verified`) — cut from this pass along with the badge, may return as a later access-gate design
- A verified badge on public profiles — `status` gates access, but nothing surfaces it on `GET /profile/:id` or in the directory
- `AdminAction` / audit log (Phase 4) — `User.reviewed_at` / `reviewed_by_id` record only the *latest* decision, not a history
- Self-service admin creation/promotion — admins exist only via the seed script
- `PostReaction` / `Comment` (Phase 3)
- `Message` / `Conversation` for direct messaging (Phase 3)

---

*Bring this to standup as the current source of truth for what tables/models the backend needs — update it as the Prisma schema evolves.*
