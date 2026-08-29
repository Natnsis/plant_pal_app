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
| Login / Signup | `POST /login`, `POST /register` |
| Home | `GET /users/me`, `/reminders/today`, `/plants`, `/weather`, `/notifications/unread-count`; toggle task → `PUT /reminders/{id}` |
| Collection | `GET /plants` (room filter is client-side on `location`) |
| Plant detail | `GET /plants/{id}` + `/care-plan` + `/growth` + `/activities`; Log watering → `POST /plants/{id}/activities` |
| Reminders | `GET /reminders/today` + `/reminders`; complete / snooze → `PUT /reminders/{id}` |
| Journal | `GET /journal` |
| Community | `GET /community/posts` (category query); like → `POST`/`DELETE /community/posts/{id}/like` (optimistic) |
| Weather | `GET /weather` — upstream provider currently returns 502; the screen shows a graceful error + Retry |
| Notifications | `GET /notifications/inbox`; mark read → `PATCH /notifications/{id}/read`; Read all → `POST /notifications/read-all`; swipe → `DELETE /notifications/{id}` |
| Profile | `GET /users/me`, `GET/PUT /notifications`; Log out → `AuthController.logout()` |
| Scan / Diagnosis | `POST /scan`, `POST /scan/{id}/confirm`, `POST /diagnosis`, `POST /diagnosis/{id}/chat`, `GET /diagnosis/{id}` |

## Known constraints

- **No camera/gallery.** No image-picker plugin resolves on this SDK (all pull
  `flutter_web_plugins`, which is missing). Scan & Diagnosis send a bundled
  sample photo (`assets/img/sample_plant.jpg`) so the request path is exercised;
  drop in a real capture plugin on a full SDK and feed its bytes to
  `PlantPalApi.scan` / `.startDiagnosis`.
- `preferred_notification_time` must be a full RFC3339 datetime — the model
  serialises `HH:mm` as `0001-01-01THH:mm:00Z`.
- The diagnosis screen keeps a local sample conversation when opened without a
  `sessionId` (from a plant, not a scan); with a `sessionId` it is fully live.
