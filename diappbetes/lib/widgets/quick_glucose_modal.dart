import 'package:flutter/material.dart';
import '../services/dose_service.dart';
import '../services/glucose_service.dart';
import 'app_feedback.dart';

/// Diálogo para anotar solo una glucemia (sin comida).
/// Devuelve true si se guardó una lectura.
class QuickGlucoseModal extends StatefulWidget {
  const QuickGlucoseModal({super.key});

  static Future<bool> show(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const QuickGlucoseModal(),
    );
    return saved ?? false;
  }

  @override
  State<QuickGlucoseModal> createState() => _QuickGlucoseModalState();
}

class _QuickGlucoseModalState extends State<QuickGlucoseModal> {
  final _ctrl = TextEditingController();
  DateTime _when = DateTime.now();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));

  String _fmtWhen(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
    return sameDay ? 'Hoy, ${p(d.hour)}:${p(d.minute)}' : '${p(d.day)}/${p(d.month)}, ${p(d.hour)}:${p(d.minute)}';
  }

  Future<void> _pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null || !mounted) return;
    var picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isAfter(DateTime.now())) picked = DateTime.now();
    setState(() => _when = picked);
  }

  Future<void> _save() async {
    final v = _value;
    if (v == null) {
      setState(() => _error = 'Introduce un número válido');
      return;
    }

    final check = DoseService.checkGlucose(v);
    if (check == GlucoseCheck.implausible) {
      setState(() => _error =
          'Valor fuera de lo posible (${DoseService.minPlausible.toStringAsFixed(0)}–${DoseService.maxPlausible.toStringAsFixed(0)} mg/dL). Revísalo.');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await GlucoseService().addReading(v, at: _when);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final low = check == GlucoseCheck.low;
      navigator.pop(true);
      if (low) {
        // Se avisa DESPUÉS de guardar: el dato queda registrado igualmente.
        await AppDialog.warn(
          navigator.context,
          title: 'Glucemia baja',
          message:
              'Tienes ${v.toStringAsFixed(0)} mg/dL. Toma 15 g de hidratos de acción rápida '
              '(zumo, azúcar o glucosa) y vuelve a medirte en 15 minutos. No te pongas insulina hasta recuperarte.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final card = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSmall = Theme.of(context).textTheme.bodySmall?.color;
    final divider = Theme.of(context).dividerColor;

    return Dialog(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop, color: onPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Registrar glucemia',
                      style: TextStyle(color: onPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: Icon(Icons.close, color: onPrimary),
                  onPressed: _saving ? null : () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _ctrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: primary),
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) => _save(),
                    decoration: InputDecoration(
                      hintText: '—',
                      suffixText: 'mg/dL',
                      suffixStyle: TextStyle(fontSize: 16, color: textSmall),
                      errorText: _error,
                      errorMaxLines: 3,
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: divider)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primary)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _saving ? null : _pickWhen,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 18, color: primary),
                          const SizedBox(width: 8),
                          Text(_fmtWhen(_when), style: TextStyle(fontSize: 15, color: textColor)),
                          const SizedBox(width: 6),
                          Icon(Icons.edit, size: 14, color: textSmall),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary))
                          : Text('Guardar',
                              style: TextStyle(
                                  color: onPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
