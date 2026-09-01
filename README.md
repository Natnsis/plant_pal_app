<div align="center">

<img src="assets/img/icon.jpg" width="88" height="88" alt="PlantPal" style="border-radius:20px" />

# PlantPal

**Scan your plants, get a care schedule, and never miss a watering again.**
A plant-care companion with AI identification, an AI plant doctor, recurring
reminders, garden-health tracking, and a community — for Android.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.13-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/platform-Android-3ddc84?logo=android)

[**⬇ Download the APK**](https://github.com/Natnsis/plant_pal_app/releases/latest) ·
[**Install guide & site**](https://github.com/Natnsis/plant_pal_landing) ·
[**Backend API**](https://github.com/Natnsis/plant-pal-api)

</div>

---

> My first proper Flutter app. Built to take the research-planning-and-remembering
> chore out of keeping houseplants alive. Feedback and PRs welcome.

## What it does

| | |
|---|---|
| 🔍 **Scan & identify** | Point the camera at a plant → species + full care profile, via AI vision. |
| 🩺 **AI plant doctor** | Describe a symptom or send a photo → likely diagnosis and a fix, with follow-up chat. |
| 📅 **Care plans & reminders** | Per-plant watering / feeding / misting / rotation cadence, auto-rescheduling the next occurrence when you complete or skip one. |
| 🔔 **Reminders that reach you** | Local notifications **and** FCM push (delivered at your preferred time), overdue tracking, care streaks. |
| 📈 **Garden health score** | One number for the whole collection, trended over time. |
| 👥 **Community** | Posts, comments, likes — replies land in your inbox and deep-link straight to the thread. |
| 📖 **Journal & growth** | Photo journal and growth metrics per plant. |
| ⛅ **Weather-aware** | Local conditions from Open-Meteo alongside your care tasks. |
| 🔑 **Auth** | Email/password + native Google Sign-In. |

## Architecture notes

This project runs on a **stripped Flutter SDK with no plugin support**, so the
usual federated plugins (`image_picker`, `flutter_local_notifications`,
`firebase_messaging`, `google_sign_in`, `shared_preferences`, …) can't be used.
Everything they'd provide is **hand-rolled as native `MethodChannel` bridges**:

| Channel | Kotlin | Replaces |
|---|---|---|
| `plantpal/media` | `MainActivity.kt` | system camera + photo picker → downscaled JPEG |
| `plantpal/notifications` | `Notifications.kt` | `POST_NOTIFICATIONS` flow + posting to the shade |
| `plantpal/push` | `PlantPalFirebaseMessagingService.kt` | FCM token + data-message handling |
| `plantpal/auth` | `MainActivity.kt` | Google Sign-In (Play Services, ID token) |
| `plantpal/links` | `MainActivity.kt` | `plantpal://` deep links |

Firebase is wired **without** the `google-services` Gradle plugin — config lives
in `android/app/src/main/res/values/firebase.xml` as string resources that
`FirebaseInitProvider` reads at startup.

Other choices: plain `ChangeNotifier` + `InheritedNotifier` for state (no
packages), token/journal/prefs persisted as JSON files via `path_provider`,
`http` for networking, `lucide_icons_flutter` for icons. Design tokens in
`lib/theme/pp_theme.dart` (Outfit typeface; forest / bone / lime).

## Project layout

```
lib/
  api/       HTTP client, typed API facade, native-channel wrappers, local stores
  models/    data models + JSON parsing
  screens/   one file per screen
  state/     AuthController / AuthScope
  theme/     design tokens
  widgets/   shared UI
android/app/src/main/kotlin/com/example/plant_app/
  MainActivity.kt, Notifications.kt, PlantPalFirebaseMessagingService.kt
```

## Run it

```bash
flutter pub get
flutter run                       # uses the hosted API by default
```

Point at a local backend instead:

```bash
flutter run --dart-define=PLANTPAL_API=http://10.0.2.2:8080
```

Release build:

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### External setup

- **Backend** — the Go API ([`plant-pal-api`](https://github.com/Natnsis/plant-pal-api)),
  hosted; override with `--dart-define=PLANTPAL_API=…`.
- **Firebase (push)** — a `google-services.json` / `firebase.xml` is committed for
  the project's own Firebase app. For your own, swap the values in
  `android/app/src/main/res/values/firebase.xml` and set
  `FIREBASE_SERVICE_ACCOUNT_JSON` on the backend.
- **Google Sign-In** — needs an Android OAuth client for package
  `com.example.plant_app` + your signing SHA-1, and the backend
  `GOOGLE_CLIENT_ID` set to the **web** client id.

## Install (for users)

Not on the Play Store yet — grab the APK from
[**Releases**](https://github.com/Natnsis/plant_pal_app/releases/latest). The
[landing page](https://github.com/Natnsis/plant_pal_landing) has a step-by-step
install guide (including getting past Play Protect).

<div align="center"><sub>PlantPal · <a href="https://github.com/Natnsis/plant-pal-api">API</a> · <a href="https://github.com/Natnsis/plant_pal_landing">landing page</a></sub></div>
