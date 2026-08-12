# Data Entities

Current data model for the MVP. `User` below matches the live `connectappbe/prisma/schema.prisma` — everything else is still a planning reference and may shift once implemented.

---

## User

Core identity + auth record. Email + password auth (implemented) — no email verification, OTP, or gov-email gate in this pass; see [FEATURES.md](FEATURES.md) for that as a deferred item.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| email | string | Unique, used for signup/login |
| password_hash | string | bcrypt hash, never returned by the API |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## Profile

Public-facing professional profile, one-to-one with User.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| user_id | UUID | FK → User, unique |
| name | string | |
| photo_url | string | Nullable — profile photo, optional at signup |
| designation | string | e.g. "District Magistrate" |
| service | enum/string | IAS / IPS / IFS / State Service / etc. |
| department | string | |
| state_or_cadre | string | |
| years_in_service | integer | |
| bio | string | Short bio, nullable |
| created_at | timestamp | |
| updated_at | timestamp | |

---

## Connection

Represents a connection request between two users and its state.

| Field | Type | Notes |
|---|---|---|
| id | UUID | Primary key |
| requester_id | UUID | FK → User |
| recipient_id | UUID | FK → User |
| status | enum | `pending` / `accepted` / `declined` |
| created_at | timestamp | |
| updated_at | timestamp | |

Notes:
- Unique constraint on (requester_id, recipient_id) to prevent duplicate requests.
- "My Network" view = all Connections where status = accepted and the current user is either requester or recipient.

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
- `VerificationDocument` — document upload for manual admin approval (Phase 2)
- `AdminAction` / audit log (Phase 4)
- `PostReaction` / `Comment` (Phase 3)
- `Message` / `Conversation` for direct messaging (Phase 3)

---

*Bring this to standup as the current source of truth for what tables/models the backend needs — update it as the Prisma schema evolves.*
