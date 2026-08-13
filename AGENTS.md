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

Auth (login + signup) is implemented; Profile/Directory/Connections/Feed screens
are still empty stubs awaiting their own passes.

```
connectappfe/
  pubspec.yaml      deps: provider, dio, flutter_secure_storage, go_router,
                     image_picker, shared_preferences, json_annotation,
                     connectivity_plus, flutter_dotenv
                     devDeps: build_runner, json_serializable, flutter_lints
  test/
    validators_test.dart  unit tests for the form validators
  lib/
    main.dart          entry point -> ConnectApp
    app.dart             root widget; builds the DI graph + MaterialApp.router
    core/
      config/
        env.dart          API base URL (String.fromEnvironment, host-aware)
        api_config.dart    endpoint paths + timeouts
      models/
        picked_image.dart  image bytes + filename, shared by picker and upload
      services/
        api_client.dart     Dio wrapper: base URL, JWT interceptor, 401 hook
        api_exception.dart   maps server {error, details} into a UI-ready error
        storage_service.dart secure storage for the JWT
      utils/
        validators.dart     form validators mirroring the backend zod rules
      widgets/               shared UI: app_button, app_text_field, auth_shell,
                             brand_mark, fade_slide_in, image_picker_field,
                             shake_on_change, status_banner
      router/
        app_router.dart     go_router config + custom page transitions
        app_routes.dart      route path constants
      theme/
        app_colors.dart      brand palette
        app_tokens.dart      spacing / radius / motion tokens
        app_theme.dart       light + dark ThemeData
    features/
      auth/            models/ + services/ + state/auth_controller.dart +
                        screens/ (login_screen, signup_screen) — IMPLEMENTED
      splash/           screens/splash_screen.dart — shown during session restore
      home/             screens/home_screen.dart — post-login placeholder
      profile/          screens/ (profile, edit_profile) + services/ — empty stubs
      verification/      screens/ + services/ — empty stubs
      directory/          screens/ + services/ — empty stubs
      connections/         screens/ + services/ — empty stubs
      feed/                screens/ + services/ — empty stubs
```

Feature-first organization: each domain under `features/` owns its own `screens/` and `services/`. Shared/cross-cutting code lives under `core/`.

Frontend notes:
- **API base URL** defaults to `10.0.2.2:3000` on Android (emulator → host) and
  `localhost:3000` elsewhere. For a physical device, pass your machine's LAN IP:
  `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000`.
- **Cleartext HTTP** is enabled via `android/app/src/main/res/xml/network_security_config.xml`
  so the dev backend is reachable. Remove it once the API is on HTTPS.
- Models use hand-written `fromJson`, so **no `build_runner` step is required**
  to compile, despite json_serializable being declared.

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
