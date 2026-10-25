import 'package:budget_fuck/providers/settings_provider.dart';
import 'package:budget_fuck/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/localized_app.dart';

/// Fake SettingsProvider that does not depend on Hive.
class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  String? _code;

  @override
  String? get languageCode => _code;

  @override
  Locale? get locale => _code == null ? null : Locale(_code!);

  @override
  Future<void> setLanguageCode(String? code) async {
    _code = code;
    notifyListeners();
  }
}

void main() {
  late FakeSettingsProvider provider;

  setUp(() {
    provider = FakeSettingsProvider();
  });

  Widget buildWidget() {
    return ChangeNotifierProvider<SettingsProvider>.value(
      value: provider,
      child: localizedApp(home: const SettingsScreen()),
    );
  }

  testWidgets('shows the language and backup entries', (tester) async {
    await tester.pumpWidget(buildWidget());

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Automatic (device language)'), findsOneWidget);
    expect(find.text('Backup & restore'), findsOneWidget);
  });

  testWidgets('the language dialog lists every option', (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    final dialog = find.byType(SimpleDialog);
    for (final label in ['Automatic (device language)', 'Italiano', 'English']) {
      expect(
        find.descendant(of: dialog, matching: find.text(label)),
        findsOneWidget,
      );
    }
    // The current choice (automatic) has the check mark
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('choosing a language saves it and closes the dialog',
      (tester) async {
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();

    expect(provider.languageCode, 'it');
    expect(find.byType(SimpleDialog), findsNothing);
    // The subtitle shows the new choice
    expect(find.text('Italiano'), findsOneWidget);
  });

  testWidgets('automatic goes back to the device language', (tester) async {
    await provider.setLanguageCode('en');
    await tester.pumpWidget(buildWidget());

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Automatic (device language)').last);
    await tester.pumpAndSettle();

    expect(provider.languageCode, isNull);
  });
}
