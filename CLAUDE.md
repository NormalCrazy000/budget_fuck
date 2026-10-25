# CLAUDE.md — Budget Tracker

## Project overview

Cross-platform Flutter app for tracking monthly income and expenses.
- **Language:** Dart 3.9.2+ (Flutter 3.47.8, pinned in CI)
- **Framework:** Flutter (Material Design 3)
- **State Management:** Provider (ChangeNotifier)
- **Database:** Hive (local NoSQL)
- **Application ID:** `io.github.normalcrazy000.budgettracker` (Dart package: `budget_fuck`)
- **Current version:** see `pubspec.yaml`

## Features

- Add transactions (income and expenses) with amount, category and date
- View the month's transaction list with totals (income, expenses, balance)
- Per-category statistics with amounts, percentages and progress bars
- Navigate between months with a month/year selector
- Delete transactions, templates and categories via swipe + confirmation dialog
- **Predefined templates**: create recurring transaction templates (salary, rent, bills, etc.)
- **Template application**: apply templates in bulk or selectively to any month
- **Backup & Restore**: export all data to JSON and re-import it (replace or merge mode). Export via "Salva su file" (system "Save as" dialog: on Android any folder, e.g. Download or Drive) or "Condividi" (share sheet, Android/iOS only)
- **Search**: search bar on categories, templates and the month's transactions (case- and accent-insensitive); similar existing categories suggested while creating one; searchable category picker when adding transactions/templates
- Local data persistence (data survives app restarts). Hive directory: app documents dir on Android/iOS, app support dir on desktop (Linux: `~/.local/share/<application id>`), see `lib/services/storage_location.dart`
- Material 3 UI with Italian localization

## Structure

```
lib/
├── main.dart                  # Entry point, Hive setup + MultiProvider
├── models/                    # Data with @HiveType annotations
│   ├── transaction.dart           # typeId: 0
│   ├── transaction_template.dart  # typeId: 1
│   └── category.dart              # typeId: 2
├── providers/                 # State management (ChangeNotifier)
├── screens/                   # UI screens
│   ├── home_screen.dart           # Main screen with transaction list
│   ├── stats_screen.dart          # Per-category statistics (expenses/income) by month
│   ├── backup_screen.dart         # JSON export/import (backup & restore)
│   ├── add_transaction_screen.dart
│   ├── categories_screen.dart
│   ├── templates_screen.dart
│   ├── add_template_screen.dart
│   └── apply_templates_screen.dart
├── services/
│   ├── backup_service.dart        # JSON serialization/deserialization
│   └── storage_location.dart      # Hive data directory per platform
├── utils/
│   └── search.dart                # matchesSearch(): case/accent-insensitive matching
└── widgets/                   # Reusable components (SearchField, CategoryPickerField, ...)
```

`*.g.dart` files are **auto-generated** — do not edit them by hand.

## Platform prerequisites

### Linux
```bash
sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
flutter config --enable-linux-desktop
```

### Android
- Android Studio with Android SDK (API level 21+, Android 5.0+)
- Java JDK 17
- Physical device with USB debugging enabled, or an AVD emulator

### macOS
- Xcode from the App Store (with Command Line Tools)
- CocoaPods: `sudo gem install cocoapods`
- `flutter config --enable-macos-desktop`

## Main commands

```bash
# Setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Continuous generation (watch mode)
dart run build_runner watch --delete-conflicting-outputs

# Run (debug)
flutter run -d linux
flutter run -d android
flutter run -d macos
flutter devices          # list available devices

# Unit and widget tests
flutter test

# Single test file
flutter test test/widgets/stats_screen_test.dart

# Integration tests (require a device/emulator)
flutter test integration_test/add_transactions_test.dart -d linux
flutter test integration_test/totals_test.dart -d linux
flutter test integration_test/persistence_test.dart -d linux
flutter test integration_test/month_filter_test.dart -d linux
flutter test integration_test/templates_test.dart -d linux
flutter test integration_test/delete_confirmation_test.dart -d linux

# Release build
flutter build linux --release
flutter build apk --release
flutter build appbundle --release   # App Bundle for Google Play Store
flutter install                     # install directly on a connected device

# Build artifacts
# Linux:   build/linux/x64/release/bundle/budget_fuck
# APK:     build/app/outputs/flutter-apk/app-release.apk
# AAB:     build/app/outputs/bundle/release/app-release.aab

# Release automation (version + optional Markdown release notes file)
./scripts/release.sh <VERSION> [NOTES_FILE]
# e.g. ./scripts/release.sh 2.6.0 notes.md
#
# The script:
# 1. Validates the x.y.z format
# 2. Checks there are no uncommitted changes
# 3. Checks the vVERSION tag does not already exist
# 4. Checks out main + pull
# 5. Uses NOTES_FILE as release notes, or generates them from feat/fix commits
#    since the last tag (chore/ci/docs are hidden)
# 6. Updates pubspec.yaml with VERSION+<commit count> and commits
# 7. Creates the annotated vVERSION tag (message = release notes) and pushes main + tag
# → GitHub Actions triggers automatically on the tag push and builds the APK
```

