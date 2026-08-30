# PlantPal API integration

Base URL: `https://plant-hzgf.onrender.com` (override with
`--dart-define=PLANTPAL_API=…`). OpenAPI: `GET /openapi.json`.

## Layers

| Path | Role |
|------|------|
| `lib/api/api_client.dart` | HTTP transport: bearer-token header, JSON encode/decode, error mapping, one-shot 401→`/refresh`→retry, multipart upload. |
| `lib/api/token_store.dart` | Persists the JWT pair to `<appSupport>/pp_tokens.json` (via `path_provider`). `shared_preferences`/`flutter_secure_storage` don't resolve on this Flutter SDK — swap in secure storage on a full SDK. |
| `lib/api/plantpal_api.dart` | `PlantPalApi.instance` — one typed method per endpoint. |
| `lib/models/models.dart` | Response models. Tolerant parsing: the API mixes GORM PascalCase (`ID`, `CreatedAt`, `Plants`) with snake_case, so every field is read through `pick([...aliases])`. |
| `lib/state/auth_scope.dart` | `AuthController` (`ChangeNotifier`) + `AuthScope` InheritedNotifier. `_AuthGate` in `main.dart` renders Splash / Welcome / RootShell off `AuthController.status`. |
| `lib/widgets/async_view.dart` | `AsyncView<T>` — loading / error (with Retry) / empty / data, in the app's visual language. `showPPSnack()` for transient feedback. |

## Screen wiring

| Screen | Endpoints |
|--------|-----------|
| Login / Signup | `POST /login`, `POST /register`, `POST /auth/google` (ID-token exchange; see constraints) |
| Home | `GET /users/me`, `/reminders/today`, `/plants`, `/weather`, `/notifications/unread-count`; toggle task → `PUT /reminders/{id}`. Search icon → `GET /plants/search?q=`; health card → Garden health screen; "See all" → Plants tab |
| Collection / Search | `GET /plants` (room filter client-side); `GET /plants/search?q=` |
| Plant detail | `GET /plants/{id}` + `/care-plan` + `/growth` + `/activities` + `/journal?plant_id=`. Tab-aware action: **Care** → `POST /plants/{id}/activities`; **Growth** → `POST /plants/{id}/growth`; **Journal** → local `JournalStore` + `POST /journal` on "Sync to cloud"; **Info** → species + care-plan detail. Stethoscope downloads the plant photo → `POST /diagnosis` → live session |
| Reminders | `GET /reminders/today` + `/reminders`; complete / snooze → `PUT /reminders/{id}`; **＋** → `POST /plants/{id}/reminders` |
| Journal tab | `GET /journal` merged with device-only notes (`JournalStore`); **＋** adds a local note; "Sync to cloud" → `POST /journal` (multipart) |
| Community | `GET /community/posts` (category slugged: `Q&A`→`qa`); like → `POST`/`DELETE .../like`; **＋** → `POST /community/posts`; tap a post → `GET /community/posts/{id}/comments`, `POST` to comment |
| Weather | `GET /weather` (Open-Meteo proxy). Home card is resilient to a failed fetch; the screen has Retry |
| Notifications | `GET /notifications/inbox`; mark read → `PATCH /notifications/{id}/read`; Read all → `POST /notifications/read-all`; swipe → `DELETE /notifications/{id}`. `RootShell` polls `/notifications/unread-count` on resume and shows an in-app banner for newly-due care |
| Profile | `GET /users/me`, `GET/PUT /notifications`; edit (name + image URL) → `PUT /users/me`; Privacy & Help are in-app Markdown docs; Log out → `AuthController.logout()` |
| Scan / Diagnosis | `POST /scan`, `GET /scan/{id}`, `POST /scan/{id}/confirm`, `POST /diagnosis`, `POST /diagnosis/{id}/chat`, `GET /diagnosis/{id}` |

## Known constraints

- **No camera/gallery.** No image-picker plugin resolves on this SDK (all pull
  `flutter_web_plugins`, which is missing). Scan & Diagnosis send the bundled
  sample photo (`assets/img/sample_plant.jpg`); the full flow after that —
  result → confirm → plant, and the live diagnosis session — is real. Drop in a
  capture plugin on a full SDK and feed its bytes to `PlantPalApi.scan` /
  `.startDiagnosis`.
- **No native Google Sign-In / OS notifications** for the same reason. The
  Google button opens a manual ID-token field wired to
  `AuthController.loginWithGoogle`; add `google_sign_in` on a full SDK. Push is
  in-app only (`RootShell` inbox polling); add `flutter_local_notifications` for
  real scheduled OS alerts.
- **Journal notes** live on-device in `JournalStore` (a plain JSON file, like
  `TokenStore`) until synced. Synced notes carry a `remoteId` so they aren't
  shown twice after a `GET /journal`.
- `preferred_notification_time` must be a full RFC3339 datetime — the model
  serialises `HH:mm` as `0001-01-01THH:mm:00Z`.
- `PUT /users/me` now also accepts `image_url` (backend change) so the profile
  picture can be set from a hosted URL without a multipart upload.
