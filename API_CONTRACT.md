# API Contract

Base URL (local dev): `http://localhost:3000`

Covers the currently implemented endpoints: auth, admin, profile, connections, directory, feed.

All endpoints below except `POST /auth/signup` and `POST /auth/login` require `Authorization: Bearer <token>` (see Notes at the bottom of the Auth section).

## Account approval — read this first

Every signup lands in `status: "pending"` and stays locked out of the app until an admin approves it. Two gates enforce this:

| Gate | Applies to | On failure |
|---|---|---|
| `requireAuth` | everything except signup/login | `401` |
| `requireApproved` | `/profile`, `/connections`, `/directory`, `/feed` | `403` with `code` `ACCOUNT_PENDING` or `ACCOUNT_REJECTED` |

`POST /auth/signup`, `POST /auth/login` and `GET /auth/status` are **not** gated by `requireApproved` — a pending user must still be able to sign in and watch for a decision. `/admin/*` is gated by `requireAdmin` instead.

**The gate reads the database, not the token.** A token issued at signup carries `"status": "pending"` for its full 7-day life. If the gate trusted that claim, an approved user would stay locked out until they logged in again. It re-reads the user row on every request instead, so approval takes effect on the user's very next call with the token they already hold. The `role`/`status` claims inside the JWT are a convenience snapshot for client-side routing only — never a source of truth.

Admin accounts bypass `requireApproved` entirely (they are reviewers, not applicants).

**`403` account-gate response shapes**

```json
{ "error": "Your account is awaiting admin approval", "code": "ACCOUNT_PENDING" }
```
```json
{
  "error": "Your account was not approved",
  "code": "ACCOUNT_REJECTED",
  "rejectionReason": "ID card photo is unreadable"
}
```
`rejectionReason` is `null` when the admin rejected without giving one.

**The `user` object** returned by signup, login, and `GET /auth/status` is the same shape everywhere:

| Field | Type | Notes |
|---|---|---|
| id | string (uuid) | |
| email | string | only ever returned for the requester's own account |
| role | `"user"` \| `"admin"` | |
| status | `"pending"` \| `"approved"` \| `"rejected"` | |
| rejectionReason | string \| null | non-null only while `status` is `"rejected"`, and only if the admin supplied one |
| createdAt | string (ISO 8601) | |

`idCardPhotoUrl` is never in this object — it is returned **only** on `/admin/*` responses.

---

# Auth

---

## POST /auth/signup

Creates a new user with email + password, full profile details, and an ID card photo for verification. Profile photo, ID card photo, and Cloudinary upload happen server-side as part of this request.

The account is created with `role: "user"` and `status: "pending"` — the returned token is valid, but every app feature returns `403 ACCOUNT_PENDING` until an admin approves it.

**Headers**
```
Content-Type: multipart/form-data
```

**Request body** (`multipart/form-data` fields)
| Field | Type | Rules |
|---|---|---|
| email | string (text field) | must be a valid email |
| password | string (text field) | minimum 8 characters |
| name | string (text field) | required |
| designation | string (text field) | required, e.g. "District Magistrate" |
| service | string (text field) | required, e.g. "IAS" |
| department | string (text field) | required |
| stateOrCadre | string (text field) | required |
| yearsInService | string (text field, numeric) | required, coerced to a non-negative integer |
| bio | string (text field) | optional |
| idCardPhoto | file | **required** — image only (any `image/*` mimetype), max 5MB, uploaded to Cloudinary |
| profilePhoto | file | optional — image only, max 5MB, uploaded to Cloudinary |

Example (curl):
```
curl -X POST http://localhost:3000/auth/signup \
  -F "email=officer@example.com" \
  -F "password=password123" \
  -F "name=Test Officer" \
  -F "designation=District Magistrate" \
  -F "service=IAS" \
  -F "department=Revenue" \
  -F "stateOrCadre=Karnataka" \
  -F "yearsInService=5" \
  -F "bio=Optional short bio" \
  -F "idCardPhoto=@id_card.jpg;type=image/jpeg" \
  -F "profilePhoto=@profile.jpg;type=image/jpeg"
```

**Responses**

