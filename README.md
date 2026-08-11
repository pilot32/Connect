# GovConnect (Working Title)

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

### 3. Identity Verification
- will work either with OTP email of .gov tag or magic link to the email of .gov tag if that fails  
// optinal as of now for MVP- Upload verification document (service ID / appointment letter / official proof)
//optional as of now for MVP- Manual admin approval workflow
- "Verified" badge shown on approved profiles
- Unverified profiles marked "Pending"

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
- Direct messaging
- Likes / comments on posts
- Rich media posts (images/video)
- Push notifications
- Native admin panel (manual DB / bare-bones web page used instead for week 1)
- iOS build (Android APK only for initial testing)

---

## Step to test the app


1. Install the APK on an Android device
2. Sign up and complete OTP verification
3. Create a profile and upload a verification document
4. Get manually marked "Verified" by admin
5. Search the directory and find another seeded official
6. Send/accept a connection request
7. Post to the feed and see it appear

---

## Open Decisions / Next Steps

- Finalize backend hosting provider 
- Finalize OTP delivery provider (Twilio / MSG91) or confirm hardcoded test OTP for demo
- Define Postgres schema (users, profiles, connections, posts, verification_documents)
- Define Flutter project folder structure and navigation flow