# API Contract — Auth

Base URL (local dev): `http://localhost:3000`

Covers the currently implemented endpoints in `connectappbe/src/routes/auth.routes.js` / `connectappbe/src/controllers/auth.controller.js`. Other feature routers (profile, verification, directory, connections, feed) are not implemented yet — see [AGENTS.md](AGENTS.md).

---

## POST /auth/signup

Creates a new user with email + password.

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

`201 Created` — account created
```json
{
  "token": "<jwt>",
  "user": {
    "id": "9a48b702-203c-47a6-9092-076ce1f7954b",
    "email": "officer@example.com"
  }
}
```

`400 Bad Request` — validation failed (invalid email format, missing fields, or password under 8 characters)
```json
{
  "error": "Invalid email or password",
  "details": [
    {
      "validation": "email",
      "code": "invalid_string",
      "message": "Invalid email",
      "path": ["email"]
    }
  ]
}
```

`409 Conflict` — email already registered
```json
{
  "error": "Email is already registered"
}
```

`500 Internal Server Error` — unexpected failure (e.g. DB unreachable); internal details are logged server-side only, never returned to the client
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
