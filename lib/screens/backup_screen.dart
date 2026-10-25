import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/category_provider.dart';
import '../providers/template_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _isLoading = false;

  Future<void> _export() async {
    setState(() => _isLoading = true);
    try {
      final txProvider = context.read<TransactionProvider>();
      final catProvider = context.read<CategoryProvider>();
      final tmplProvider = context.read<TemplateProvider>();

      final json = BackupService.exportToJson(
        transactions: txProvider.allTransactions,
        categories: catProvider.categories,
        templates: tmplProvider.templates,
      );

      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          'budget_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);

      if (!mounted) return;

      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], subject: fileName),
        );
      } else {
        _showSnackBar('File salvato in: ${file.path}');
      }
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
                    onPressed: _export,
                    icon: const Icon(Icons.upload),
                    label: const Text('Esporta dati'),
                  ),
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
