# Budget Tracker

App Flutter per tracciare entrate e uscite mensili con report, lista transazioni e totali. Supporta template predefiniti per inserire transazioni ricorrenti in blocco. Storage locale con Hive, state management con Provider.

## Funzionalita

- Aggiungere transazioni (entrate e uscite) con descrizione, importo e data
- Visualizzare lista transazioni del mese con totali (entrate, uscite, bilancio)
- Navigare tra i mesi con selettore mese/anno
- Eliminare transazioni, template e categorie con swipe + dialog di conferma
- **Template predefiniti**: creare template di transazioni ricorrenti (stipendio, affitto, bollette, ecc.)
- **Applicazione template**: applicare template in blocco o parzialmente a qualsiasi mese
- Persistenza locale dei dati (i dati sopravvivono alla chiusura dell'app)
- Interfaccia Material 3 con localizzazione italiana

## Struttura Progetto

```
lib/
├── main.dart                          # Entry point, setup Hive + MultiProvider
├── models/
│   ├── transaction.dart               # Modello Transaction (Hive typeId: 0)
│   ├── transaction.g.dart             # TypeAdapter generato automaticamente
│   ├── transaction_template.dart      # Modello TransactionTemplate (Hive typeId: 1)
│   └── transaction_template.g.dart    # TypeAdapter generato automaticamente
├── providers/
│   ├── transaction_provider.dart      # Provider per gestire le transazioni
│   └── template_provider.dart         # Provider per gestire i template predefiniti
├── screens/
│   ├── home_screen.dart               # Schermata principale con report
│   ├── add_transaction_screen.dart    # Form per aggiungere entrata/uscita
│   ├── templates_screen.dart          # Lista e gestione template predefiniti
│   ├── add_template_screen.dart       # Form per creare un nuovo template
│   └── apply_templates_screen.dart    # Applicazione template a un mese
└── widgets/
    ├── confirm_delete_dialog.dart     # Dialog riutilizzabile di conferma eliminazione
    ├── transaction_tile.dart          # Widget per singola transazione nella lista
    └── template_tile.dart             # Widget per singolo template nella lista
```

## Librerie

### Dipendenze principali

| Libreria | Versione | Descrizione |
|----------|----------|-------------|
| [hive](https://pub.dev/packages/hive) | ^2.2.3 | Database NoSQL locale leggero e veloce, basato su file binari |
| [hive_flutter](https://pub.dev/packages/hive_flutter) | ^1.1.0 | Integrazione Hive con Flutter (inizializzazione path e widget) |
| [provider](https://pub.dev/packages/provider) | ^6.1.2 | State management reattivo tramite ChangeNotifier e InheritedWidget |
| [intl](https://pub.dev/packages/intl) | ^0.19.0 | Formattazione date e valute con supporto locale (italiano) |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | ^1.0.8 | Set di icone stile iOS per Flutter |

### Dipendenze di sviluppo

| Libreria | Versione | Descrizione |
|----------|----------|-------------|
| [hive_generator](https://pub.dev/packages/hive_generator) | ^2.0.1 | Genera automaticamente i TypeAdapter per i modelli Hive |
| [build_runner](https://pub.dev/packages/build_runner) | ^2.4.13 | Tool per eseguire generatori di codice Dart (usato con hive_generator) |
| [flutter_lints](https://pub.dev/packages/flutter_lints) | ^5.0.0 | Regole di linting raccomandate per progetti Flutter |
| [integration_test](https://flutter.dev) | SDK Flutter | Framework per test di integrazione end-to-end |
| [flutter_test](https://flutter.dev) | SDK Flutter | Framework per widget test e unit test |

## Prerequisiti

- **Flutter SDK** >= 3.9.2
- **Dart SDK** >= 3.9.2

### Prerequisiti per piattaforma

#### Linux
```bash
sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
```

#### Android
- **Android Studio** con Android SDK installato
- **Android SDK** API level 21+ (Android 5.0 Lollipop o superiore)
- **Java JDK** 17
- Un dispositivo fisico connesso via USB (con debug USB attivo) oppure un emulatore AVD configurato

#### macOS
- **Xcode** installato da App Store (con Command Line Tools)
- **CocoaPods**: `sudo gem install cocoapods`

## Setup

```bash
# Clonare il repository
git clone <url-repo>
cd budget_fuck

# Installare le dipendenze
flutter pub get

# Generare i TypeAdapter di Hive (necessario dopo modifiche al modello)
dart run build_runner build --delete-conflicting-outputs
```

## Build

### Linux

```bash
# Verificare che la piattaforma sia abilitata
flutter config --enable-linux-desktop

# Build di debug
flutter build linux --debug

# Build di release (ottimizzato)
flutter build linux --release
```

L'eseguibile viene generato in:
```
build/linux/x64/release/bundle/budget_fuck
```

Per eseguirlo direttamente:
```bash
./build/linux/x64/release/bundle/budget_fuck
```

### Android

```bash
# Build APK di debug
flutter build apk --debug

# Build APK di release
flutter build apk --release

# Build App Bundle per Google Play Store
flutter build appbundle --release
```

I file generati si trovano in:
```
build/app/outputs/flutter-apk/app-release.apk          # APK
build/app/outputs/bundle/release/app-release.aab        # App Bundle
```

Per installare direttamente su un dispositivo connesso:
```bash
flutter install
```

### macOS

```bash
# Verificare che la piattaforma sia abilitata
flutter config --enable-macos-desktop

# Build di debug
flutter build macos --debug

# Build di release
flutter build macos --release
```

L'app viene generata in:
```
build/macos/Build/Products/Release/budget_fuck.app
```

## Esecuzione in modalita sviluppo

```bash
# Eseguire su Linux
flutter run -d linux

# Eseguire su Android (dispositivo connesso o emulatore)
flutter run -d android

# Eseguire su macOS
flutter run -d macos

# Elencare i dispositivi disponibili
flutter devices
```

## Test

```bash
# Unit test
flutter test

# Integration test (richiede un dispositivo/desktop)
flutter test integration_test/add_transactions_test.dart -d linux
flutter test integration_test/totals_test.dart -d linux
flutter test integration_test/persistence_test.dart -d linux
flutter test integration_test/month_filter_test.dart -d linux
flutter test integration_test/templates_test.dart -d linux
flutter test integration_test/delete_confirmation_test.dart -d linux
```

## Generazione codice

Dopo aver modificato i modelli Hive (file con annotazioni `@HiveType`), rigenerare i TypeAdapter:

```bash
# Generazione singola
dart run build_runner build --delete-conflicting-outputs

# Generazione continua (watch mode, rigenera ad ogni salvataggio)
dart run build_runner watch --delete-conflicting-outputs
```
