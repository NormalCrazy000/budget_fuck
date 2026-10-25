import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Restituisce la cartella in cui Hive salva i dati dell'app.
///
/// - Android/iOS: cartella documenti privata dell'app, la stessa usata da
///   `Hive.initFlutter()` nelle versioni precedenti (i dati esistenti restano
///   dove sono).
/// - Desktop: cartella "dati applicazione" del sistema, invece della cartella
///   Documenti dell'utente (es. su Linux `~/.local/share/<application id>`).
///
/// Non va chiamata sul web, dove Hive non usa il file system.
Future<String> appStorageDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return (await getApplicationDocumentsDirectory()).path;
  }
  return (await getApplicationSupportDirectory()).path;
}
