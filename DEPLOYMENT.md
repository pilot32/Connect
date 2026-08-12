# Deployment — Backend on Render

Deploying `connectappbe` so the Flutter app can reach the API over the internet
instead of a LAN address.

---

## Secrets: what goes where

**Nothing secret is committed to this repository.** `connectappbe/.env` is
gitignored and must stay that way — this repo is public, and it holds the
Supabase database password, the Cloudinary API secret, and the JWT signing key.
Anyone with those can read and write the entire database, delete uploaded ID
documents, and mint valid login tokens for any account. Public repos are
continuously scraped for exactly these strings.

The committed file is `connectappbe/.env.example`, which lists the variable
*names* with placeholder values. Real values live in two places only:

| Where | Purpose |
|---|---|
| `connectappbe/.env` on your machine | local development (gitignored) |
| Render dashboard → service → Environment | production |

---

## Required environment variables

Set all six in the Render dashboard (Environment tab). `PORT` is injected by
Render automatically — don't set it.

| Variable | Where to find it |
|---|---|
| `DATABASE_URL` | Supabase → Project Settings → Database → Connection pooling (port `6543`), append `?pgbouncer=true` |
| `DIRECT_URL` | Same page, pooler host on port `5432` |
| `JWT_SECRET` | Generate a **new** one for production: `openssl rand -base64 32` |
| `CLOUDINARY_CLOUD_NAME` | Cloudinary dashboard → Product Environment Credentials |
| `CLOUDINARY_API_KEY` | Same |
| `CLOUDINARY_API_SECRET` | Same |

> Use the **connection pooler** host (`aws-0-<region>.pooler.supabase.com`), not
> the direct `db.<ref>.supabase.co` host. The direct host resolves to IPv6 only
> and is unreachable from most networks — this already bit us during local
> development.

Use a different `JWT_SECRET` in production than the one in your local `.env`. If
they match, a leak of one compromises both.

---

## Deploy

**Option A — Blueprint (uses `connectappbe/render.yaml`)**

1. Render → **New** → **Blueprint**, select this repository.
2. Render reads `render.yaml`, creates the `connect-api` web service.
3. Fill in the six `sync: false` variables when prompted.

**Option B — Manual web service**

1. Render → **New** → **Web Service**, connect the repository.
2. Configure:
   - **Root Directory**: `connectappbe`
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
3. Add the six environment variables under **Environment**.

`npm install` triggers the `postinstall` hook, which runs `prisma generate` to
build the Prisma client. `prisma` is a runtime dependency rather than a dev
dependency specifically for this: Render sets `NODE_ENV=production`, which makes
npm skip `devDependencies`, and `postinstall` would fail with `prisma: not found`.

### Database schema

Render does **not** run migrations. The Supabase tables already exist from local
development. For a fresh database, run the SQL files in order in the Supabase
SQL Editor:

```
connectappbe/prisma/sql/001_create_users.sql
connectappbe/prisma/sql/002_add_profiles_and_id_card.sql
connectappbe/prisma/sql/003_create_connections.sql
connectappbe/prisma/sql/004_create_posts.sql
```

---

## Verify the deploy

```bash
curl https://<your-service>.onrender.com/
# -> Backend is running!

curl -X POST https://<your-service>.onrender.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"nobody@example.com","password":"password123"}'
# -> 401 {"error":"Invalid email or password"}  (proves the DB is reachable)
```

A `500` on that second call means the database connection is misconfigured —
check `DATABASE_URL` and confirm you used the pooler host.

**Free plan caveat:** the service sleeps after ~15 minutes idle. The next
request takes 30–60s to wake it. If the app seems to hang on first launch,
that's why — not a bug.

---

## Point the Flutter app at it

The app defaults to `10.0.2.2:3000` (Android emulator → host machine). To use
the deployed API from a physical phone, override the base URL at build time:

```bash
cd connectappfe

# Run on a connected device
flutter run --dart-define=API_BASE_URL=https://<your-service>.onrender.com

# Or build an installable APK
flutter build apk --release \
  --dart-define=API_BASE_URL=https://<your-service>.onrender.com
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`.

Because the deployed URL is `https://`, the cleartext-HTTP exemption in
`connectappfe/android/app/src/main/res/xml/network_security_config.xml` is no
longer needed for this path. Keep it only while you still test against a local
`http://` backend; remove it before any real release.
