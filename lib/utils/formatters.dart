import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

// Locale-aware formatting helpers. They read the current app locale from
// the widget tree, so the output follows the language chosen by the user.

String _localeName(BuildContext context) =>
    Intl.canonicalizedLocale(Localizations.localeOf(context).toString());

/// Euro amounts in the app language (it: "1.500,00 €", en: "€1,500.00").
NumberFormat currencyFormat(BuildContext context) =>
    NumberFormat.currency(locale: _localeName(context), symbol: '€');

/// Month and year (it: "ottobre 2026", en: "October 2026").
DateFormat monthYearFormat(BuildContext context) =>
    DateFormat('MMMM yyyy', _localeName(context));

/// Full date (it: "26 ottobre 2026", en: "October 26, 2026").
DateFormat longDateFormat(BuildContext context) =>
    DateFormat.yMMMMd(_localeName(context));

/// Short numeric date (it: "26/10/2026", en: "10/26/2026").
DateFormat shortDateFormat(BuildContext context) =>
    DateFormat.yMd(_localeName(context));

/// Parses an amount typed by the user, accepting both "12.50" and "12,50".
/// Returns null if the text is not a number.
double? parseAmount(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// Percentage with one decimal (it: "12,5%", en: "12.5%").
NumberFormat percentFormat(BuildContext context) =>
    NumberFormat.decimalPercentPattern(
      locale: _localeName(context),
      decimalDigits: 1,
    );
