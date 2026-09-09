# HMS India — Mobile

Flutter mobile client for the HMS India hospital management system. It talks to a Laravel + Sanctum API backend and serves six roles from one app: patient, nurse, staff, lab assistant, receptionist, and pharmacist. After login, `RoleHome` routes each user straight to their role's dashboard.

## Requirements

- Flutter SDK `>=3.3.0 <4.0.0`
- A running instance of the Laravel backend

## Getting started

```bash
flutter pub get
flutter run
```

### Pointing the app at your backend

The API base URL is set in `lib/core/services/api_service.dart` (`ApiService.baseUrl`). Update it depending on where you're running from:

| Target | Base URL |
| --- | --- |
| Chrome / desktop (this machine) | `http://127.0.0.1:8000` |
| Real Android device over USB | `http://127.0.0.1:8000` (run `adb reverse tcp:8000 tcp:8000` once per connection) |
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://127.0.0.1:8000` |
| Real device over Wi-Fi | `http://<your-pc-lan-ip>:8000` |
| Deployed server | `https://your-domain.com` |

## Project structure

```
lib/
  core/            shared models, navigation (RoleHome), API/auth-storage services, theme
  features/
    auth/          login, registration, forgot password
    patient/       appointments, prescriptions, lab results, invoices, profile
    nurse/         admissions, vitals, ICU charting, EMAR, OT, ER, blood bank, rounds, shift handover
    receptionist/  OPD queue, billing, insurance claims, radiology orders, referrals
    lab/           lab orders, test catalogue, dashboard
    pharmacy/      drug master, dispensing
    staff/         dashboard
  main.dart
```

Each feature follows the same pattern: `models/` (API DTOs), `viewmodels/` (`ChangeNotifier` + `provider`), `screens/` (UI), and `widgets/` for anything reused within the feature.

## Auth

Login/registration go through Laravel Sanctum; the returned bearer token is stored on-device via `flutter_secure_storage` (`AuthStorage`) and sent as `Authorization: Bearer <token>` on every request. On launch, `SessionViewModel` validates the saved token against `/me` and falls back to the login screen if it's missing or expired.

## Testing

```bash
flutter test
```

Currently limited to a smoke test that the app builds and shows the startup gate.
