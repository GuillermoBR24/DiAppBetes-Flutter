import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// ConfirmInsulinModal — paso previo a guardar la comida.
// Muestra la insulina calculada automáticamente y permite ajustarla antes
// de confirmar la creación. Devuelve (via Navigator.pop) el valor final
// de insulina, o null si el usuario cancela.
// ---------------------------------------------------------------------------
class ConfirmInsulinModal extends StatefulWidget {
  final double totalHc;
  final double totalCalories;
  final double totalRations;
  final double glucoseLevel;
  final double calculatedInsulin;

  const ConfirmInsulinModal({
    super.key,
    required this.totalHc,
    required this.totalCalories,
    required this.totalRations,
    required this.glucoseLevel,
    required this.calculatedInsulin,
  });

  @override
  State<ConfirmInsulinModal> createState() => _ConfirmInsulinModalState();
}

class _ConfirmInsulinModalState extends State<ConfirmInsulinModal> {
  late final TextEditingController _insulinCtrl;
  late double _insulinValue;
  bool _wasModified = false;

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
          // ── Header ────────────────────────────────────────────────── //
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
                  // Resumen breve del contexto
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
                  const SizedBox(height: 16),

                  // ── Campo editable de insulina, destacado ───────────── //
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

                  // Indicador de ajuste manual + botón para restaurar
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

                  const SizedBox(height: 20),

                  // ── Botones ──────────────────────────────────────────── //
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context), // cancela → devuelve null
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
                          onPressed: _confirm,
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

  Widget _miniStat(String label, String value, Color? valueColor, Color? labelColor) => Column(
    children: [
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 14)),
      Text(label, style: TextStyle(fontSize: 10, color: labelColor)),
    ],
  );
}