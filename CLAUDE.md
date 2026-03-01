# CLAUDE.md — Budget Tracker

## Panoramica progetto

App Flutter cross-platform per il tracciamento di entrate e uscite mensili.
- **Linguaggio:** Dart 3.9.2+
- **Framework:** Flutter (Material Design 3)
- **State Management:** Provider (ChangeNotifier)
- **Database:** Hive (NoSQL locale)
- **Package:** `com.budgetfuck.budget_fuck`
- **Versione attuale:** controllare `pubspec.yaml`

## Struttura

```
lib/
├── main.dart                  # Entry point, setup Hive + MultiProvider
├── models/                    # Dati con @HiveType annotations
│   ├── transaction.dart           # typeId: 0
│   ├── transaction_template.dart  # typeId: 1
│   └── category.dart              # typeId: 2
├── providers/                 # State management (ChangeNotifier)
├── screens/                   # Schermate UI
└── widgets/                   # Componenti riutilizzabili
```

File `*.g.dart` sono **generati automaticamente** — non modificarli manualmente.

## Comandi principali

```bash
# Setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Run (debug)
flutter run -d linux

# Test unitari e widget
flutter test

# Integration test (richiedono device/emulatore)
flutter test integration_test/<nome_test>.dart -d linux

# Build release
flutter build linux --release
flutter build apk --release

# Release automation
./scripts/release.sh <VERSION>   # es. ./scripts/release.sh 2.2.0
```

## Convenzioni di codice

- **Classes:** PascalCase (`Transaction`, `HomeScreen`)
- **Methods/Variables:** camelCase (`getTransactionsByMonth`, `_selectedMonth`)
- **File names:** snake_case (`transaction_provider.dart`)
- Linting: `flutter_lints` (vedi `analysis_options.yaml`)

### Hive TypeId schema

| TypeId | Modello |
|--------|---------|
| 0 | Transaction |
| 1 | TransactionTemplate |
| 2 | Category |

Quando si aggiunge un nuovo modello Hive, usare il prossimo typeId disponibile e rigenerare con `build_runner`.

## Commit convention

```
feat:           nuova funzionalità
fix:            bug fix
chore(release): attività di release
```

## Branching

- `develop` → branch di sviluppo principale
- `main` → branch stabile/release
- PR da feature branch → `develop`
- Release: `develop` → `main` → tag `v{VERSION}` → bump snapshot su `develop`

## Dipendenze principali

| Libreria | Uso |
|----------|-----|
| `hive` / `hive_flutter` | Persistenza locale |
| `provider` | State management |
| `intl` | Formattazione date/valute (italiano) |
| `hive_generator` + `build_runner` | Code generation |

## CI/CD

GitHub Actions (`.github/workflows/flutter_ci.yml`) su push/PR a `main` e `develop`:
1. Setup Java 17 + Flutter stable
2. `flutter pub get` + `build_runner`
3. `flutter test`
4. `flutter build apk --release`
5. Upload APK artifact (7 giorni)
