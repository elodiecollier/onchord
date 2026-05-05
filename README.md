# Onchord

A music social platform for iOS that integrates with Spotify. Users can search for songs, albums, and artists, rate them with a 1–5 star system, and follow other users to see their reviews.

---

## Why Onchord?

My best friend and I adore our logging and rating apps. Personally, I am consistently updating my Beli with the restaurants I've tried, GoodReads with the books I've finished, and Letterboxd for the movies I've watched. The only app missing was one for rating songs, albums, and artists we listen to. My best friend gave me the idea to build an app to solve this issue, and with the availability of Spotify's API to individual developers, I knew I could do it. Onchord was built for my close friends and me to put our possibly-problematic opinions of music "on the record" and to satisfy the hole we both felt in our logging needs.

---

## Demo & Screenshots

📱 **[Watch the demo on YouTube](https://youtu.be/tblJcXCZfr0?si=r-mOjYSOoaSuZ3NV)**

<p float="left">
  <img src="https://elodiecollier.github.io/assets/screenshots/rateRecentListens.png" width="18%" />
  <img src="https://elodiecollier.github.io/assets/screenshots/rateSong.png" width="18%" />
  <img src="https://elodiecollier.github.io/assets/screenshots/friendActivity.png" width="18%" />
  <img src="https://elodiecollier.github.io/assets/screenshots/searchResults.png" width="18%" />
  <img src="https://elodiecollier.github.io/assets/screenshots/myProfile.png" width="18%" />
</p>

---

## Tech Stack

| Layer | Technology |
|---|---|
| iOS App | Swift 5.0, SwiftUI, MVVM |
| Authentication | Firebase Auth + Spotify OAuth 2.0 (PKCE) |
| Database | Cloud Firestore |
| Backend | Firebase Cloud Functions (Node.js v24 / TypeScript) |
| Music API | Spotify Web API |
| iOS Package Manager | Swift Package Manager |
| Backend Package Manager | npm |

---

## Architecture

```
onchord/
├── ios/onchord/              # Xcode project
│   └── onchord/
│       ├── Models/           # Data models (AlbumResult, RatedSong, UserResult, etc.)
│       ├── ViewModels/       # MVVM view models (Search, Profile, Detail, FollowList)
│       ├── Views/            # SwiftUI views
│       ├── Services/
│       │   ├── SpotifyAuth.swift       # OAuth PKCE flow + Firebase custom token auth
│       │   └── FirestoreService.swift  # All Firestore read/write operations
│       └── GoogleService-Info.plist   # Firebase iOS config (not committed if missing)
└── firebase/
    ├── firestore.rules        # Firestore security rules
    ├── firestore.indexes.json
    ├── .firebaserc            # Firebase project alias (project: onchord-ec86c)
    ├── firebase.json          # Deployment config
    └── functions/
        ├── src/index.ts       # All Cloud Function endpoints
        ├── package.json
        └── tsconfig.json
```

---

## iOS Dependencies (Swift Package Manager)

Managed via `ios/onchord/onchord.xcodeproj/project.pbxproj` and `Package.resolved`.

| Package | Version | Used For |
|---|---|---|
| `firebase-ios-sdk` | 12.9.0 | FirebaseCore, FirebaseAuth, FirebaseFirestore |

Transitive dependencies (resolved automatically by SPM):
- `abseil-cpp-binary` v1.2024072200.0
- `app-check` v11.2.0
- `grpc-binary` v1.69.1
- `gtm-session-fetcher` v5.1.0
- `leveldb` v1.22.5
- `nanopb` v2.30910.0
- `promises` v2.4.0
- `googleutilities` v8.1.0
- `googledatatransport` v10.1.0

---

## Firebase Functions Dependencies (npm)

Located in `firebase/functions/package.json`.

**Runtime:**
| Package | Version |
|---|---|
| `firebase-admin` | ^13.6.1 |
| `firebase-functions` | ^7.0.0 |

**Dev:**
| Package | Version |
|---|---|
| `typescript` | ^5.1.6 |
| `eslint` | ^8.9.0 |
| `@typescript-eslint/eslint-plugin` | ^5.12.0 |
| `@typescript-eslint/parser` | ^5.12.0 |
| `eslint-config-google` | ^0.14.0 |
| `eslint-plugin-import` | ^2.25.4 |
| `firebase-functions-test` | ^3.4.1 |

---

## Prerequisites

### macOS / Xcode
- macOS with **Xcode 16+** or later
- Swift 5.0+
- An Apple Developer account (for device builds / TestFlight)

### Node.js
- Node.js **v20** (pinned in `.nvmrc`). Use `nvm` to switch:
  ```bash
  nvm use   # reads .nvmrc automatically
  ```

### Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### Accounts & Credentials Required
- **Firebase project:** `onchord-ec86c` — access required on Firebase Console
- **Spotify Developer App** — Client ID and secret needed for backend functions
- **`GoogleService-Info.plist`** — Download from Firebase Console → Project Settings → iOS app and place at `ios/onchord/onchord/GoogleService-Info.plist`
- **`.env` file** — Place at `firebase/functions/.env` with the following keys:
  ```
  SPOTIFY_CLIENT_ID=...
  SPOTIFY_CLIENT_SECRET=...
  ```

---

## Setup

### iOS App

1. Open `ios/onchord/onchord.xcodeproj` in Xcode.
2. Ensure `GoogleService-Info.plist` is present at `ios/onchord/onchord/`.
3. Swift Package Manager will resolve dependencies automatically on first open.
4. Select a simulator or connected device and run.

### Firebase Functions

```bash
cd firebase/functions
nvm use           # switch to Node 20
npm install       # install dependencies
npm run build     # compile TypeScript
```

**Run locally with emulators:**
```bash
npm run serve     # builds + starts Firebase emulators (functions only)
```

**Deploy to production:**
```bash
npm run deploy    # firebase deploy --only functions
```

**Other scripts:**
```bash
npm run lint      # eslint check
npm run build:watch  # watch mode TypeScript compilation
npm run logs      # tail Firebase function logs
```

---

## Cloud Functions Endpoints

All functions are HTTP-triggered and live in `firebase/functions/src/index.ts`.

| Function | Description |
|---|---|
| `healthcheck` | Service status ping |
| `spotifyLogin` | Initial Spotify OAuth exchange, creates user in Firestore + Firebase Auth |
| `spotifyExchange` | Token exchange for returning users |
| `spotifyRefresh` | Refresh a user's Spotify access token |
| `spotifySearch` | Search Spotify (albums, tracks) |
| `spotifyAlbumTracks` | Fetch tracks for an album |
| `spotifyArtistAlbums` | Fetch albums and profile for an artist |

---

## Firestore Collections

| Collection | Description |
|---|---|
| `users` | Public user profiles |
| `reviews` | Song and album ratings (1–5 stars) |
| `follows` | Follow relationships between users |
| `spotifyTokens` | Private per-user Spotify tokens (access + refresh) |

Security rules are defined in `firebase/firestore.rules`.

---

## Environment Files (not committed)

| File | Purpose |
|---|---|
| `firebase/functions/.env` | Spotify client ID + secret |
| `firebase/.runtimeconfig.json` | Legacy Firebase runtime config |
| `ios/onchord/onchord/GoogleService-Info.plist` | Firebase iOS configuration |

---

## Key Firestore / Firebase Config

- **Firebase Project ID:** `onchord-ec86c`
- **iOS Bundle ID:** `com.elodiecollier.onchord`
- **Firebase Project Alias:** defined in `firebase/.firebaserc`
