# CLAUDE.md — Budget Tracker

## Project overview

Cross-platform Flutter app for tracking monthly income and expenses.
- **Language:** Dart 3.9.2+
- **Framework:** Flutter (Material Design 3)
- **State Management:** Provider (ChangeNotifier)
- **Database:** Hive (local NoSQL)
- **Package:** `com.budgetfuck.budget_fuck`
- **Current version:** see `pubspec.yaml`

## Features

- Add transactions (income and expenses) with amount, category and date
- View the month's transaction list with totals (income, expenses, balance)
- Per-category statistics with amounts, percentages and progress bars
- Navigate between months with a month/year selector
- Delete transactions, templates and categories via swipe + confirmation dialog
- **Predefined templates**: create recurring transaction templates (salary, rent, bills, etc.)
- **Template application**: apply templates in bulk or selectively to any month
- **Backup & Restore**: export all data to JSON and re-import it (replace or merge mode)
- Local data persistence (data survives app restarts)
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
│   └── backup_service.dart        # JSON serialization/deserialization
└── widgets/                   # Reusable components
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

# Release automation (takes a single argument: the version to release)
./scripts/release.sh <VERSION>
# e.g. ./scripts/release.sh 2.2.0
#
# The script:
# 1. Validates the x.y.z format
# 2. Checks there are no uncommitted changes
# 3. Checks the vVERSION tag does not already exist
# 4. Checks out develop + pull
# 5. Checks out main + pull
# 6. Merges develop → main (--no-ff)
# 7. Updates pubspec.yaml with VERSION+<commit count> and commits
# 8. Creates the vVERSION tag and pushes main + tag to origin
# 9. Checks out develop + merges main → develop (--no-ff) + push
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

- `develop` → main development branch
- `main` → stable/release branch
- PRs from feature branches → `develop`
- Release: run `./scripts/release.sh <VERSION>` on the desired branch → the script commits, tags and pushes → GitHub Actions builds the APK and creates the GitHub Release

## Main dependencies

| Library | Version | Purpose |
|---------|---------|---------|
| `hive` | ^2.2.3 | Local NoSQL database |
| `hive_flutter` | ^1.1.0 | Hive integration with Flutter |
| `provider` | ^6.1.2 | State management |
| `intl` | ^0.19.0 | Date/currency formatting (Italian) |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `path_provider` | ^2.1.4 | Documents directory for the backup file |
| `share_plus` | ^10.0.0 | File sharing on Android/iOS |
| `file_picker` | ^8.1.6 | JSON file selection during import |

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

### Pure tests (BackupService)
- No Hive or Flutter dependency: only static Dart functions are tested
- Verify full round-trip and handling of mixed numeric types (int/double in JSON)

### Test files
```
test/
├── backup_service_test.dart         # Unit tests for JSON serialization/deserialization
├── category_provider_test.dart      # Unit tests for the category provider (real Hive)
├── provider_backup_test.dart        # Unit tests for replaceAll/addAll on all three providers
├── template_provider_test.dart      # Unit tests for the template provider (real Hive)
├── confirm_delete_dialog_test.dart  # Widget test for the confirmation dialog
├── widget_test.dart                 # Smoke test (placeholder)
└── widgets/
    ├── backup_screen_test.dart      # Widget test for the backup screen (rendering and buttons)
    ├── categories_screen_test.dart  # Widget test for the categories screen
    ├── stats_screen_test.dart       # Widget test for the statistics screen (13 cases)
    ├── template_tile_test.dart      # Widget test for the template tile
    └── transaction_tile_test.dart   # Widget test for the transaction tile
```

## CI/CD

GitHub Actions (`.github/workflows/flutter_ci.yml`) triggers on push of a `v*` tag:
1. Setup Java 17 + Flutter stable
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter test`
5. `flutter build apk --release`
6. Creates a GitHub Release with the APK attached and auto-generated release notes
