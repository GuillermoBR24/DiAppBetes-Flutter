import 'package:diappbetes/screens/add_food_detail_modal.dart';
import 'package:diappbetes/services/profile_service.dart';
import 'package:diappbetes/widgets/app_feedback.dart';
import 'package:diappbetes/widgets/empty_state.dart';
import 'package:diappbetes/widgets/setup_wizard.dart';
import 'package:diappbetes/widgets/custom_appbar.dart';
import 'package:diappbetes/widgets/gluten_indicator.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/dose_service.dart';
import '../services/food_service.dart';
import '../services/meal_create_service.dart';
import '../utils/admin_nav_helper.dart';
import 'add_food_modal.dart';
import 'add_meal_summary_modal.dart';
import 'confirm_insulin_modal.dart';

class AddedFood {
  final String id;
  String name;
  String category;
  double carbsPer100g;
  double caloriesPer100g;
  double quantityGrams;
  double calculatedHc;
  double calculatedCalories;
  double calculatedRations;
  final bool? containsGluten;

  AddedFood({
    required this.id,
    required this.name,
    required this.category,
    required this.carbsPer100g,
    required this.caloriesPer100g,
    required this.quantityGrams,
    required this.calculatedHc,
    required this.calculatedCalories,
    required this.calculatedRations,
    this.containsGluten,
  });
}

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _mealService = MealCreateService();
  bool _celiacMode = false;

  late DateTime _selectedDateTime;
  late String _mealTime;

  String _mealType    = '';
  String _glucemiaText = '';

  DoseSettings? _dose;
  String? _doseError;
  bool _doseNeedsSetup = false;
  bool _loadingDose = true;

  final List<AddedFood> _addedFoods = [];
  bool _saving = false;
  
  int _selectedTab = 2;
  bool _isAdmin = false;

  final _glucemiaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setNow();
    _loadUserData();
    _checkAdminRole();
    _loadCeliacMode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAdminRole();
  }

  @override
  void dispose() {
    _glucemiaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCeliacMode() async {
    final celiac = await ProfileService().getCeliacMode();
    if (mounted) setState(() => _celiacMode = celiac);
  }

  Future<void> _checkAdminRole() async {
    final isAdmin = await AdminNavHelper.getIsAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _loadingDose = true);
    final res = await DoseService().load(at: _selectedDateTime);
    if (!mounted) return;
    setState(() {
      _dose = res.settings;
      _doseError = res.error;
      _doseNeedsSetup = res.needsSetup;
      _loadingDose = false;
    });
  }

  void _setNow() {
    _selectedDateTime = DateTime.now();
    _mealTime = _formatDateTime(_selectedDateTime);
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.year}-${_p(dt.month)}-${_p(dt.day)}  ${_p(dt.hour)}:${_p(dt.minute)}';

  String _p(int n) => n.toString().padLeft(2, '0');

  Future<void> _pickDateTime() async {
    final primaryColor = Theme.of(context).colorScheme.primary;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _mealTime = _formatDateTime(_selectedDateTime);
    });
  }

  bool get _isFormValid =>
      _dose != null &&
      _mealType.isNotEmpty &&
      (double.tryParse(_glucemiaText.replaceAll(',', '.')) ?? 0) > 0 &&
      _addedFoods.isNotEmpty;

  double get _totalHc       => _addedFoods.fold(0, (s, f) => s + f.calculatedHc);
  double get _totalCalories => _addedFoods.fold(0, (s, f) => s + f.calculatedCalories);
  double get _totalRations  => _addedFoods.fold(0, (s, f) => s + f.calculatedRations);

  void _openAddFoodModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddFoodModal(
        onFoodAdded: (data) => setState(() {
          _addedFoods.add(AddedFood(
            id:                  data['id'],
            name:                data['name'],
            category:            data['category'],
            carbsPer100g:        (data['carbs_per_100g'] as num).toDouble(),
            caloriesPer100g:     (data['calories_per_100g'] as num).toDouble(),
            quantityGrams:       (data['quantity_grams'] as num).toDouble(),
            calculatedHc:        (data['calculated_hc'] as num).toDouble(),
            calculatedCalories:  (data['calculated_calories'] as num).toDouble(),
            calculatedRations:   (data['calculated_rations'] as num).toDouble(),
            containsGluten: data['contains_gluten'] as bool?,
          ));
        }),
      ),
    );
  }

  void _editFood(int index) {
    final food = _addedFoods[index];
    showDialog(
      context: context,
      builder: (_) => AddFoodDetailsModal(
        selectedFood: Food(
          id: food.id, name: food.name, category: food.category,
          carbsPer100g: food.carbsPer100g, caloriesPer100g: food.caloriesPer100g,
        ),
        isEditMode:      true,
        initialQuantity: food.quantityGrams,
        initialRaciones: food.calculatedRations,
        initialHc:       food.calculatedHc,
        initialCalories: food.calculatedCalories,
        onConfirm: (data) => setState(() {
          _addedFoods[index] = AddedFood(
            id: data['id'], name: data['name'], category: data['category'],
            carbsPer100g:       (data['carbs_per_100g'] as num).toDouble(),
            caloriesPer100g:    (data['calories_per_100g'] as num).toDouble(),
            quantityGrams:      (data['quantity_grams'] as num).toDouble(),
            calculatedHc:       (data['calculated_hc'] as num).toDouble(),
            calculatedCalories: (data['calculated_calories'] as num).toDouble(),
            calculatedRations:  (data['calculated_rations'] as num).toDouble(),
          );
        }),
      ),
    );
  }

  void _removeFood(int index) => setState(() => _addedFoods.removeAt(index));

  Future<void> _createMeal() async {
    if (!_isFormValid || _saving) return;

    final glucemia = double.tryParse(_glucemiaText.replaceAll(',', '.')) ?? 0;

    // Seguridad: valores imposibles se rechazan; una hipoglucemia exige confirmar.
    switch (DoseService.checkGlucose(glucemia)) {
      case GlucoseCheck.implausible:
        await AppDialog.error(
          context,
          title: 'Revisa la glucemia',
          message:
              '${glucemia.toStringAsFixed(0)} mg/dL no es un valor posible '
              '(debe estar entre ${DoseService.minPlausible.toStringAsFixed(0)} y '
              '${DoseService.maxPlausible.toStringAsFixed(0)}). Vuelve a medirte o corrige el número.',
        );
        return;
      case GlucoseCheck.low:
        final goOn = await AppDialog.warnConfirm(
          context,
          title: 'Glucemia baja (${glucemia.toStringAsFixed(0)} mg/dL)',
          message:
              'Con menos de ${DoseService.hypoThreshold.toStringAsFixed(0)} mg/dL hay que tratar primero la '
              'hipoglucemia (15 g de hidratos de acción rápida) y volver a medir a los 15 minutos. '
              '¿Quieres calcular la insulina de todos modos?',
          confirmLabel: 'Continuar',
          cancelLabel: 'Corregir valor',
        );
        if (!goOn || !mounted) return;
      case GlucoseCheck.ok:
        break;
    }

    // Se vuelve a leer el ratio de la franja horaria de ESTA comida (la hora
    // puede haberse editado). Sin datos reales no se calcula ninguna dosis.
    final res = await DoseService().load(at: _selectedDateTime);
    if (!mounted) return;
    setState(() {
      _dose = res.settings;
      _doseError = res.error;
    });
    if (!res.isOk) {
      await AppDialog.error(
        context,
        title: 'No se puede calcular la insulina',
        message: res.error!,
      );
      if (res.needsSetup && mounted) {
        final ok = await SetupWizard.show(context);
        if (ok && mounted) _loadUserData();
      }
      return;
    }

    final calculatedInsulin = DoseService.calculate(
      totalHc: _totalHc,
      glucose: glucemia,
      settings: res.settings!,
    );

    final confirmedInsulin = await showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmInsulinModal(
        totalHc: _totalHc,
        totalCalories: _totalCalories,
        totalRations: _totalRations,
        glucoseLevel: glucemia,
        calculatedInsulin: calculatedInsulin,
        settings: res.settings,
      ),
    );

    if (confirmedInsulin == null) return;

    final wasAdjusted = (confirmedInsulin - calculatedInsulin).abs() > 0.01;

    setState(() => _saving = true);

    try {
      final mealData = await _mealService.createMeal(
        mealType:      _mealType,
        glucoseLevel:  glucemia,
        totalHc:       _totalHc,
        totalCalories: _totalCalories,
        totalRations:  _totalRations,
        totalInsulin:  confirmedInsulin,
        insulinManuallyAdjusted: wasAdjusted,
        foods:         _addedFoods,
        mealDateTime:  _selectedDateTime,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AddMealSummaryModal(
          meal: MealSummaryData(
            mealType:      mealData['meal_type'],
            createdAt:     mealData['created_at'],
            totalHc:       (mealData['total_hc'] as num).toDouble(),
            totalCalories: (mealData['total_calories'] as num).toDouble(),
            totalRations:  (mealData['total_rations'] as num).toDouble(),
            totalInsulin:  (mealData['total_insulin'] as num).toDouble(),
            glucoseLevel:  (mealData['glucose_level'] as num).toDouble(),
          ),
        ),
      );

      if (!mounted) return;
      setState(() {
        _addedFoods.clear();
        _mealType    = '';
        _glucemiaText = '';
        _glucemiaCtrl.clear();
        _setNow();
      });
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) {
        await AppDialog.error(
          context,
          title: 'No se ha guardado la comida',
          message: friendlyError(e),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onTabTapped(int index) {
    AdminNavHelper.handleTabTap(
      context: context,
      index: index,
      isAdmin: _isAdmin,
      onValidTap: (validIndex) {
        setState(() => _selectedTab = validIndex);
        switch (validIndex) {
          case 0: Navigator.pushReplacementNamed(context, '/historial'); break;
          case 1: Navigator.pushReplacementNamed(context, '/home'); break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'DiAppBetes',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _buildDetailsCard(),
            const SizedBox(height: 12),
            _buildFoodsCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isFormValid && !_saving) ? _createMeal : null,
                icon: _saving
                    ? SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: onPrimaryColor, strokeWidth: 2))
                    : Icon(Icons.save, color: onPrimaryColor),
                label: Text(_saving ? 'Guardando...' : 'Crear Comida',
                    style: TextStyle(color: onPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Theme.of(context).disabledColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminNavHelper.buildBottomBar(
        context: context,
        currentIndex: _selectedTab,
        onTap: _onTabTapped,
        isAdmin: _isAdmin,
      ),
    );
  }

  Widget _buildDetailsCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;
    const opciones = ['desayuno', 'almuerzo', 'comida', 'merienda', 'cena'];
    
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalles de la comida',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
          const SizedBox(height: 14),

          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Icon(Icons.access_time, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(_mealTime, style: TextStyle(fontSize: 14, color: textColor)),
                const SizedBox(width: 6),
                Icon(Icons.edit, size: 14, color: textSmallColor),
              ]),
            ),
          ),
          Divider(color: dividerColor),
          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            value: _mealType.isEmpty ? null : _mealType,
            hint: Text('Seleccionar tipo', style: TextStyle(color: textColor, fontSize: 14)),
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Tipo de comida',
              labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            ),
            items: opciones.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o[0].toUpperCase() + o.substring(1),
                  style: TextStyle(color: textColor)),
            )).toList(),
            onChanged: (v) => setState(() => _mealType = v ?? ''),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _glucemiaCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 15, color: textColor),
            decoration: InputDecoration(
              labelText: 'Glucemia (mg/dL)',
              labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
              suffixText: 'mg/dL',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
            ),
            onChanged: (v) => setState(() => _glucemiaText = v),
          ),

          const SizedBox(height: 8),
          if (_loadingDose)
            Text('Cargando ratio y FSI…',
                style: TextStyle(fontSize: 12, color: textSmallColor))
          else if (_dose != null)
            Text('Ratio HC: ${_dose!.ratio.toStringAsFixed(1)} g/U  •  FSI: ${_dose!.fsi.toStringAsFixed(0)} mg/dL/U',
                style: TextStyle(fontSize: 12, color: textSmallColor))
          else
            Row(children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.rojoSuave),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_doseError ?? 'No se pudo calcular la dosis.',
                    style: const TextStyle(fontSize: 12, color: AppColors.rojoSuave)),
              ),
              if (_doseNeedsSetup)
                TextButton(
                  onPressed: () async {
                    final ok = await SetupWizard.show(context);
                    if (ok && mounted) _loadUserData();
                  },
                  child: const Text('Configurar'),
                )
              else
                TextButton(onPressed: _loadUserData, child: const Text('Reintentar')),
            ]),
        ],
      ),
    );
  }

  Widget _buildFoodsCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final dividerColor = Theme.of(context).dividerColor;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alimentos',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
              ElevatedButton(
                onPressed: _openAddFoodModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Icon(Icons.add, color: onPrimaryColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_addedFoods.isEmpty)
            EmptyState(
              icon: Icons.restaurant_menu,
              title: 'Aún no has añadido alimentos',
              message: 'Busca un alimento o escanea un envase para calcular tus hidratos.',
              actionLabel: 'Añadir alimento',
              onAction: _openAddFoodModal,
            )
          else ...[
            ..._addedFoods.asMap().entries.map((e) => _buildFoodItem(e.key, e.value)),
            Divider(color: dividerColor),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _totalChip('HC', '${_totalHc.toStringAsFixed(1)}g', primaryColor),
                  _totalChip('Cal', _totalCalories.toStringAsFixed(0), AppColors.ambarSuave),
                  _totalChip('Rac', _totalRations.toStringAsFixed(1), AppColors.verdesuave),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodItem(int i, AddedFood food) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dividerColor = Theme.of(context).dividerColor;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.restaurant, size: 24, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(food.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (_celiacMode && food.containsGluten != null) ...[
              GlutenIndicator(
                containsGluten: food.containsGluten,
                size: 12,
                showLabel: false,
              ),
              const SizedBox(width: 4),
            ],
            IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: Icon(Icons.edit, size: 18, color: primaryColor),
              onPressed: () => _editFood(i),
            ),
            const SizedBox(width: 6),
            IconButton(
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, size: 18, color: AppColors.rojoSuave),
              onPressed: () => _removeFood(i),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            _infoChip('${food.quantityGrams.toStringAsFixed(0)}g'),
            const SizedBox(width: 8),
            _infoChip('HC: ${food.calculatedHc.toStringAsFixed(1)}g'),
            const SizedBox(width: 8),
            _infoChip('${food.calculatedCalories.toStringAsFixed(0)} cal'),
          ]),
        ],
      ),
    );
  }

  Widget _infoChip(String text) =>
      Text(text, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color));

  Widget _totalChip(String label, String value, Color color) => Column(
    children: [
      Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
    ],
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0x1A000000),
            blurRadius: 12, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}