import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import 'backup_screen.dart';

/// Settings screen.
///
/// Contains:
/// - Language: automatic (device language), Italiano or English
/// - Backup & restore: opens [BackupScreen]
///
/// Reached from HomeScreen via the gear icon in the AppBar.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Language codes the user can pick; null means "device language".
  static const List<String?> languageOptions = [null, 'it', 'en'];

  /// Label of a language option. Language names are written in their own
  /// language, so users always recognize them.
  static String languageLabel(AppLocalizations l10n, String? code) {
    switch (code) {
      case 'it':
        return l10n.languageItalian;
      case 'en':
        return l10n.languageEnglish;
      default:
        return l10n.languageSystem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // watch: the subtitle follows the chosen language
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            subtitle: Text(languageLabel(l10n, settings.languageCode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseLanguage(context, settings),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(l10n.backupAndRestore),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Opens a dialog listing the languages; the current one has a check mark.
  Future<void> _chooseLanguage(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          for (final code in languageOptions)
            ListTile(
              title: Text(languageLabel(l10n, code)),
              trailing: code == settings.languageCode
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                settings.setLanguageCode(code);
                Navigator.of(dialogContext).pop();
              },
            ),
        ],
      ),
    );
  }
}
