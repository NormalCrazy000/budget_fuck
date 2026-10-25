import 'dart:io';
import 'dart:ui' show Locale;

import 'package:budget_fuck/providers/settings_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// Unit tests for [SettingsProvider] (language preference) and its
/// device locale resolution.
void main() {
  group('language preference', () {
    late Directory tempDir;
    late SettingsProvider provider;

    // Create an isolated Hive environment before each test
    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(tempDir.path);
      await Hive.openBox<String>(SettingsProvider.boxName);
      provider = SettingsProvider();
    });

    // Close Hive and remove the temporary files after each test
    tearDown(() async {
      await Hive.close();
      await tempDir.delete(recursive: true);
    });

    test('follows the device language by default', () {
      expect(provider.languageCode, isNull);
      expect(provider.locale, isNull);
    });

    test('setLanguageCode saves the choice and notifies', () async {
      var notified = 0;
      provider.addListener(() => notified++);

      await provider.setLanguageCode('it');

      expect(provider.languageCode, 'it');
      expect(provider.locale, const Locale('it'));
      expect(notified, 1);
    });

    test('the choice survives reopening the box', () async {
      await provider.setLanguageCode('en');
      await Hive.close();
      Hive.init(tempDir.path);
      await Hive.openBox<String>(SettingsProvider.boxName);

      expect(SettingsProvider().languageCode, 'en');
    });

    test('null goes back to the device language', () async {
      await provider.setLanguageCode('it');
      await provider.setLanguageCode(null);

      expect(provider.languageCode, isNull);
      expect(provider.locale, isNull);
    });
  });

  group('resolveLocale', () {
    const supported = [Locale('en'), Locale('it')];

    test('uses the device language when supported', () {
      expect(
        SettingsProvider.resolveLocale([const Locale('it', 'IT')], supported),
        const Locale('it'),
      );
    });

    test('falls back to English for an unsupported language', () {
      expect(
        SettingsProvider.resolveLocale([const Locale('de', 'DE')], supported),
        const Locale('en'),
      );
    });

    test('uses the first supported language in the device list', () {
      expect(
        SettingsProvider.resolveLocale(
          [const Locale('de'), const Locale('it'), const Locale('en')],
          supported,
        ),
        const Locale('it'),
      );
    });

    test('falls back to English when the device list is missing', () {
      expect(SettingsProvider.resolveLocale(null, supported), const Locale('en'));
    });
  });
}
