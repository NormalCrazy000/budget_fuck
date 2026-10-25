// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Budget Tracker';

  @override
  String get income => 'Entrata';

  @override
  String get expense => 'Uscita';

  @override
  String get incomeTotal => 'Entrate';

  @override
  String get expensesTotal => 'Uscite';

  @override
  String get balance => 'Bilancio';

  @override
  String get statistics => 'Statistiche';

  @override
  String get manageCategories => 'Gestisci categorie';

  @override
  String get manageTemplates => 'Gestisci template';

  @override
  String get applyTemplates => 'Applica template';

  @override
  String get settings => 'Impostazioni';

  @override
  String get backupAndRestore => 'Backup & Ripristino';

  @override
  String get searchByCategory => 'Cerca per categoria';

  @override
  String get searchCategory => 'Cerca categoria';

  @override
  String get clearSearch => 'Cancella ricerca';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get noTransactionsThisMonth => 'Nessuna transazione questo mese';

  @override
  String get categories => 'Categorie';

  @override
  String get noCategories => 'Nessuna categoria';

  @override
  String get newCategory => 'Nuova categoria';

  @override
  String get categoryName => 'Nome categoria';

  @override
  String get categoryNameEmpty => 'Il nome non può essere vuoto';

  @override
  String get categoryAlreadyExists => 'Categoria già esistente';

  @override
  String get similarExistingCategories => 'Già esistenti:';

  @override
  String get category => 'Categoria';

  @override
  String get selectCategory => 'Seleziona una categoria';

  @override
  String get cancel => 'Annulla';

  @override
  String get add => 'Aggiungi';

  @override
  String get save => 'Salva';

  @override
  String get change => 'Cambia';

  @override
  String get delete => 'Elimina';

  @override
  String get newTransaction => 'Nuova transazione';

  @override
  String get amountLabel => 'Importo (€)';

  @override
  String get enterAmount => 'Inserisci un importo';

  @override
  String get enterValidAmount => 'Inserisci un importo valido';

  @override
  String get confirmDeletion => 'Conferma eliminazione';

  @override
  String confirmDeletionMessage(String item) {
    return 'Sei sicuro di voler eliminare $item?';
  }

  @override
  String get noExpensesThisMonth => 'Nessuna uscita questo mese';

  @override
  String get noIncomeThisMonth => 'Nessuna entrata questo mese';

  @override
  String get totalExpenses => 'Totale uscite';

  @override
  String get totalIncome => 'Totale entrate';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transazioni',
      one: '1 transazione',
    );
    return '$_temp0';
  }

  @override
  String get templates => 'Template';

  @override
  String get noTemplates => 'Nessun template';

  @override
  String get newTemplate => 'Nuovo template';

  @override
  String get noTemplatesAvailable => 'Nessun template disponibile';

  @override
  String get selectAll => 'Seleziona tutti';

  @override
  String get deselectAll => 'Deseleziona tutti';

  @override
  String applyCount(int count) {
    return 'Applica ($count)';
  }

  @override
  String get backupDescription =>
      'Esporta tutti i dati in un file JSON oppure importa un backup precedente.';

  @override
  String get saveToFile => 'Salva su file';

  @override
  String get share => 'Condividi';

  @override
  String get importBackup => 'Importa backup';

  @override
  String get saveBackupDialogTitle => 'Salva backup';

  @override
  String get backupSaved => 'Backup salvato';

  @override
  String backupSavedTo(String path) {
    return 'Backup salvato in: $path';
  }

  @override
  String exportError(String error) {
    return 'Errore esportazione: $error';
  }

  @override
  String invalidFile(String error) {
    return 'File non valido: $error';
  }

  @override
  String get importMode => 'Modalità importazione';

  @override
  String importSummary(int transactions, int categories, int templates) {
    String _temp0 = intl.Intl.pluralLogic(
      transactions,
      locale: localeName,
      other: '$transactions transazioni',
      one: '1 transazione',
    );
    String _temp1 = intl.Intl.pluralLogic(
      categories,
      locale: localeName,
      other: '$categories categorie',
      one: '1 categoria',
    );
    String _temp2 = intl.Intl.pluralLogic(
      templates,
      locale: localeName,
      other: '$templates template',
      one: '1 template',
    );
    return 'Trovati:\n• $_temp0\n• $_temp1\n• $_temp2\n\nCome vuoi procedere?';
  }

  @override
  String get merge => 'Unisci';

  @override
  String get replaceAll => 'Sostituisci tutto';

  @override
  String get importCompleted => 'Importazione completata';

  @override
  String importError(String error) {
    return 'Errore importazione: $error';
  }

  @override
  String get language => 'Lingua';

  @override
  String get languageSystem => 'Automatica (lingua del telefono)';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';
}
