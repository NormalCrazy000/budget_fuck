import 'package:budget_fuck/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../helpers/localized_app.dart';

/// Renders a widget in [locale] and returns the [BuildContext] below the
/// localizations, so the locale-aware formatters can be called.
Future<BuildContext> _contextFor(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(localizedApp(
    locale: locale,
    home: Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    }),
  ));
  return captured;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('parseAmount', () {
    test('accepts a dot or a comma as decimal separator', () {
      expect(parseAmount('12.50'), 12.5);
      expect(parseAmount('12,50'), 12.5);
      expect(parseAmount(' 7 '), 7);
    });

    test('returns null for text that is not a number', () {
      expect(parseAmount('abc'), isNull);
      expect(parseAmount(''), isNull);
    });
  });

  testWidgets('English formats', (tester) async {
    final context = await _contextFor(tester, const Locale('en'));
    final date = DateTime(2026, 10, 26);

    expect(currencyFormat(context).format(1500), '€1,500.00');
    expect(monthYearFormat(context).format(date), 'October 2026');
    expect(longDateFormat(context).format(date), 'October 26, 2026');
    expect(shortDateFormat(context).format(date), '10/26/2026');
    expect(percentFormat(context).format(0.125), '12.5%');
  });

  testWidgets('Italian formats', (tester) async {
    final context = await _contextFor(tester, const Locale('it'));
    final date = DateTime(2026, 10, 26);

    // NumberFormat uses a non-breaking space before the euro sign
    expect(currencyFormat(context).format(1500), '1.500,00 €');
    expect(monthYearFormat(context).format(date), 'ottobre 2026');
    expect(longDateFormat(context).format(date), '26 ottobre 2026');
    expect(shortDateFormat(context).format(date), '26/10/2026');
    expect(percentFormat(context).format(0.125), '12,5%');
  });
}