## Code conventions

- **Classes:** PascalCase (`Transaction`, `HomeScreen`)
- **Methods/Variables:** camelCase (`getTransactionsByMonth`, `_selectedMonth`)
- **File names:** snake_case (`transaction_provider.dart`)
- Linting: `flutter_lints` (see `analysis_options.yaml`)

### Hive TypeId schema

| TypeId | Model |
|--------|-------|
| 0 | Transaction |
| 1 | TransactionTemplate |
| 2 | Category |

When adding a new Hive model, use the next available typeId and regenerate with `build_runner`.

## Commit convention

```
feat:           new feature
fix:            bug fix
chore(release): release tasks
```

## Branching

- Trunk-based: `main` is the only long-lived branch (protected against deletion and force-push)
- Work on short-lived branches (e.g. `feat/xyz`, `fix/xyz`) merged into `main` via PR, then delete them
- Release: run `./scripts/release.sh <VERSION> [NOTES_FILE]` from `main` → the script bumps the version, commits, tags and pushes → GitHub Actions builds the APK and creates the GitHub Release
- Open PRs before a release: before tagging, Claude checks the open pull requests (the repo is public, so `curl -s https://api.github.com/repos/NormalCrazy000/budget_fuck/pulls?state=open` works without `gh`). For each PR:
  1. read what it changes (`git fetch origin pull/<N>/head:pr-<N>` + `git diff main...pr-<N>`; for Dependabot also the changelog in the PR body, looking for breaking changes)
  2. check its CI status (`/commits/<sha>/check-runs`) and run `flutter analyze` + `flutter test` locally on it
  3. explain to the user in plain terms what it does and the risk, and recommend merge / close / wait
  4. only with the user's OK, merge it into `main` (fast-forward or rebase, then push) before running `release.sh`; included changes go in the release notes if they matter to app users
- Release notes: before a release, Claude reads the commits since the last tag and writes user-facing notes in **English** (`## What's new`, `## Fixes`; only what changes for app users, no chore/ci/docs), shows them to the user for approval, saves them in the scratchpad and passes the file to `release.sh`

## Main dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| `hive` | ^2.2.3 | Local NoSQL database |
| `hive_flutter` | ^1.1.0 | Hive integration with Flutter |
| `provider` | ^6.1.2 | State management |
| `intl` | ^0.19.0 | Date/currency formatting (Italian) |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `path_provider` | ^2.1.4 | Documents directory for the backup file |
| `share_plus` | ^13.3.1 | File sharing on Android/iOS |
| `file_picker` | ^13.2.0 | JSON file selection on import, "Save as" dialog on export |

### Dev dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| `hive_generator` | ^2.0.1 | Generates TypeAdapters for Hive models |
| `build_runner` | ^2.4.13 | Runs Dart code generators |
| `flutter_lints` | ^5.0.0 | Linting rules for Flutter |
| `integration_test` | SDK | End-to-end tests |
| `flutter_test` | SDK | Widget and unit tests |

## Testing conventions

### Unit tests (providers)
- Use real Hive on a temporary directory (`Directory.systemTemp.createTemp`)
- `setUp`/`tearDown` open and close the Hive box
- Always verify the adapter's `typeId` with `isAdapterRegistered`

### Widget tests (screens/widgets)
- Use a `FakeProvider` that implements the real provider without Hive
- The pattern is `class FakeXProvider extends ChangeNotifier implements XProvider`
- Minimal wrapper: `MaterialApp > ChangeNotifierProvider.value > Widget`
- Screens using `DateFormat` with the `it` locale require `initializeDateFormatting('it', null)` in `setUpAll`
- The currency format `NumberFormat.currency(locale: 'it_IT', symbol: '€')` produces `"50,00 €"` (symbol after, non-breaking space) — use `find.textContaining(...)` to avoid depending on the separator

