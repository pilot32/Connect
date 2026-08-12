# Connect 

A LinkedIn-style professional networking mobile app exclusively for government officials — IAS, IPS, IFS, and other state/central service officers — to connect, discover peers by department/state/service, and share professional updates within a verified network.

## Problem it solves

Government officials currently have no dedicated, trusted platform to network with peers across departments and states. Generic social networks don't verify official identity/designation, so there's no reliable way to know you're actually connecting with a real, currently-serving officer. This app solves that by gating access behind an identity verification step.

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter (Android, APK distribution for testing) |
| Backend API | Node.js + Express |
| Database | PostgreSQL |
| Auth | JWT + Phone OTP |
| State management | Provider / Riverpod |
| Hosting (backend) | Railway / Render / Supabase (TBD) |

## Team

- Full-stack developer — Flutter app + supports backend
- Backend developer — Node.js + PostgreSQL API

## Target Users

Serving government officials (IAS, IPS, IFS, and other central/state civil services) who want to network professionally with verified peers.

---

## MVP Features (Finalized — Week 1 Prototype)

### 1. Authentication
- Signup/login via phone number + OTP
- JWT-based session handling

### 2. Profile
- Name, profile photo
- Designation
- Service (IAS / IPS / IFS / State Service / etc.)
- Department
- State / cadre
- Years in service
- Short bio

### 3. Identity Verification (Access Gate Only)
- Signup is gated behind OTP to a .gov or other mail too for MVP tag email, or a magic link to the .gov tag email if OTP delivery fails
- Successful gov-email verification is required before the account can access the directory, connections, or feed
- No visible "Verified" badge or "Pending" status in MVP — verification is a one-time access check, not a profile attribute
// deferred post-MVP - Upload verification document (service ID / appointment letter / official proof)
// deferred post-MVP - Manual admin approval workflow
// deferred post-MVP - Verified/Pending badge shown on profiles

### 4. Directory / Search
- Browse all officials
- Filter/search by service, department, state

### 5. Connections
- Send connection request
- Accept / decline request
- "My Network" view of accepted connections

### 6. Feed
- Create a text post
- View chronological feed of posts from connections
- the post will contain the content like text reaction no commenst feature as of now

---

## Explicitly Out of Scope for MVP

- Aadhaar / DigiLocker government ID verification (deferred — requires API access + compliance review)
- Verification document upload + manual admin approval workflow
- "Verified" / "Pending" badge or status shown on profiles
- Direct messaging
- Likes / comments on posts
- Rich media posts (images/video)
- Push notifications
- Native admin panel (manual DB / bare-bones web page used instead for week 1)
- iOS build (Android APK only for initial testing)

---

## Step to test the app


1. Install the APK on an Android device
2. Sign up and complete gov-email OTP verification (access gate — no badge/status shown)
3. Create a profile
4. Search the directory and find another seeded official
5. Send/accept a connection request
6. Post to the feed and see it appear

---

## Open Decisions / Next Steps

- Finalize backend hosting provider 
- Finalize OTP delivery provider (Twilio / MSG91) or confirm hardcoded test OTP for demo
- Define Postgres schema (users, profiles, connections, posts)
- Define Flutter project folder structure and navigation flow

See [FEATURES.md](FEATURES.md) for the post-MVP feature backlog and [ENTITIES.md](ENTITIES.md) for the current data model.
