# API Contract — Auth

Base URL (local dev): `http://localhost:3000`

Covers the currently implemented endpoints in `connectappbe/src/routes/auth.routes.js` / `connectappbe/src/controllers/auth.controller.js`. Other feature routers (profile, verification, directory, connections, feed) are not implemented yet — see [AGENTS.md](AGENTS.md).

---

## POST /auth/signup

Creates a new user with email + password, full profile details, and an ID card photo for verification. Profile photo, ID card photo, and Cloudinary upload happen server-side as part of this request.

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

`201 Created` — account + profile created
```json
{
  "token": "<jwt>",
  "user": {
    "id": "9a48b702-203c-47a6-9092-076ce1f7954b",
    "email": "officer@example.com"
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

Authenticates an existing user with email + password.

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
    "id": "9a48b702-203c-47a6-9092-076ce1f7954b",
    "email": "officer@example.com"
  }
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

## Notes

- `token` is a JWT signed with `JWT_SECRET`, payload `{ sub: <user id>, email }`, expires in 7 days. Send it as `Authorization: Bearer <token>` on endpoints that require `requireAuth` (none yet — auth is the first implemented feature).
- `password_hash` is never returned in any response.
- No email verification, OTP, or gov-email gate on signup/login in this pass — see [FEATURES.md](FEATURES.md) for that as a deferred item.
- Login (`POST /auth/login`) is unaffected by the profile/ID-card changes — still plain `application/json` with just `email`/`password`.
- The ID card photo is only *captured and stored* at signup — nothing in this pass reviews it, sets a verified status, or shows a badge (that's still deferred, see [FEATURES.md](FEATURES.md)).
