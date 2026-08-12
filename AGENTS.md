# AGENTS.md — GovConnect Project Context

Quick-orientation file for LLM coding agents working in this repo. Read this first, then pull in [README.md](README.md), [FEATURES.md](FEATURES.md), or [ENTITIES.md](ENTITIES.md) as needed for depth.

> **Keep this file current.** Run `/update-context` after finishing a unit of work to refresh this file (and FEATURES.md/ENTITIES.md if relevant) with what actually changed. See "Keeping this file current" below.

---

## What this project is

**GovConnect** (working title) — a LinkedIn-style professional networking mobile app exclusively for verified government officials (IAS, IPS, IFS, state/central services) to connect by department/state/service and share professional updates.

Full product context: [README.md](README.md).

---

## Tech stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Android only for MVP) |
| Backend API | Node.js + Express |
| Database | PostgreSQL via Prisma ORM |
| Auth | JWT + Email OTP; gov-email OTP/(later stage only Email OTP as of now )magic-link as an access gate (no visible verification badge) |
| State management | Provider |
| HTTP client (FE) | Dio |
| Routing (FE) | go_router |

---

## Repo layout

```
Connect/
  README.md          product spec, MVP scope, test steps
  FEATURES.md         post-MVP feature backlog by phase
  ENTITIES.md          data model reference (User, Profile, Connection, Post)
  AGENTS.md            this file
  connectappbe/        backend — Node.js + Express
  connectappfe/         frontend — Flutter
```

### Backend — `connectappbe/`

```
connectappbe/
  index.js                       app entry point
  app.js                          (currently empty stub)
  package.json                    deps: express, @prisma/client, jsonwebtoken,
                                   dotenv, zod, cors, morgan
                                   devDeps: prisma, nodemon
  src/
    config/
      env.js                       env var loader (empty stub)
      db.js                        Prisma/db connection (empty stub)
    controllers/
      auth.controller.js            (empty stub)
      profile.controller.js         (empty stub)
      # verification/directory/connections/feed controllers not yet created
    middleware/
      auth.js                       JWT auth guard (empty stub)
      errorHandler.js               (empty stub)
    routes/
      index.js                      mounts all feature routers (empty stub)
      auth.routes.js                 (empty stub)
      profile.routes.js              (empty stub)
      verification.routes.js         (empty stub)
      directory.routes.js            (empty stub)
      connections.routes.js          (empty stub)
      feed.routes.js                 (empty stub)
    models/                          empty, reserved for Prisma-adjacent model logic
    db/migrations/                   empty, reserved (Prisma manages its own
                                     prisma/migrations once `prisma init` is run)
    utils/                          empty, reserved
```

Route → feature mapping is one router + one controller per MVP feature area: auth, profile, verification, directory, connections, feed. `verification`/`directory`/`connections`/`feed` controllers still need to be created to match their routers.

### Frontend — `connectappfe/`

```
connectappfe/
  pubspec.yaml      deps: provider, dio, flutter_secure_storage,
                     shared_preferences, json_annotation, go_router,
                     connectivity_plus, flutter_dotenv
                     devDeps: build_runner, json_serializable, flutter_lints
  lib/
    main.dart          existing default Flutter entry point (untouched, not yet wired up)
    app.dart             root app widget (empty stub)
    core/
      config/
        env.dart          (empty stub)
        api_config.dart    (empty stub)
      services/
        api_client.dart     Dio wrapper (empty stub)
        storage_service.dart secure storage + shared_prefs wrapper (empty stub)
      utils/
        validators.dart     form validators (empty stub)
      widgets/               empty, reserved for shared widgets
      router/
        app_router.dart     go_router config (empty stub)
      theme/
        app_theme.dart       ThemeData (empty stub)
    features/
      auth/            screens/ (login, otp) + services/ (auth_service) — all empty stubs
      profile/          screens/ (profile, edit_profile) + services/ (profile_service) — empty stubs
      verification/      screens/ (verification) + services/ (verification_service) — empty stubs
      directory/          screens/ (directory) + services/ (directory_service) — empty stubs
      connections/         screens/ (connections) + services/ (connections_service) — empty stubs
      feed/                screens/ (feed) + services/ (feed_service) — empty stubs
```

Feature-first organization: each domain under `features/` owns its own `screens/` and `services/`. Shared/cross-cutting code lives under `core/`.

---

## Current MVP scope (Week 1 prototype)

1. **Auth** — phone number + OTP signup/login, JWT sessions
2. **Profile** — name, photo, designation, service, department, state/cadre, years in service, bio
3. **Identity verification (access gate only)** — gov-email OTP or magic-link required before using the app; **no visible "Verified"/"Pending" badge or status in MVP** (that was deliberately removed from scope — see [FEATURES.md](FEATURES.md) Phase 2)
4. **Directory/search** — browse and filter officials by service, department, state
5. **Connections** — send/accept/decline requests, "My Network" view
6. **Feed** — text-only posts, chronological, from connections only (no likes/comments/media)

Explicitly out of scope for MVP: Aadhaar/DigiLocker verification, verification docs + admin approval, verification badges, DMs, likes/comments, rich media, push notifications, native admin panel, iOS build. Full list and rationale in [README.md](README.md#explicitly-out-of-scope-for-mvp).

Data model: [ENTITIES.md](ENTITIES.md) — `User`, `Profile`, `Connection`, `Post`.

Post-MVP roadmap: [FEATURES.md](FEATURES.md).

---

## Key conventions

- **Empty-stub files are intentional, not broken.** Most files listed above under `src/` and `lib/` are empty placeholders created to lock in the project structure before implementation. Don't treat an empty file as a bug — check with the user/team before assuming it should already contain logic, and don't silently "complete" a stub with invented behavior beyond what's asked.
- **Feature-first folders.** Both backend (`routes`/`controllers` per feature) and frontend (`features/<name>/screens`, `features/<name>/services`) organize by product feature, not by technical layer. New feature work should follow this pattern rather than introducing a new organizing scheme.
- **Dependencies may be declared but not installed.** `package.json`/`pubspec.yaml` can be ahead of what's actually been `npm install`ed / `flutter pub get`ed on this machine — check before assuming a package is available in `node_modules`/`.dart_tool`.
- **Verification is an access gate, not a profile attribute.** Do not reintroduce a Verified/Pending badge or status field without an explicit product decision — it was deliberately cut from MVP.

---

## Keeping this file current

Run the `/update-context` slash command (defined in `.claude/commands/update-context.md`) after completing a chunk of work. It reviews recent changes (git diff/log) and updates this file — plus `FEATURES.md`/`ENTITIES.md` if the data model or backlog shifted — so future agents don't work from stale context.
