import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/category_provider.dart';
import '../providers/template_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/backup_service.dart';

/// Opens the system "Save as" dialog and writes [bytes] to the chosen
/// file. Returns the file [Uri], or null if the user cancels.
///
/// Matches [FilePicker.saveFile]; tests pass a fake one.
typedef SaveFileDialog = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
  String mimeType,
  String? dialogTitle,
});

class BackupScreen extends StatefulWidget {
  /// "Save as" dialog used by the "save to file" button.
  final SaveFileDialog saveFileDialog;

  const BackupScreen({super.key, this.saveFileDialog = FilePicker.saveFile});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  /// Sharing files (WhatsApp, Gmail, ...) is only available on phones;
  /// on desktop only "save to file" is offered.
  bool get _canShare =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Backup file name with today's date (e.g. budget_backup_20261025.json).
  String _backupFileName() {
    final now = DateTime.now();
    return 'budget_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
  }

  /// Serializes all the data of the three providers to JSON.
  String _backupJson() {
    return BackupService.exportToJson(
      transactions: context.read<TransactionProvider>().allTransactions,
      categories: context.read<CategoryProvider>().categories,
      templates: context.read<TemplateProvider>().templates,
    );
  }

  /// Opens the system "Save as" dialog to choose where to save the backup
  /// (on Android: Download, other folders, Google Drive, ...).
  Future<void> _saveToFile() async {
    setState(() => _isLoading = true);
    try {
      final uri = await widget.saveFileDialog(
        fileName: _backupFileName(),
        bytes: utf8.encode(_backupJson()),
        mimeType: 'application/json',
        dialogTitle: _l10n.saveBackupDialogTitle,
      );
      // null: the user closed the dialog without saving
      if (uri != null && mounted) {
        _showSnackBar(
          uri.scheme == 'file'
              ? _l10n.backupSavedTo(uri.toFilePath())
              : _l10n.backupSaved,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar(_l10n.exportError('$e'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Writes the backup to an app file and opens the phone's share sheet
  /// (WhatsApp, Telegram, Gmail, ...).
  Future<void> _share() async {
    setState(() => _isLoading = true);
    try {
      final json = _backupJson();
      final fileName = _backupFileName();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: fileName),
      );
    } catch (e) {
      if (mounted) _showSnackBar(_l10n.exportError('$e'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _import() async {
    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (_) {
      // Some devices do not support filtering by extension
      picked = await FilePicker.pickFile();
    }

    if (picked == null) return;

    BackupData data;
    try {
      final content = utf8.decode(await picked.readAsBytes());
      data = BackupService.parseJson(content);
    } catch (e) {
      if (mounted) _showSnackBar(_l10n.invalidFile('$e'), isError: true);
      return;
    }

    if (!mounted) return;

    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.importMode),
        content: Text(
          _l10n.importSummary(
            data.transactions.length,
            data.categories.length,
            data.templates.length,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: Text(_l10n.merge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: Text(_l10n.replaceAll),
          ),
        ],
      ),
    );

    if (mode == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final txProvider = context.read<TransactionProvider>();
      final catProvider = context.read<CategoryProvider>();
      final tmplProvider = context.read<TemplateProvider>();

      if (mode == 'replace') {
        await catProvider.replaceAll(data.categories);
        await txProvider.replaceAll(data.transactions);
        await tmplProvider.replaceAll(data.templates);
      } else {
        await catProvider.addAll(data.categories);
        await txProvider.addAll(data.transactions);
        await tmplProvider.addAll(data.templates);
      }

      if (mounted) _showSnackBar(_l10n.importCompleted);
    } catch (e) {
      if (mounted) _showSnackBar(_l10n.importError('$e'), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_l10n.backupAndRestore)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _l10n.backupDescription,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _saveToFile,
                    icon: const Icon(Icons.save_alt),
                    label: Text(_l10n.saveToFile),
                  ),
                  if (_canShare) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _share,
                      icon: const Icon(Icons.share),
                      label: Text(_l10n.share),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _import,
                    icon: const Icon(Icons.download),
                    label: Text(_l10n.importBackup),
                  ),
                ],
              ),
            ),
    );
  }
}
