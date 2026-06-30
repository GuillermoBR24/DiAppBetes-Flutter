import 'package:diappbetes/services/report_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

enum IssueType { bug, error, suggestion, other }

extension IssueTypeX on IssueType {
  String get label {
    switch (this) {
      case IssueType.bug: return 'Bug';
      case IssueType.error: return 'Error';
      case IssueType.suggestion: return 'Sugerencia';
      case IssueType.other: return 'Otro';
    }
  }

  IconData get icon {
    switch (this) {
      case IssueType.bug: return Icons.bug_report;
      case IssueType.error: return Icons.error_outline;
      case IssueType.suggestion: return Icons.lightbulb_outline;
      case IssueType.other: return Icons.chat_bubble_outline;
    }
  }
}

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  static const String _supportEmail = 'diappbetes0@gmail.com';

  IssueType _selectedType = IssueType.bug;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _sending = false;
  String _error = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _error = '');

    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      setState(() => _error = 'Completa el título y la descripción');
      return;
    }

    setState(() => _sending = true);

    final ok = await ReportService.sendReport(
      type: _selectedType.label,
      title: title,
      description: desc,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incidencia enviada correctamente')),
        );
      } else {
        setState(() => _error = 'No se pudo enviar. Inténtalo de nuevo más tarde.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text('Reportar incidencia',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo de incidencia',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                )),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IssueType.values.map((type) {
                final selected = _selectedType == type;
                return ChoiceChip(
                  selected: selected,
                  label: Text(type.label),
                  avatar: Icon(type.icon,
                      size: 18,
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodySmall?.color),
                  labelStyle: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  selectedColor: primaryColor,
                  backgroundColor: Theme.of(context).cardColor,
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error,
                    style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13)),
              ),
            TextField(
              controller: _titleCtrl,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: primaryColor)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              maxLines: 6,
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: 'Descripción',
                alignLabelWithHint: true,
                hintText: 'Describe el problema o la sugerencia con el mayor detalle posible...',
                labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: primaryColor)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(_sending ? 'Abriendo correo...' : 'Enviar Incidencia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}