`201 Created` — account + profile created, awaiting review
```json
{
  "token": "<jwt>",
  "user": {
    "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
    "email": "officer@example.com",
    "role": "user",
    "status": "pending",
    "rejectionReason": null,
    "createdAt": "2026-08-17T14:04:00.845Z"
  },
  "profile": {
    "name": "Test Officer",
    "photoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/profile-photos/xyz.png",
    "designation": "District Magistrate",
    "service": "IAS",
    "department": "Revenue",
    "stateOrCadre": "Karnataka",
    "yearsInService": 5,
    "bio": "Optional short bio"
  }
}
```
Note: `photoUrl` is `null` if `profilePhoto` wasn't sent. The ID card photo URL (`idCardPhotoUrl`) is stored on the user but is **not** returned in this or any response — it's a private verification asset, not a public profile field.

`400 Bad Request` — validation failed. Three distinct causes share this status:
- Missing/invalid text fields (zod validation)
  ```json
  {
    "error": "Invalid signup details",
    "details": [
      { "code": "invalid_type", "expected": "string", "received": "undefined", "path": ["name"], "message": "Required" }
    ]
  }
  ```
- Missing `idCardPhoto` file
  ```json
  { "error": "ID card photo is required" }
  ```
- Non-image file uploaded for `idCardPhoto`/`profilePhoto`, or file over 5MB
  ```json
  { "error": "Only image uploads are allowed" }
  ```

`409 Conflict` — email already registered
```json
{
  "error": "Email is already registered"
}
```

`500 Internal Server Error` — unexpected failure (e.g. DB unreachable, Cloudinary upload failure); internal details are logged server-side only, never returned to the client
```json
{
  "error": "Internal server error"
}
```

---

## POST /auth/login

Authenticates an existing user with email + password. Works for admin accounts too — the same endpoint, distinguished by `user.role` in the response.

Pending and rejected accounts **can** log in: they need a token to poll `GET /auth/status`. Login is not where the approval gate lives.

**Headers**
```
Content-Type: application/json
```

**Request body**
| Field | Type | Rules |
|---|---|---|
| email | string | must be a valid email |
| password | string | minimum 8 characters |

```json
{
  "email": "officer@example.com",
  "password": "password123"
}
```

**Responses**

`200 OK` — authenticated
```json
{
  "token": "<jwt>",
  "user": {
    "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
    "email": "officer@example.com",
    "role": "user",
    "status": "approved",
    "rejectionReason": null,
    "createdAt": "2026-08-17T14:04:00.845Z"
  },
  "profile": {
    "name": "Test Officer",
    "photoUrl": null,
    "designation": "District Magistrate",
    "service": "IAS",
    "department": "Revenue",
    "stateOrCadre": "Karnataka",
    "yearsInService": 5,
    "bio": "Optional short bio"
  }
}
```
`profile` is `null` for admin accounts, which have no profile row:
```json
{
  "token": "<jwt>",
  "user": {
    "id": "c6804a74-97a3-4989-ba22-97eed48b7c69",
    "email": "admin@govconnect.in",
    "role": "admin",
    "status": "approved",
    "rejectionReason": null,
    "createdAt": "2026-08-17T14:02:31.646Z"
  },
  "profile": null
}
```

