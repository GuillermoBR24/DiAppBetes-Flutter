import 'package:flutter/material.dart';
import '../services/hc_ratio_service.dart';
import '../services/profile_service.dart';
import 'app_feedback.dart';

/// Asistente de 2 pasos para configurar FSI y ratio H.C. la primera vez.
/// Devuelve true si se guardó la configuración.
class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});

  static Future<bool> show(BuildContext context) async {
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SetupWizard(),
    );
    return done ?? false;
  }

  @override
  State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final _fsiCtrl = TextEditingController();
  final _ratioCtrl = TextEditingController();
  int _step = 0;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefillFsi();
  }

  @override
  void dispose() {
    _fsiCtrl.dispose();
    _ratioCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillFsi() async {
    try {
      final p = await ProfileService().getMyProfile();
      final fsi = (p?['fsi'] as num?)?.toDouble();
      if (fsi != null && mounted && _fsiCtrl.text.isEmpty) {
        _fsiCtrl.text = fsi == fsi.roundToDouble() ? fsi.toStringAsFixed(0) : fsi.toString();
      }
    } catch (_) {
      // Sin perfil se deja el campo vacío.
    }
  }

  double? _parse(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  void _next() {
    final fsi = _parse(_fsiCtrl);
    if (fsi == null || fsi < 1 || fsi > 500) {
      setState(() => _error = 'Introduce un FSI entre 1 y 500 mg/dL por unidad');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
    });
  }

  Future<void> _finish() async {
    final fsi = _parse(_fsiCtrl);
    final ratio = _parse(_ratioCtrl);
    if (fsi == null || fsi < 1 || fsi > 500) {
      setState(() {
        _step = 0;
        _error = 'Introduce un FSI entre 1 y 500 mg/dL por unidad';
      });
      return;
    }
    if (ratio == null || ratio < 1 || ratio > 200) {
      setState(() => _error = 'Introduce un ratio entre 1 y 200 g por unidad');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ProfileService().updateFsi(fsi);
      // Un único tramo para todo el día (se puede dividir luego en Ajustes).
      await HcRatioService().saveAll([
        {'start_time': '00:00', 'end_time': '24:00', 'ratio_value': ratio},
      ]);
      if (mounted) Navigator.pop(context, true);
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

    final isFsi = _step == 0;

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
                Icon(Icons.tune, color: onPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Configura tu insulina',
                      style: TextStyle(color: onPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                Semantics(
                  label: 'Paso ${_step + 1} de 2',
                  child: Text('${_step + 1}/2',
                      style: TextStyle(color: onPrimary.withValues(alpha: 0.9), fontSize: 14)),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / 2,
                      minHeight: 6,
                      color: primary,
                      backgroundColor: divider,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isFsi ? 'Factor de sensibilidad (FSI)' : 'Ratio de hidratos (H.C.)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isFsi
                        ? 'Cuántos mg/dL baja tu glucosa con 1 unidad de insulina. '
                            'Se usa para corregir una glucemia alta. Si no lo sabes, pregúntaselo a tu médico.'
                        : 'Cuántos gramos de hidratos cubre 1 unidad de insulina. '
                            'Aquí se aplica a todo el día; luego puedes dividirlo por franjas en Ajustes.',
                    style: TextStyle(fontSize: 14, height: 1.4, color: textColor),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: ValueKey(_step),
                    controller: isFsi ? _fsiCtrl : _ratioCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary),
                    onChanged: (_) => setState(() => _error = null),
                    decoration: InputDecoration(
                      labelText: isFsi ? 'FSI' : 'Ratio',
                      suffixText: isFsi ? 'mg/dL por U' : 'g por U',
                      suffixStyle: TextStyle(fontSize: 14, color: textSmall),
                      errorText: _error,
                      errorMaxLines: 3,
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: divider)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primary)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () {
                                  if (isFsi) {
                                    Navigator.pop(context, false);
                                  } else {
                                    setState(() {
                                      _step = 0;
                                      _error = null;
                                    });
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: divider),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(isFsi ? 'Ahora no' : 'Atrás',
                              style: TextStyle(color: textColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saving ? null : (isFsi ? _next : _finish),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: onPrimary))
                              : Text(isFsi ? 'Siguiente' : 'Guardar',
                                  style: TextStyle(color: onPrimary, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
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
