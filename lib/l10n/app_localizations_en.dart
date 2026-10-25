// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Budget Tracker';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get incomeTotal => 'Income';

  @override
  String get expensesTotal => 'Expenses';

  @override
  String get balance => 'Balance';

  @override
  String get statistics => 'Statistics';

  @override
  String get manageCategories => 'Manage categories';

  @override
  String get manageTemplates => 'Manage templates';

  @override
  String get applyTemplates => 'Apply templates';

  @override
  String get settings => 'Settings';

  @override
  String get backupAndRestore => 'Backup & restore';

  @override
  String get searchByCategory => 'Search by category';

  @override
  String get searchCategory => 'Search category';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noResults => 'No results';

  @override
  String get noTransactionsThisMonth => 'No transactions this month';

  @override
  String get categories => 'Categories';

  @override
  String get noCategories => 'No categories';

  @override
  String get newCategory => 'New category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryNameEmpty => 'The name cannot be empty';

  @override
  String get categoryAlreadyExists => 'Category already exists';

  @override
  String get similarExistingCategories => 'Already existing:';

  @override
  String get category => 'Category';

  @override
  String get selectCategory => 'Select a category';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get change => 'Change';

  @override
  String get delete => 'Delete';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get amountLabel => 'Amount (€)';

  @override
  String get enterAmount => 'Enter an amount';

  @override
  String get enterValidAmount => 'Enter a valid amount';

  @override
  String get confirmDeletion => 'Confirm deletion';

  @override
  String confirmDeletionMessage(String item) {
    return 'Are you sure you want to delete $item?';
  }

  @override
  String get noExpensesThisMonth => 'No expenses this month';

  @override
  String get noIncomeThisMonth => 'No income this month';

  @override
  String get totalExpenses => 'Total expenses';

  @override
  String get totalIncome => 'Total income';

  @override
  String transactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get templates => 'Templates';

  @override
  String get noTemplates => 'No templates';

  @override
  String get newTemplate => 'New template';

  @override
  String get noTemplatesAvailable => 'No templates available';

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String applyCount(int count) {
    return 'Apply ($count)';
  }

  @override
  String get backupDescription =>
      'Export all your data to a JSON file or import a previous backup.';

  @override
  String get saveToFile => 'Save to file';

  @override
  String get share => 'Share';

  @override
  String get importBackup => 'Import backup';

  @override
  String get saveBackupDialogTitle => 'Save backup';

  @override
  String get backupSaved => 'Backup saved';

  @override
  String backupSavedTo(String path) {
    return 'Backup saved to: $path';
  }

  @override
  String exportError(String error) {
    return 'Export error: $error';
  }

  @override
  String invalidFile(String error) {
    return 'Invalid file: $error';
  }

  @override
  String get importMode => 'Import mode';

  @override
  String importSummary(int transactions, int categories, int templates) {
    String _temp0 = intl.Intl.pluralLogic(
      transactions,
      locale: localeName,
      other: '$transactions transactions',
      one: '1 transaction',
    );
    String _temp1 = intl.Intl.pluralLogic(
      categories,
      locale: localeName,
      other: '$categories categories',
      one: '1 category',
    );
    String _temp2 = intl.Intl.pluralLogic(
      templates,
      locale: localeName,
      other: '$templates templates',
      one: '1 template',
    );
    return 'Found:\n• $_temp0\n• $_temp1\n• $_temp2\n\nHow do you want to proceed?';
  }

  @override
  String get merge => 'Merge';

  @override
  String get replaceAll => 'Replace all';

  @override
  String get importCompleted => 'Import completed';

  @override
  String importError(String error) {
    return 'Import error: $error';
  }

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Automatic (device language)';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languageEnglish => 'English';
}
