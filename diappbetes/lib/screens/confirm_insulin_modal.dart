import 'package:flutter/material.dart';
import '../services/dose_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medical_disclaimer.dart';
import '../widgets/ration_bar.dart';

class ConfirmInsulinModal extends StatefulWidget {
  final double totalHc;
  final double totalCalories;
  final double totalRations;
  final double glucoseLevel;
  final double calculatedInsulin;

  /// Si se pasa, se muestra el desglose de cómo se ha calculado la dosis.
  final DoseSettings? settings;

  const ConfirmInsulinModal({
    super.key,
    required this.totalHc,
    required this.totalCalories,
    required this.totalRations,
    required this.glucoseLevel,
    required this.calculatedInsulin,
    this.settings,
  });

  @override
  State<ConfirmInsulinModal> createState() => _ConfirmInsulinModalState();
}

class _ConfirmInsulinModalState extends State<ConfirmInsulinModal> {
  late final TextEditingController _insulinCtrl;
  late double _insulinValue;
  bool _wasModified = false;

  // Debe coincidir con el tope de total_insulin en firestore.rules.
  static const double _maxDose = 100;

  @override
  void initState() {
    super.initState();
    _insulinValue = widget.calculatedInsulin;
    _insulinCtrl = TextEditingController(text: _insulinValue.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _insulinCtrl.dispose();
    super.dispose();
  }

  void _onInsulinChanged(String v) {
    final parsed = double.tryParse(v.replaceAll(',', '.'));
    if (parsed == null) return;
    setState(() {
      _insulinValue = parsed;
      _wasModified = (parsed - widget.calculatedInsulin).abs() > 0.01;
    });
  }

  void _resetToCalculated() {
    setState(() {
      _insulinValue = widget.calculatedInsulin;
      _insulinCtrl.text = _insulinValue.toStringAsFixed(1);
      _wasModified = false;
    });
  }

  void _confirm() {
    if (_insulinValue < 0) _insulinValue = 0;
    Navigator.pop(context, _insulinValue);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Icon(Icons.vaccines, color: onPrimaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Confirmar Insulina',
                      style: TextStyle(color: onPrimaryColor, fontSize: 17, fontWeight: FontWeight.bold)),
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStat('HC', '${widget.totalHc.toStringAsFixed(1)}g', textColor, textSmallColor),
                        _miniStat('Glucemia', '${widget.glucoseLevel.toStringAsFixed(0)} mg/dL', textColor, textSmallColor),
                        _miniStat('Raciones', widget.totalRations.toStringAsFixed(1), textColor, textSmallColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Insulina calculada según tu ratio HC y FSI. Puedes ajustarla antes de crear la comida.',
                    style: TextStyle(fontSize: 13, color: textSmallColor, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  RationBar(
                    raciones: widget.totalRations,
                    hc: widget.totalHc,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 16),

                  if (widget.settings != null) ...[
                    _buildBreakdown(textColor, textSmallColor, dividerColor),
                    const SizedBox(height: 16),
                  ],

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('Unidades de insulina',
                            style: TextStyle(color: onPrimaryColor.withValues(alpha: 0.9), fontSize: 13)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _insulinCtrl,
                          onChanged: _onInsulinChanged,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: onPrimaryColor, fontSize: 40, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            suffixText: 'U',
                            suffixStyle: TextStyle(color: onPrimaryColor.withValues(alpha: 0.8), fontSize: 20),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_wasModified)
                    Center(
                      child: Column(
                        children: [
                          Text('Valor calculado: ${widget.calculatedInsulin.toStringAsFixed(1)} U',
                              style: TextStyle(fontSize: 12, color: textSmallColor)),
                          TextButton.icon(
                            onPressed: _resetToCalculated,
                            icon: Icon(Icons.refresh, size: 16, color: primaryColor),
                            label: Text('Restaurar valor calculado',
                                style: TextStyle(color: primaryColor, fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Valor calculado automáticamente',
                          style: TextStyle(fontSize: 12, color: textSmallColor),
                          textAlign: TextAlign.center),
                    ),

                  if (_insulinValue > DoseService.highDoseWarning)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.rojoSuave),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _insulinValue > _maxDose
                                  ? 'La dosis supera el máximo permitido (${_maxDose.toStringAsFixed(0)} U).'
                                  : 'Dosis alta (más de ${DoseService.highDoseWarning.toStringAsFixed(0)} U). Revísala antes de confirmar.',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.rojoSuave,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),
                  const MedicalDisclaimer(compact: true),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancelar', style: TextStyle(color: textColor)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _insulinValue > _maxDose ? null : _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Confirmar y Crear',
                              style: TextStyle(color: onPrimaryColor, fontWeight: FontWeight.w600)),
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

  String _num(double v) => v.toStringAsFixed(1);

  Widget _buildBreakdown(Color? textColor, Color? textSmallColor, Color dividerColor) {
    final s = widget.settings!;
    final b = DoseService.breakdown(
      totalHc: widget.totalHc,
      glucose: widget.glucoseLevel,
      settings: s,
    );
    final target = DoseService.targetGlucose.toStringAsFixed(0);
    final corrSign = b.correctionUnits >= 0 ? '+' : '−';
    final summary =
        'Comida ${_num(b.mealUnits)} unidades, corrección ${_num(b.correctionUnits)} unidades, '
        'total ${_num(b.total)} unidades';

    Widget row(String label, String formula, String result, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                        color: textColor)),
                if (formula.isNotEmpty)
                  Text(formula, style: TextStyle(fontSize: 12, color: textSmallColor)),
              ],
            ),
          ),
          Text(result,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: summary,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cómo se calcula',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSmallColor)),
              const SizedBox(height: 4),
              row('Comida',
                  '${widget.totalHc.toStringAsFixed(1)} g ÷ ${_num(s.ratio)} g/U',
                  '${_num(b.mealUnits)} U'),
              row('Corrección',
                  '(${widget.glucoseLevel.toStringAsFixed(0)} − $target) ÷ ${s.fsi.toStringAsFixed(0)} mg/dL/U',
                  '$corrSign${_num(b.correctionUnits.abs())} U'),
              Divider(height: 12, color: dividerColor),
              row('Total calculado', 'Redondeado a 0,1 · nunca menor que 0', '${_num(b.total)} U', bold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color? valueColor, Color? labelColor) => Column(
    children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 14)),
      Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
    ],
  );
}