### Integration tests
- Use the helpers in `integration_test/test_helpers.dart`:
  - `resetStorage(categories: [...])` clears the boxes in a temp directory (`testStoragePath`) and seeds categories (required by the add forms)
  - `startApp(tester)` runs the real app on that directory
  - `addTransaction(...)`, `selectCategory(...)` drive the current forms (amount + searchable category picker)
  - `swipeToDelete(tester, text)` drags almost the full row width (a short fling is flaky on desktop windows) and waits for the confirm dialog
  - `waitFor(tester, finder)` after Hive writes: the UI can update just after `pumpAndSettle` (e.g. totals after a delete)
- **Never** use `Hive.initFlutter()` or `app.main()` in integration tests: they clear the boxes, and without the temp directory they would wipe the real app data on desktop

### Pure tests (BackupService)
- No Hive or Flutter dependency: only static Dart functions are tested
- Verify full round-trip and handling of mixed numeric types (int/double in JSON)

### Test files
```
test/
├── backup_service_test.dart         # Unit tests for JSON serialization/deserialization
├── category_provider_test.dart      # Unit tests for the category provider (real Hive)
├── provider_backup_test.dart        # Unit tests for replaceAll/addAll on all three providers
├── search_test.dart                 # Unit tests for matchesSearch/normalizeForSearch
├── template_provider_test.dart      # Unit tests for the template provider (real Hive)
├── confirm_delete_dialog_test.dart  # Widget test for the confirmation dialog
├── widget_test.dart                 # Smoke test (placeholder)
└── widgets/
    ├── backup_screen_test.dart      # Widget test for the backup screen (rendering and buttons)
    ├── categories_screen_test.dart  # Widget test for the categories screen (incl. search and suggestions)
    ├── category_picker_field_test.dart # Widget test for the searchable category picker
    ├── home_screen_test.dart        # Widget test for transaction search on the home screen
    ├── stats_screen_test.dart       # Widget test for the statistics screen (13 cases)
    ├── template_tile_test.dart      # Widget test for the template tile
    ├── templates_screen_test.dart   # Widget test for template search
    └── transaction_tile_test.dart   # Widget test for the transaction tile
```

## CI/CD

GitHub Actions `.github/workflows/ci.yml` runs on every push and pull request to `main`:
`flutter pub get` → `build_runner` → `flutter analyze` (infos are fatal) → `flutter test`.
Integration tests use `print` for step progress and opt out of `avoid_print` with `// ignore_for_file`.

Dependabot (`.github/dependabot.yml`) opens monthly PRs to `main` for pub packages (minor/patch grouped) and GitHub Actions.

GitHub Actions `.github/workflows/flutter_ci.yml` triggers on push of a `v*` tag:
1. Setup Java 17 + Flutter 3.47.8 (pinned for reproducible builds; when upgrading Flutter, align Gradle/AGP/Kotlin in `android/` with a fresh `flutter create` project)
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter test`
5. Read the release notes from the annotated tag message (used as the GitHub Release body, followed by GitHub's "Full Changelog" link)
6. Rebuild `android/app/release.jks` + `android/key.properties` from GitHub Secrets
7. `flutter build apk --release`
8. Creates a GitHub Release with the APK attached and auto-generated release notes

## Release signing

- `android/app/build.gradle.kts` reads `android/key.properties`; if missing, release builds fall back to the debug key
- `key.properties`, `*.jks` and `*.keystore` are git-ignored (`android/.gitignore`) — **never commit them, never write real values in docs or code**
- CI secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`
- `key.properties` is a Java properties file: `\` is an escape character and must be doubled. The workflow escapes secret values when writing it; do the same when creating it by hand
- If the repository variable `REQUIRE_RELEASE_SIGNING` is `true` (set on the official repo), the workflow **fails** when the secrets are missing, to avoid publishing a debug-signed APK; without it (e.g. forks) it falls back to debug signing with a warning
- The keystore must stay the same forever: a different key means users cannot update over the installed app (they would have to uninstall and lose their local Hive data). Keep an off-machine backup of the keystore and its passwords
- To rotate the CI secrets: `base64 -w0 <keystore>.jks` → update `KEYSTORE_BASE64` in *Settings → Secrets and variables → Actions*
