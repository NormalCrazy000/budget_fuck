import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget Tracker'**
  String get appTitle;

  /// Single transaction type (toggle and template subtitle)
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// Single transaction type (toggle and template subtitle)
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Home summary card and stats tab: all income of the month
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get incomeTotal;

  /// Home summary card and stats tab: all expenses of the month
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTotal;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage categories'**
  String get manageCategories;

  /// No description provided for @manageTemplates.
  ///
  /// In en, this message translates to:
  /// **'Manage templates'**
  String get manageTemplates;

  /// No description provided for @applyTemplates.
  ///
  /// In en, this message translates to:
  /// **'Apply templates'**
  String get applyTemplates;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @backupAndRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupAndRestore;

  /// No description provided for @searchByCategory.
  ///
  /// In en, this message translates to:
  /// **'Search by category'**
  String get searchByCategory;

  /// No description provided for @searchCategory.
  ///
  /// In en, this message translates to:
  /// **'Search category'**
  String get searchCategory;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @noTransactionsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get noTransactionsThisMonth;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'The name cannot be empty'**
  String get categoryNameEmpty;

  /// No description provided for @categoryAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Category already exists'**
  String get categoryAlreadyExists;

  /// No description provided for @similarExistingCategories.
  ///
  /// In en, this message translates to:
  /// **'Already existing:'**
  String get similarExistingCategories;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategory;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get newTransaction;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount (€)'**
  String get amountLabel;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get enterAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get confirmDeletion;

  /// No description provided for @confirmDeletionMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {item}?'**
  String confirmDeletionMessage(String item);

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month'**
  String get noExpensesThisMonth;

  /// No description provided for @noIncomeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No income this month'**
  String get noIncomeThisMonth;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total expenses'**
  String get totalExpenses;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get totalIncome;

  /// No description provided for @transactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String transactionCount(int count);

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @noTemplates.
  ///
  /// In en, this message translates to:
  /// **'No templates'**
  String get noTemplates;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New template'**
  String get newTemplate;

  /// No description provided for @noTemplatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No templates available'**
  String get noTemplatesAvailable;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// No description provided for @applyCount.
  ///
  /// In en, this message translates to:
  /// **'Apply ({count})'**
  String applyCount(int count);

  /// No description provided for @backupDescription.
  ///
  /// In en, this message translates to:
  /// **'Export all your data to a JSON file or import a previous backup.'**
  String get backupDescription;

  /// No description provided for @saveToFile.
  ///
  /// In en, this message translates to:
  /// **'Save to file'**
  String get saveToFile;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get importBackup;

  /// No description provided for @saveBackupDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save backup'**
  String get saveBackupDialogTitle;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupSaved;

  /// No description provided for @backupSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to: {path}'**
  String backupSavedTo(String path);

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Export error: {error}'**
  String exportError(String error);

  /// No description provided for @invalidFile.
  ///
  /// In en, this message translates to:
  /// **'Invalid file: {error}'**
  String invalidFile(String error);

  /// No description provided for @importMode.
  ///
  /// In en, this message translates to:
  /// **'Import mode'**
  String get importMode;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'Found:\n• {transactions, plural, =1{1 transaction} other{{transactions} transactions}}\n• {categories, plural, =1{1 category} other{{categories} categories}}\n• {templates, plural, =1{1 template} other{{templates} templates}}\n\nHow do you want to proceed?'**
  String importSummary(int transactions, int categories, int templates);

  /// No description provided for @merge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get merge;

  /// No description provided for @replaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get replaceAll;

  /// No description provided for @importCompleted.
  ///
  /// In en, this message translates to:
  /// **'Import completed'**
  String get importCompleted;

  /// No description provided for @importError.
  ///
  /// In en, this message translates to:
  /// **'Import error: {error}'**
  String importError(String error);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic (device language)'**
  String get languageSystem;

  /// Always written in Italian, so users recognize their language
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// Always written in English, so users recognize their language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