`400 Bad Request` — validation failed (same shape as signup's 400)
```json
{
  "error": "Invalid email or password",
  "details": [
    {
      "code": "too_small",
      "minimum": 8,
      "type": "string",
      "inclusive": true,
      "exact": false,
      "message": "String must contain at least 8 character(s)",
      "path": ["password"]
    }
  ]
}
```

`401 Unauthorized` — email not found, or password doesn't match. Deliberately the same message for both cases, so the API doesn't reveal whether an email is registered.
```json
{
  "error": "Invalid email or password"
}
```

`500 Internal Server Error` — same shape as signup's 500
```json
{
  "error": "Internal server error"
}
```

---

## GET /auth/status

The authenticated user's **current** account state, read fresh from the database. This is how the app learns it has been approved without forcing a logout/login: the token's `status` claim is frozen at sign-in, this endpoint is not.

Requires `Authorization: Bearer <token>`. Deliberately **not** gated by `requireApproved` — a pending user is exactly who needs to call it. Poll it on app resume and from the "awaiting approval" screen.

**Request body** — none.

**Responses**

`200 OK` — still waiting
```json
{
  "user": {
    "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
    "email": "officer@example.com",
    "role": "user",
    "status": "pending",
    "rejectionReason": null,
    "createdAt": "2026-08-17T14:04:00.845Z"
  },
  "profile": {
    "name": "Approval Test Officer",
    "photoUrl": null,
    "designation": "District Magistrate",
    "service": "IAS",
    "department": "Revenue",
    "stateOrCadre": "Karnataka",
    "yearsInService": 5,
    "bio": "Signed up for the approval test"
  }
}
```

`200 OK` — rejected, with the admin's reason for display
```json
{
  "user": {
    "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
    "email": "officer@example.com",
    "role": "user",
    "status": "rejected",
    "rejectionReason": "ID card photo is unreadable",
    "createdAt": "2026-08-17T14:04:00.845Z"
  },
  "profile": { "...": "same shape as above" }
}
```

`200 OK` — approved; the client can now move into the app on the token it already has.

`401 Unauthorized` — missing/invalid token, or the account no longer exists
```json
{ "error": "Missing token" }
```
```json
{ "error": "Invalid or expired token" }
```

`profile` is `null` for admin accounts.

---

## Notes

- `token` is a JWT signed with `JWT_SECRET`, payload `{ sub: <user id>, email, role, status }`, expires in 7 days. Send it as `Authorization: Bearer <token>` on every endpoint outside signup/login.
- **`role` and `status` in the token are a sign-in-time snapshot, for client-side routing only.** The server re-reads both from the database on every gated request, so a stale claim can never widen access — and an approval never requires a re-login. Use `GET /auth/status` for the authoritative value.
- `password_hash` is never returned in any response.
- No email verification, OTP, or gov-email gate on signup/login — see [FEATURES.md](FEATURES.md).
- Login (`POST /auth/login`) is still plain `application/json` with just `email`/`password`; it now returns `profile` alongside `user`.
- The ID card photo captured at signup is reviewed by an admin via `/admin/*` (below). There is still no verified badge on public profiles.

---

# Admin

The approval console. Every endpoint below requires `Authorization: Bearer <token>` for an account with `role: "admin"` — `requireAuth` then `requireAdmin`, which re-reads the role from the database rather than trusting the token's claim.

Admin accounts are **seeded, not signed up** (`node prisma/seed.js`, credentials from `ADMIN_EMAIL` / `ADMIN_PASSWORD`). There is no endpoint that creates or promotes an admin. They log in through the normal `POST /auth/login`.

**Shared errors on every `/admin/*` endpoint**

`401 Unauthorized` — missing/invalid token, or the account no longer exists
```json
{ "error": "Missing token" }
```

`403 Forbidden` — a valid token for a non-admin account
```json
{ "error": "Admin access required", "code": "ADMIN_ONLY" }
```

## The applicant object

Returned by all four endpoints below. This is the **only** place `idCardPhotoUrl` is ever exposed — it's a private verification asset, and reviewing it is the point of this screen.

| Field | Type | Notes |
|---|---|---|
| id | string (uuid) | |
| email | string | |
| role | `"user"` | always — admins are never applicants |
| status | `"pending"` \| `"approved"` \| `"rejected"` | |
| idCardPhotoUrl | string \| null | Cloudinary URL of the ID card uploaded at signup |
| rejectionReason | string \| null | |
| reviewedAt | string (ISO 8601) \| null | `null` until first reviewed; overwritten on every approve/reject |
| reviewedById | string (uuid) \| null | the admin who last reviewed them |
| createdAt | string (ISO 8601) | when they applied |
| updatedAt | string (ISO 8601) | |
| profile | object \| null | same shape as everywhere else in this document |

```json
{
  "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
  "email": "officer@example.com",
  "role": "user",
  "status": "pending",
  "idCardPhotoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/id-cards/qaihfbaky97vp6f7uxc2.png",
  "rejectionReason": null,
  "reviewedAt": null,
  "reviewedById": null,
  "createdAt": "2026-08-17T14:04:00.845Z",
  "updatedAt": "2026-08-17T14:04:00.845Z",
  "profile": {
    "name": "Approval Test Officer",
    "photoUrl": null,
    "designation": "District Magistrate",
    "service": "IAS",
    "department": "Revenue",
    "stateOrCadre": "Karnataka",
    "yearsInService": 5,
    "bio": "Signed up for the approval test"
  }
}
```

## GET /admin/users

The review queue.

**Query params**
| Param | Type | Default | Notes |
|---|---|---|---|
| status | `pending` \| `approved` \| `rejected` \| `all` | `pending` | anything else is a `400`, not a silent fallback |

Admin accounts are excluded from every filter, including `all` — the list is applicants only.

Example: `GET /admin/users?status=pending`

**Responses**

`200 OK` — a bare array of applicant objects, **oldest first** (`createdAt` ascending: the review queue is worked front to back). Empty array when nothing matches — an empty queue is not a `404`.
```json
[
  {
    "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
    "email": "officer@example.com",
    "role": "user",
    "status": "pending",
    "idCardPhotoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/id-cards/qaihfbaky97vp6f7uxc2.png",
    "rejectionReason": null,
    "reviewedAt": null,
    "reviewedById": null,
    "createdAt": "2026-08-17T14:04:00.845Z",
    "updatedAt": "2026-08-17T14:04:00.845Z",
    "profile": { "...": "..." }
  }
]
```

`400 Bad Request` — unrecognised `status`
```json
{
  "error": "Invalid status filter — expected pending, approved, rejected or all",
  "details": [
    {
      "received": "bogus",
      "code": "invalid_enum_value",
      "options": ["pending", "approved", "rejected", "all"],
      "path": ["status"],
      "message": "Invalid enum value. Expected 'pending' | 'approved' | 'rejected' | 'all', received 'bogus'"
    }
  ]
}
```

No pagination yet.

## GET /admin/users/:id

One applicant, for the detail/review screen.

**Responses**

`200 OK` — a single applicant object (shape above).

`400 Bad Request` — `:id` isn't a valid UUID
```json
{ "error": "Invalid user id" }
```

`404 Not Found` — no such applicant. Passing an **admin's** id also returns `404`: an admin account isn't an applicant, so there is nothing here to show.
```json
{ "error": "User not found" }
```

## POST /admin/users/:id/approve

Approve an applicant. Takes effect immediately — on the user's *existing* token, no re-login needed.

**Request body** — none.

Sets `status = "approved"`, clears `rejectionReason` to `null`, and stamps `reviewedAt` / `reviewedById`. **Idempotent**, and doubles as the reconsider-a-rejection path: approving an already-approved or previously-rejected user succeeds and re-stamps the review fields.

Example (curl):
```
curl -X POST http://localhost:3000/admin/users/6c9bdf39-ea7c-4c93-97f1-69296a42e5ef/approve \
  -H "Authorization: Bearer <admin token>"
```

**Responses**

`200 OK` — the updated applicant object
```json
{
  "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
  "email": "officer@example.com",
  "role": "user",
  "status": "approved",
  "idCardPhotoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/id-cards/qaihfbaky97vp6f7uxc2.png",
  "rejectionReason": null,
  "reviewedAt": "2026-08-17T14:04:18.879Z",
  "reviewedById": "c6804a74-97a3-4989-ba22-97eed48b7c69",
  "createdAt": "2026-08-17T14:04:00.845Z",
  "updatedAt": "2026-08-17T14:04:19.006Z",
  "profile": { "...": "..." }
}
```

`400 Bad Request` / `404 Not Found` — same as `GET /admin/users/:id`.

## POST /admin/users/:id/reject

Reject an applicant, optionally with a reason shown to them.

**Headers**
```
Content-Type: application/json
```

**Request body** — optional; the endpoint accepts an empty body, `{}`, or no `Content-Type` at all.
| Field | Type | Rules |
|---|---|---|
| reason | string | optional — trimmed, 1-500 chars if sent. Omitted → `rejectionReason` is `null` |

```json
{ "reason": "ID card photo is unreadable" }
```

Sets `status = "rejected"`, stores `reason` (or `null`), and stamps `reviewedAt` / `reviewedById`. Idempotent.

Example (curl):
```
curl -X POST http://localhost:3000/admin/users/6c9bdf39-ea7c-4c93-97f1-69296a42e5ef/reject \
  -H "Authorization: Bearer <admin token>" \
  -H "Content-Type: application/json" \
  -d '{"reason":"ID card photo is unreadable"}'
```

**Responses**

`200 OK` — the updated applicant object
```json
{
  "id": "6c9bdf39-ea7c-4c93-97f1-69296a42e5ef",
  "email": "officer@example.com",
  "role": "user",
  "status": "rejected",
  "idCardPhotoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/id-cards/qaihfbaky97vp6f7uxc2.png",
  "rejectionReason": "ID card photo is unreadable",
  "reviewedAt": "2026-08-17T14:04:14.003Z",
  "reviewedById": "c6804a74-97a3-4989-ba22-97eed48b7c69",
  "createdAt": "2026-08-17T14:04:00.845Z",
  "updatedAt": "2026-08-17T14:04:14.131Z",
  "profile": { "...": "..." }
}
```
The rejected user's next call to a gated endpoint returns `403 ACCOUNT_REJECTED` carrying this `rejectionReason`.

`400 Bad Request` — invalid `:id` (`{ "error": "Invalid user id" }`), or a `reason` that is empty after trimming / over 500 chars
```json
{
  "error": "Invalid rejection reason",
  "details": [
    { "code": "too_big", "maximum": 500, "type": "string", "inclusive": true, "exact": false, "message": "String must contain at most 500 character(s)", "path": ["reason"] }
  ]
}
```

`404 Not Found` — `{ "error": "User not found" }`

---

# Profile

All endpoints below require `Authorization: Bearer <token>` **and** an approved account — an unapproved caller gets `403 ACCOUNT_PENDING` / `ACCOUNT_REJECTED` before the handler runs.

## GET /profile/me

The authenticated user's own profile.

**Responses**

`200 OK` — `user` is the same object described under [Account approval](#account-approval--read-this-first)
```json
{
  "user": {
    "id": "074c04eb-1e8c-4e63-97a6-fc2cc4f31683",
    "email": "officerA@example.com",
    "role": "user",
    "status": "approved",
    "rejectionReason": null,
    "createdAt": "2026-08-17T14:04:00.845Z"
  },
  "profile": {
    "name": "Officer A",
    "photoUrl": null,
    "designation": "DM",
    "service": "IAS",
    "department": "Revenue",
    "stateOrCadre": "Karnataka",
    "yearsInService": 5,
    "bio": null
  }
}
```

`401 Unauthorized` — missing/invalid token
```json
{ "error": "Missing token" }
```

`404 Not Found` — no profile exists for this user (shouldn't happen given signup always creates one, but a real code path)
```json
{ "error": "Profile not found" }
```

## PUT /profile/me

Partial update of the authenticated user's own profile. Only send the fields you want to change — omitted fields are left as-is.

**Headers**
```
Content-Type: multipart/form-data
```

**Request body** (`multipart/form-data` fields, all optional)
| Field | Type | Rules |
|---|---|---|
| name | string (text field) | non-empty if sent |
| designation | string (text field) | non-empty if sent |
| service | string (text field) | non-empty if sent |
| department | string (text field) | non-empty if sent |
| stateOrCadre | string (text field) | non-empty if sent |
| yearsInService | string (text field, numeric) | coerced to a non-negative integer if sent |
| bio | string (text field) | any string, including empty (clears the bio) |
| photo | file | optional — image only, max 5MB, uploaded to Cloudinary. If omitted, the existing `photoUrl` is left unchanged (there's no way to *clear* an existing photo yet, only replace it) |

At least one field or `photo` must be sent — an entirely empty request is rejected.

**Responses**

`200 OK` — same shape as `GET /profile/me`
```json
{
  "user": {
    "id": "93496c45-6fc8-47e4-894c-f45800879aed",
    "email": "putX@example.com",
    "role": "user",
    "status": "approved",
    "rejectionReason": null,
    "createdAt": "2026-08-17T14:04:00.845Z"
  },
  "profile": {
    "name": "Put X",
    "photoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/profile-photos/xyz.png",
    "designation": "Joint Secretary",
    "service": "IAS",
    "department": "Revenue",
    "stateOrCadre": "Karnataka",
    "yearsInService": 6,
    "bio": "Updated bio only"
  }
}
```

`400 Bad Request` — no fields sent, an empty/invalid value for a sent field, or a non-image/oversized `photo`
```json
{ "error": "Invalid profile update", "details": [ { "...": "zod issue, same shape as elsewhere" } ] }
```
```json
{ "error": "Only image uploads are allowed" }
```

`404 Not Found` — no profile exists for this user

## GET /profile/:id

Any other user's public profile, looked up by user id.

**Responses**

`200 OK` — same shape as `GET /profile/me`, but `user` only contains `{ "id" }` — **no email**. Email is the login credential and is only ever returned for the requester's own account.
```json
{
  "user": { "id": "421cadfb-8fd4-4141-bc33-0f6805dd29c5" },
  "profile": {
    "name": "Officer B",
    "photoUrl": null,
    "designation": "SP",
    "service": "IPS",
    "department": "Police",
    "stateOrCadre": "Maharashtra",
    "yearsInService": 3,
    "bio": null
  }
}
```

`400 Bad Request` — `:id` isn't a valid UUID
```json
{ "error": "Invalid user id" }
```

`404 Not Found` — no user/profile exists for that id
```json
{ "error": "Profile not found" }
```

Neither endpoint ever returns `idCardPhotoUrl` — private verification asset.

---

# Connections

All endpoints below require `Authorization: Bearer <token>` **and** an approved account (`403 ACCOUNT_PENDING` / `ACCOUNT_REJECTED` otherwise).

## POST /connections/request/:userId

Send a connection request to another user.

**Responses**

`201 Created`
```json
{
  "requestId": "c4f56802-49f1-4974-be9b-e13000efacf5",
  "status": "pending",
  "createdAt": "2026-08-12T20:09:35.127Z"
}
```

`400 Bad Request` — `:userId` isn't a valid UUID, or equals the requester's own id
```json
{ "error": "Invalid user id" }
```
```json
{ "error": "Cannot send a connection request to yourself" }
```

`404 Not Found` — target user doesn't exist
```json
{ "error": "User not found" }
```

`409 Conflict` — a `Connection` row already exists between these two users, in either direction, regardless of status (pending/accepted/declined). Delete it first via `DELETE /connections/:connectionId` to re-request.
```json
{ "error": "A connection already exists between these users" }
```

## POST /connections/:requestId/accept

Accept a pending request. Only the recipient may call this.

**Responses**

`200 OK`
```json
{
  "requestId": "c4f56802-49f1-4974-be9b-e13000efacf5",
  "status": "accepted",
  "updatedAt": "2026-08-12T20:10:05.833Z"
}
```

`400 Bad Request` — `:requestId` isn't a valid UUID
```json
{ "error": "Invalid request id" }
```

`403 Forbidden` — authenticated user isn't the recipient of this request
```json
{ "error": "Only the recipient can respond to this request" }
```

`404 Not Found` — no such connection request
```json
{ "error": "Connection request not found" }
```

`409 Conflict` — request isn't currently `pending` (already accepted or declined)
```json
{ "error": "Request is already accepted" }
```

## POST /connections/:requestId/decline

Decline a pending request. Same authorization/state rules and error shapes as accept, sets `status` to `"declined"`.

## GET /connections

"My Network" — all accepted connections involving the current user.

**Responses**

`200 OK`
```json
[
  {
    "connectionId": "c4f56802-49f1-4974-be9b-e13000efacf5",
    "since": "2026-08-12T20:10:05.833Z",
    "user": {
      "id": "421cadfb-8fd4-4141-bc33-0f6805dd29c5",
      "profile": { "name": "Officer B", "photoUrl": null, "designation": "SP", "service": "IPS", "department": "Police", "stateOrCadre": "Maharashtra", "yearsInService": 3, "bio": null }
    }
  }
]
```
`user` is always the *other* party in the connection (no email, same as `GET /profile/:id`).

## GET /connections/requests

Pending requests, split by direction — drives the accept/decline UI.

**Responses**

`200 OK`
```json
{
  "incoming": [
    {
      "requestId": "496335f3-9b80-4f8a-9e13-5266a5d187f9",
      "status": "pending",
      "createdAt": "2026-08-12T20:10:42.587Z",
      "user": { "id": "074c04eb-1e8c-4e63-97a6-fc2cc4f31683", "profile": { "...": "..." } }
    }
  ],
  "outgoing": []
}
```
`incoming` = requests sent *to* the current user (actionable via accept/decline). `outgoing` = requests the current user sent, awaiting the other party.

## DELETE /connections/:connectionId

Remove a connection. Semantics depend on its current status:
- **`pending`** — only the **requester** may delete it (cancels their own outgoing request; the recipient should use decline instead, not delete)
- **`accepted`** — **either party** may delete it (disconnect/"unfriend")
- **`declined`** — **either party** may delete it (cleanup — also the way to unblock re-requesting, since a declined row otherwise still blocks new requests between the same pair)

**Responses**

`204 No Content` — deleted, no response body

`400 Bad Request` — `:connectionId` isn't a valid UUID
```json
{ "error": "Invalid connection id" }
```

`403 Forbidden` — either the authenticated user isn't part of this connection at all, or it's `pending` and they're the recipient (not the requester)
```json
{ "error": "Not part of this connection" }
```
```json
{ "error": "Only the requester can cancel a pending request" }
```

`404 Not Found` — no such connection
```json
{ "error": "Connection not found" }
```

---

# Directory

## GET /directory

Browse/search officials. Requires `Authorization: Bearer <token>` **and** an approved account (`403 ACCOUNT_PENDING` / `ACCOUNT_REJECTED` otherwise).

**Only approved officials are listed.** Pending and rejected applicants are filtered out — being browsable is part of what approval grants, so an unreviewed account must not appear here.

**Query params** (all optional, combinable — AND logic; each does a case-insensitive partial match)
| Param | Matches against |
|---|---|
| service | `Profile.service` |
| department | `Profile.department` |
| state | `Profile.stateOrCadre` |

No params → all officials (including the requester's own profile if it matches — this endpoint doesn't exclude self). No pagination yet (deferred, see [FEATURES.md](FEATURES.md)).

Example: `GET /directory?department=Revenue&state=Karnataka`

**Responses**

`200 OK` — always, even with zero matches (it's a search, not a single-resource lookup)
```json
[
  {
    "id": "65728b97-2027-4656-a3a3-9684b6061a57",
    "profile": {
      "name": "Dir Test One",
      "photoUrl": null,
      "designation": "DM",
      "service": "IAS",
      "department": "Revenue",
      "stateOrCadre": "Karnataka",
      "yearsInService": 5,
      "bio": null
    }
  }
]
```
Same public-profile shape as `GET /connections`'s `user` field — no email, no `idCardPhotoUrl`. Ordered by name, ascending.

`401 Unauthorized` — missing/invalid token
```json
{ "error": "Missing token" }
```

---

# Feed

All endpoints below require `Authorization: Bearer <token>` **and** an approved account (`403 ACCOUNT_PENDING` / `ACCOUNT_REJECTED` otherwise).

## POST /feed

Create a post: text + an optional photo.

**Headers**
```
Content-Type: multipart/form-data
```

**Request body** (`multipart/form-data` fields)
| Field | Type | Rules |
|---|---|---|
| content | string (text field) | required, 1-2000 chars (trimmed; whitespace-only is rejected) |
| photo | file | optional — image only (`image/*`), max 5MB, uploaded to Cloudinary |

Example (curl):
```
curl -X POST http://localhost:3000/feed \
  -H "Authorization: Bearer <token>" \
  -F "content=Hello, network!" \
  -F "photo=@photo.jpg;type=image/jpeg"
```

**Responses**

`201 Created`
```json
{
  "id": "9990132e-ff02-4129-83ba-a5ad4fa50e69",
  "content": "Hello, network!",
  "photoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/post-photos/xyz.png",
  "createdAt": "2026-08-12T20:26:32.226Z",
  "author": {
    "id": "44e2d11d-c3b6-4ffa-a30b-d17d9af2e023",
    "profile": { "name": "Feed A", "photoUrl": null, "designation": "DM", "service": "IAS", "department": "Revenue", "stateOrCadre": "Karnataka", "yearsInService": 5, "bio": null }
  }
}
```
`photoUrl` is `null` if no `photo` was sent.

`400 Bad Request` — missing/empty `content`, or non-image/oversized `photo`
```json
{
  "error": "Invalid post content",
  "details": [
    { "code": "too_small", "minimum": 1, "type": "string", "inclusive": true, "exact": false, "message": "String must contain at least 1 character(s)", "path": ["content"] }
  ]
}
```
```json
{ "error": "Only image uploads are allowed" }
```

## GET /feed

Chronological feed: posts from the current user's accepted connections, **plus the current user's own posts**.

**Responses**

`200 OK` — newest first, same post shape as the `POST /feed` response, as an array
```json
[
  {
    "id": "8c75d502-dae9-497b-bac1-1680dc4f0433",
    "content": "Post with a photo",
    "photoUrl": "https://res.cloudinary.com/<cloud>/image/upload/v.../govconnect/post-photos/abc.png",
    "createdAt": "2026-08-12T20:26:35.450Z",
    "author": { "id": "b8565b7a-5bb4-4ca8-a094-499b0f2a43c6", "profile": { "...": "..." } }
  }
]
```
No pagination yet (deferred, see [FEATURES.md](FEATURES.md)).
