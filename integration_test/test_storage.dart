import 'dart:io';

/// Cartella temporanea per i dati Hive dei test di integrazione.
///
/// I test cancellano i box all'avvio: usando questa cartella (passata anche
/// a `runBudgetApp`) non toccano mai i dati reali dell'app.
final String testStoragePath =
    Directory.systemTemp.createTempSync('budget_tracker_it_').path;
