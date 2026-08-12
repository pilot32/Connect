# Data Entities

Current data model for the MVP. `User`, `Profile`, and `Connection` below match the live `connectappbe/prisma/schema.prisma` — `Post` is still a planning reference and may shift once implemented.

---

## User

Core identity + auth record. Email + password auth, plus an ID card photo captured at signup for future verification review (implemented) — no email verification, OTP, gov-email gate, or admin review of the ID card in this pass; see [FEATURES.md](FEATURES.md) for those as deferred items.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| email | string | Unique, used for signup/login |
| password_hash | string | bcrypt hash, never returned by the API |
| id_card_photo_url | string | Cloudinary URL, uploaded server-side at signup. Required. Private — never returned in API responses; nothing reviews it yet |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## Profile

Public-facing professional profile, one-to-one with User. Created together with User in the same signup request (implemented).

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

Represents a connection request between two users and its state (implemented — `GET/POST /connections/*`, see [API_CONTRACT.md](API_CONTRACT.md)).

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
- Re-requesting after a decline isn't supported yet — any existing row (any status) blocks a new request between the same pair.
- "My Network" view (`GET /connections`) = all Connections where status = accepted and the current user is either requester or recipient.

---

## Post

Text-only feed post authored by a user.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| author_id | UUID | FK → User |
| content | text | Text content, no rich media in MVP |
| created_at | timestamp | Used for chronological feed ordering |
| updated_at | timestamp | |

Notes:
- No likes/comments tables in MVP (explicitly out of scope) — feed reads are author + connections only.
- Feed query = Posts where author_id is in the current user's accepted Connections (+ optionally self).

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
- Manual admin approval / review workflow for `id_card_photo_url` (the photo is captured and stored at signup, but nothing reviews it or sets a verified status yet) (Phase 2)
- `AdminAction` / audit log (Phase 4)
- `PostReaction` / `Comment` (Phase 3)
- `Message` / `Conversation` for direct messaging (Phase 3)

---

*Bring this to standup as the current source of truth for what tables/models the backend needs — update it as the Prisma schema evolves.*
