import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Provider for the user preferences (currently the app language).
///
/// Values are plain strings in the `settings` Hive box, so no TypeAdapter
/// is needed.
class SettingsProvider extends ChangeNotifier {
  static const String boxName = 'settings';
  static const String languageKey = 'language';

  /// Language used when the device language is not supported.
  static const Locale fallbackLocale = Locale('en');

  late Box<String> _box;

  SettingsProvider() {
    // Gets the box already opened in main.dart
    _box = Hive.box<String>(boxName);
  }

  /// Language code chosen by the user (e.g. "it", "en"), or null to follow
  /// the device language.
  String? get languageCode => _box.get(languageKey);

  /// Locale for [MaterialApp.locale]: null lets Flutter use the device
  /// language (see [resolveLocale]).
  Locale? get locale {
    final code = languageCode;
    return code == null ? null : Locale(code);
  }

  /// Saves the chosen language; null goes back to the device language.
  Future<void> setLanguageCode(String? code) async {
    if (code == null) {
      await _box.delete(languageKey);
    } else {
      await _box.put(languageKey, code);
    }
    notifyListeners();
  }

  /// Picks the app locale from the device locales: the first one whose
  /// language is supported, otherwise [fallbackLocale].
  static Locale resolveLocale(
    List<Locale>? deviceLocales,
    Iterable<Locale> supportedLocales,
  ) {
    for (final device in deviceLocales ?? const <Locale>[]) {
      for (final supported in supportedLocales) {
        if (supported.languageCode == device.languageCode) return supported;
      }
    }
    return fallbackLocale;
  }
}
