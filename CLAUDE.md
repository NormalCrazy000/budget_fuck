# CLAUDE.md — Budget Tracker

## Panoramica progetto

App Flutter cross-platform per il tracciamento di entrate e uscite mensili.
- **Linguaggio:** Dart 3.9.2+
- **Framework:** Flutter (Material Design 3)
- **State Management:** Provider (ChangeNotifier)
- **Database:** Hive (NoSQL locale)
- **Package:** `com.budgetfuck.budget_fuck`
- **Versione attuale:** controllare `pubspec.yaml`

## Funzionalità

- Aggiungere transazioni (entrate e uscite) con importo, categoria e data
- Visualizzare lista transazioni del mese con totali (entrate, uscite, bilancio)
- Statistiche per categoria con importi, percentuali e barre di progresso
- Navigare tra i mesi con selettore mese/anno
- Eliminare transazioni, template e categorie con swipe + dialog di conferma
- **Template predefiniti**: creare template di transazioni ricorrenti (stipendio, affitto, bollette, ecc.)
- **Applicazione template**: applicare template in blocco o parzialmente a qualsiasi mese
- **Backup & Ripristino**: esportare tutti i dati in JSON e reimportarli (con modalità sostituisci o unisci)
- Persistenza locale dei dati (i dati sopravvivono alla chiusura dell'app)
- Interfaccia Material 3 con localizzazione italiana

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
│   ├── home_screen.dart           # Schermata principale con lista transazioni
│   ├── stats_screen.dart          # Statistiche per categoria (uscite/entrate) per mese
│   ├── backup_screen.dart         # Export/import JSON (backup & ripristino)
│   ├── add_transaction_screen.dart
│   ├── categories_screen.dart
│   ├── templates_screen.dart
│   ├── add_template_screen.dart
│   └── apply_templates_screen.dart
├── services/
│   └── backup_service.dart        # Serializzazione/deserializzazione JSON
└── widgets/                   # Componenti riutilizzabili
```

File `*.g.dart` sono **generati automaticamente** — non modificarli manualmente.

## Prerequisiti per piattaforma

### Linux
```bash
sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
flutter config --enable-linux-desktop
```

### Android
- Android Studio con Android SDK (API level 21+, Android 5.0+)
- Java JDK 17
- Dispositivo fisico con debug USB attivo oppure emulatore AVD

### macOS
- Xcode da App Store (con Command Line Tools)
- CocoaPods: `sudo gem install cocoapods`
- `flutter config --enable-macos-desktop`

## Comandi principali

```bash
# Setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs

# Generazione continua (watch mode)
dart run build_runner watch --delete-conflicting-outputs

# Run (debug)
flutter run -d linux
flutter run -d android
flutter run -d macos
flutter devices          # elenca i dispositivi disponibili

# Test unitari e widget
flutter test

# Test di un singolo file
flutter test test/widgets/stats_screen_test.dart

# Integration test (richiedono device/emulatore)
flutter test integration_test/add_transactions_test.dart -d linux
flutter test integration_test/totals_test.dart -d linux
flutter test integration_test/persistence_test.dart -d linux
flutter test integration_test/month_filter_test.dart -d linux
flutter test integration_test/templates_test.dart -d linux
flutter test integration_test/delete_confirmation_test.dart -d linux

# Build release
flutter build linux --release
flutter build apk --release
flutter build appbundle --release   # App Bundle per Google Play Store
flutter install                     # installa direttamente su dispositivo connesso

# Artefatti di build
# Linux:   build/linux/x64/release/bundle/budget_fuck
# APK:     build/app/outputs/flutter-apk/app-release.apk
# AAB:     build/app/outputs/bundle/release/app-release.aab

# Release automation (richiede un solo argomento: versione da rilasciare)
./scripts/release.sh <VERSION>
# es. ./scripts/release.sh 2.2.0
#
# Lo script:
# 1. Valida il formato x.y.z
# 2. Controlla che non ci siano modifiche non committate
# 3. Controlla che il tag vVERSION non esista già
# 4. Checkout develop + pull
# 5. Checkout main + pull
# 6. Merge develop → main (--no-ff)
# 7. Aggiorna pubspec.yaml con VERSION+<numero commit> e committa
# 8. Crea il tag vVERSION e pusha main + tag su origin
# 9. Checkout develop + merge main → develop (--no-ff) + push
# → GitHub Actions si attiva automaticamente al push del tag e builda l'APK
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
- Release: eseguire `./scripts/release.sh <VERSION>` sul branch desiderato → lo script committa, tagga e pusha → GitHub Actions builda l'APK e crea la GitHub Release

## Dipendenze principali

| Libreria | Versione | Uso |
|----------|----------|-----|
| `hive` | ^2.2.3 | Database NoSQL locale |
| `hive_flutter` | ^1.1.0 | Integrazione Hive con Flutter |
| `provider` | ^6.1.2 | State management |
| `intl` | ^0.19.0 | Formattazione date/valute (italiano) |
| `cupertino_icons` | ^1.0.8 | Icone stile iOS |
| `path_provider` | ^2.1.4 | Directory documenti per il file di backup |
| `share_plus` | ^10.0.0 | Condivisione file su Android/iOS |
| `file_picker` | ^8.1.6 | Selezione file JSON durante l'import |

### Dipendenze di sviluppo

| Libreria | Versione | Uso |
|----------|----------|-----|
| `hive_generator` | ^2.0.1 | Genera TypeAdapter per i modelli Hive |
| `build_runner` | ^2.4.13 | Esegue i generatori di codice Dart |
| `flutter_lints` | ^5.0.0 | Regole di linting per Flutter |
| `integration_test` | SDK | Test end-to-end |
| `flutter_test` | SDK | Widget test e unit test |

## Convenzioni per i test

### Test unitari (provider)
- Usano Hive reale su directory temporanea (`Directory.systemTemp.createTemp`)
- `setUp`/`tearDown` aprono e chiudono il box Hive
- Verificare sempre il `typeId` dell'adapter con `isAdapterRegistered`

### Test widget (screen/widget)
- Usano un `FakeProvider` che implementa il provider reale senza Hive
- Il pattern è `class FakeXProvider extends ChangeNotifier implements XProvider`
- Wrapper minimo: `MaterialApp > ChangeNotifierProvider.value > Widget`
- Le schermate che usano `DateFormat` con locale `it` richiedono `initializeDateFormatting('it', null)` in `setUpAll`
- Il formato valuta `NumberFormat.currency(locale: 'it_IT', symbol: '€')` produce `"50,00 €"` (simbolo dopo, spazio non-breaking) — usare `find.textContaining(...)` per evitare dipendenze dal separatore

### Test puri (BackupService)
- Nessuna dipendenza da Hive o Flutter: si testano solo funzioni statiche Dart
- Verificano round-trip completo e gestione tipi numerici misti (int/double nel JSON)

### File di test
```
test/
├── backup_service_test.dart         # Unit test serializzazione/deserializzazione JSON
├── category_provider_test.dart      # Unit test provider categorie (con Hive reale)
├── provider_backup_test.dart        # Unit test replaceAll/addAll su tutti e tre i provider
├── template_provider_test.dart      # Unit test provider template (con Hive reale)
├── confirm_delete_dialog_test.dart  # Widget test dialog conferma
├── widget_test.dart                 # Smoke test (placeholder)
└── widgets/
    ├── backup_screen_test.dart      # Widget test schermata backup (rendering e pulsanti)
    ├── categories_screen_test.dart  # Widget test schermata categorie
    ├── stats_screen_test.dart       # Widget test schermata statistiche (13 casi)
    ├── template_tile_test.dart      # Widget test tile template
    └── transaction_tile_test.dart   # Widget test tile transazione
```

## CI/CD

GitHub Actions (`.github/workflows/flutter_ci.yml`) si attiva al push di un tag `v*`:
1. Setup Java 17 + Flutter stable
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. `flutter test`
5. `flutter build apk --release`
6. Crea una GitHub Release con l'APK allegato e note di release generate automaticamente
