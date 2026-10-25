# Budget Tracker

A simple, offline-first Flutter app to track monthly income and expenses.

All data is stored locally on the device — no account, no cloud, no tracking.

> **Note:** the app UI is currently available in **Italian** only.

## Features

- **Transactions** — add income and expenses with amount, category and date
- **Monthly overview** — browse transactions month by month with income, expense and balance totals
- **Statistics** — per-category breakdown with amounts, percentages and progress bars
- **Categories** — create and manage your own income/expense categories
- **Templates** — define recurring transactions (salary, rent, bills, …) and apply them to any month, all at once or selectively
- **Backup & restore** — export all data to a JSON file and import it back, either replacing or merging with existing data
- **Safe deletes** — swipe to delete with a confirmation dialog
- **Material 3** design

<!--
## Screenshots

| Home | Statistics | Templates |
|------|------------|-----------|
| ![Home](docs/screenshots/home.png) | ![Statistics](docs/screenshots/stats.png) | ![Templates](docs/screenshots/templates.png) |
-->

## Download

The latest Android APK is available on the [Releases page](https://github.com/NormalCrazy000/budget_fuck/releases/latest).

## Supported platforms

Budget Tracker is designed primarily for **Android**. The other platforms come from the Flutter project template and are kept for convenience, but are not actively maintained.

| Platform | Status |
|----------|--------|
| Android  | ✅ Built and released via CI |
| Linux    | ✅ Tested (integration tests run on Linux desktop) |
| macOS, iOS, Windows, Web | ⚠️ Scaffolding present, not tested |

## Building from source

### Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) **3.47.x** (the version used by CI)
- **Android:** Android SDK and Java JDK 17
- **Linux:** `clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev`

### Setup

```bash
git clone https://github.com/NormalCrazy000/budget_fuck.git
cd budget_fuck
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # generates Hive adapters (*.g.dart)
```

### Run

```bash
flutter run -d linux
flutter run -d android
```

### Build

```bash
flutter build apk --release      # build/app/outputs/flutter-apk/app-release.apk
flutter build linux --release    # build/linux/x64/release/bundle/
```

Release builds without `android/key.properties` are signed with the debug key — fine for local testing, but not for distribution.

### Signing your own release builds

If you fork the project and want to distribute your own APK, create **your own** signing key. Android only accepts an update if it is signed with the same key as the installed version, so keep the key safe: if you lose it, you can no longer ship updates.

> Also change the `applicationId` in `android/app/build.gradle.kts`, so your build does not conflict with the official app on the same device.

1. Generate a keystore (outside the repository):

   ```bash
   keytool -genkey -v -keystore ~/keys/release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```

2. Create `android/key.properties` (already git-ignored — never commit it):

   ```properties
   storeFile=/home/you/keys/release.jks
   storePassword=your-store-password
   keyAlias=release
   keyPassword=your-key-password
   ```

   `storeFile` can be absolute or relative to `android/app/`. In this file `\` is an escape character: if a password contains a backslash, write it twice (`\\`). The CI workflow does this automatically.

3. Build with `flutter build apk --release` — the release signing config is picked up automatically.

#### CI (GitHub Actions)

The release workflow rebuilds the keystore from these repository secrets (*Settings → Secrets and variables → Actions*):

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | the keystore file, base64-encoded: `base64 -w0 ~/keys/release.jks` |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key password |

Without these secrets the workflow still runs, signing the APK with the debug key and emitting a warning. To make missing secrets a hard failure instead, add the repository variable `REQUIRE_RELEASE_SIGNING` = `true` (*Settings → Secrets and variables → Actions → Variables*).

## Testing

```bash
# Unit and widget tests
flutter test

# Integration tests (require a device or desktop target)
flutter test integration_test/ -d linux
```

## Tech stack

| | |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Material 3) |
| State management | [provider](https://pub.dev/packages/provider) |
| Local storage | [Hive](https://pub.dev/packages/hive) |
| Formatting / i18n | [intl](https://pub.dev/packages/intl) |
| Backup | [path_provider](https://pub.dev/packages/path_provider), [share_plus](https://pub.dev/packages/share_plus), [file_picker](https://pub.dev/packages/file_picker) |

### Project structure

```
lib/
├── main.dart       # Entry point: Hive setup + providers
├── models/         # Hive data models (Transaction, TransactionTemplate, Category)
├── providers/      # ChangeNotifier state management
├── screens/        # App screens
├── services/       # JSON backup serialization
└── widgets/        # Reusable UI components
```

## Privacy

Budget Tracker does not collect, transmit or share any data. Everything is stored locally on your device; backups are plain JSON files that you export and keep yourself.

## License

Released under the [MIT License](LICENSE).
