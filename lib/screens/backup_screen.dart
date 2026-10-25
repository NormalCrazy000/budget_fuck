import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/category_provider.dart';
import '../providers/template_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/backup_service.dart';

/// Funzione che apre la finestra di sistema "Salva come" e scrive [bytes]
/// nel file scelto. Restituisce l'[Uri] del file, o null se l'utente annulla.
///
/// Corrisponde a [FilePicker.saveFile]; i test ne passano una finta.
typedef SaveFileDialog = Future<Uri?> Function({
  required String fileName,
  required Uint8List bytes,
  String mimeType,
  String? dialogTitle,
});

class BackupScreen extends StatefulWidget {
  /// Finestra "Salva come" usata dal pulsante "Salva su file".
  final SaveFileDialog saveFileDialog;

  const BackupScreen({super.key, this.saveFileDialog = FilePicker.saveFile});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  /// La condivisione di file (WhatsApp, Gmail, ...) è disponibile solo su
  /// telefono; su desktop resta solo "Salva su file".
  bool get _canShare =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// Nome del file di backup con la data di oggi (es. budget_backup_20261025.json).
  String _backupFileName() {
    final now = DateTime.now();
    return 'budget_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
  }

  /// Serializza in JSON tutti i dati dei tre provider.
  String _backupJson() {
    return BackupService.exportToJson(
      transactions: context.read<TransactionProvider>().allTransactions,
      categories: context.read<CategoryProvider>().categories,
      templates: context.read<TemplateProvider>().templates,
    );
  }

  /// Apre la finestra di sistema "Salva come" per scegliere dove salvare
  /// il backup (su Android: Download, altre cartelle, Google Drive, ...).
  Future<void> _saveToFile() async {
    setState(() => _isLoading = true);
    try {
      final uri = await widget.saveFileDialog(
        fileName: _backupFileName(),
        bytes: utf8.encode(_backupJson()),
        mimeType: 'application/json',
        dialogTitle: 'Salva backup',
      );
      // null: l'utente ha chiuso la finestra senza salvare
      if (uri != null && mounted) {
        _showSnackBar(
          uri.scheme == 'file'
              ? 'Backup salvato in: ${uri.toFilePath()}'
              : 'Backup salvato',
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Errore esportazione: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Scrive il backup in un file dell'app e apre il menu di condivisione
  /// del telefono (WhatsApp, Telegram, Gmail, ...).
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
      if (mounted) _showSnackBar('Errore esportazione: $e', isError: true);
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
      // Alcuni dispositivi non supportano il filtro per estensione
      picked = await FilePicker.pickFile();
    }

    if (picked == null) return;

    BackupData data;
    try {
      final content = utf8.decode(await picked.readAsBytes());
      data = BackupService.parseJson(content);
    } catch (e) {
      if (mounted) _showSnackBar('File non valido: $e', isError: true);
      return;
    }

    if (!mounted) return;

    final mode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modalità importazione'),
        content: Text(
          'Trovati:\n'
          '• ${data.transactions.length} transazioni\n'
          '• ${data.categories.length} categorie\n'
          '• ${data.templates.length} template\n\n'
          'Come vuoi procedere?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: const Text('Unisci'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'replace'),
            child: const Text('Sostituisci tutto'),
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

      if (mounted) _showSnackBar('Importazione completata');
    } catch (e) {
      if (mounted) _showSnackBar('Errore importazione: $e', isError: true);
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
      appBar: AppBar(title: const Text('Backup & Ripristino')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Esporta tutti i dati in un file JSON oppure importa un backup precedente.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _saveToFile,
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Salva su file'),
                  ),
                  if (_canShare) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: _share,
                      icon: const Icon(Icons.share),
                      label: const Text('Condividi'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _import,
                    icon: const Icon(Icons.download),
                    label: const Text('Importa backup'),
                  ),
                ],
              ),
            ),
    );
  }
}
