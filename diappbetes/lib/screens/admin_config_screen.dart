import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AdminConfigScreen extends StatefulWidget {
  const AdminConfigScreen({super.key});

  @override
  State<AdminConfigScreen> createState() => _AdminConfigScreenState();
}

class _AdminConfigScreenState extends State<AdminConfigScreen> {
  final _db = FirebaseFirestore.instance;
  
  bool _loading = true;
  bool _saving = false;
  
  String _appName = 'DiAppBetes';
  String _appVersion = '1.0.0';
  bool _maintenanceMode = false;
  String _maintenanceMessage = '';
  
  double _defaultRatio = 10.0;
  double _defaultFsi = 50.0;
  double _defaultGlucoseMin = 70.0;
  double _defaultGlucoseMax = 180.0;
  
  bool _enableNotifications = true;
  bool _enableMealReminders = true;
  bool _enableGlucoseReminders = true;
  String _mealReminderTime = '08:00';
  String _glucoseReminderTime = '10:00';
  
  bool _requireStrongPassword = true;
  int _sessionTimeoutMinutes = 30;
  
  final _appNameCtrl = TextEditingController();
  final _appVersionCtrl = TextEditingController();
  final _maintenanceMsgCtrl = TextEditingController();
  final _ratioCtrl = TextEditingController();
  final _fsiCtrl = TextEditingController();
  final _glucoseMinCtrl = TextEditingController();
  final _glucoseMaxCtrl = TextEditingController();
  final _mealTimeCtrl = TextEditingController();
  final _glucoseTimeCtrl = TextEditingController();
  final _sessionTimeoutCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _appNameCtrl.dispose();
    _appVersionCtrl.dispose();
    _maintenanceMsgCtrl.dispose();
    _ratioCtrl.dispose();
    _fsiCtrl.dispose();
    _glucoseMinCtrl.dispose();
    _glucoseMaxCtrl.dispose();
    _mealTimeCtrl.dispose();
    _glucoseTimeCtrl.dispose();
    _sessionTimeoutCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getDefaultConfig() {
    return {
      'app_name': 'DiAppBetes',
      'app_version': '1.0.0',
      'maintenance_mode': false,
      'maintenance_message': '',
      'default_ratio': 10.0,
      'default_fsi': 50.0,
      'default_glucose_min': 70.0,
      'default_glucose_max': 180.0,
      'enable_notifications': true,
      'enable_meal_reminders': true,
      'enable_glucose_reminders': true,
      'meal_reminder_time': '08:00',
      'glucose_reminder_time': '10:00',
      'require_strong_password': true,
      'session_timeout_minutes': 30,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    
    try {
      final doc = await _db.collection('app_config').doc('global').get();
      
      Map<String, dynamic> data;
      
      if (doc.exists) {
        data = doc.data()!;
      } else {
        data = _getDefaultConfig();
        await _db.collection('app_config').doc('global').set(data);
      }
      
      if (mounted) {
        setState(() {
          _appName = data['app_name'] ?? 'DiAppBetes';
          _appVersion = data['app_version'] ?? '1.0.0';
          _maintenanceMode = data['maintenance_mode'] ?? false;
          _maintenanceMessage = data['maintenance_message'] ?? '';
          _defaultRatio = (data['default_ratio'] as num?)?.toDouble() ?? 10.0;
          _defaultFsi = (data['default_fsi'] as num?)?.toDouble() ?? 50.0;
          _defaultGlucoseMin = (data['default_glucose_min'] as num?)?.toDouble() ?? 70.0;
          _defaultGlucoseMax = (data['default_glucose_max'] as num?)?.toDouble() ?? 180.0;
          _enableNotifications = data['enable_notifications'] ?? true;
          _enableMealReminders = data['enable_meal_reminders'] ?? true;
          _enableGlucoseReminders = data['enable_glucose_reminders'] ?? true;
          _mealReminderTime = data['meal_reminder_time'] ?? '08:00';
          _glucoseReminderTime = data['glucose_reminder_time'] ?? '10:00';
          _requireStrongPassword = data['require_strong_password'] ?? true;
          _sessionTimeoutMinutes = data['session_timeout_minutes'] ?? 30;
          
          _appNameCtrl.text = _appName;
          _appVersionCtrl.text = _appVersion;
          _maintenanceMsgCtrl.text = _maintenanceMessage;
          _ratioCtrl.text = _defaultRatio.toString();
          _fsiCtrl.text = _defaultFsi.toString();
          _glucoseMinCtrl.text = _defaultGlucoseMin.toString();
          _glucoseMaxCtrl.text = _defaultGlucoseMax.toString();
          _mealTimeCtrl.text = _mealReminderTime;
          _glucoseTimeCtrl.text = _glucoseReminderTime;
          _sessionTimeoutCtrl.text = _sessionTimeoutMinutes.toString();
          
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar configuración: $e'),
            backgroundColor: AppColors.rojoSuave,
          ),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    
    try {
      await _db.collection('app_config').doc('global').set({
        'app_name': _appNameCtrl.text.trim(),
        'app_version': _appVersionCtrl.text.trim(),
        'maintenance_mode': _maintenanceMode,
        'maintenance_message': _maintenanceMsgCtrl.text.trim(),
        'default_ratio': double.tryParse(_ratioCtrl.text) ?? 10.0,
        'default_fsi': double.tryParse(_fsiCtrl.text) ?? 50.0,
        'default_glucose_min': double.tryParse(_glucoseMinCtrl.text) ?? 70.0,
        'default_glucose_max': double.tryParse(_glucoseMaxCtrl.text) ?? 180.0,
        'enable_notifications': _enableNotifications,
        'enable_meal_reminders': _enableMealReminders,
        'enable_glucose_reminders': _enableGlucoseReminders,
        'meal_reminder_time': _mealTimeCtrl.text.trim(),
        'glucose_reminder_time': _glucoseTimeCtrl.text.trim(),
        'require_strong_password': _requireStrongPassword,
        'session_timeout_minutes': int.tryParse(_sessionTimeoutCtrl.text) ?? 30,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada correctamente'),
            backgroundColor: AppColors.verdesuave,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.rojoSuave,
          ),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Restablecer valores',
            style: TextStyle(color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de restablecer todos los valores a los predeterminados?',
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restablecer', style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return; 
    
    if (confirmed == true) {
      setState(() {
        _defaultRatio = 10.0;
        _defaultFsi = 50.0;
        _defaultGlucoseMin = 70.0;
        _defaultGlucoseMax = 180.0;
        _sessionTimeoutMinutes = 30;
        
        _ratioCtrl.text = '10.0';
        _fsiCtrl.text = '50.0';
        _glucoseMinCtrl.text = '70.0';
        _glucoseMaxCtrl.text = '180.0';
        _sessionTimeoutCtrl.text = '30';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Valores restablecidos'),
          backgroundColor: AppColors.verdesuave,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Configuración Global',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: _loadConfig,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Información de la App', primaryColor),
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      _buildTextField(
                        label: 'Nombre de la App',
                        controller: _appNameCtrl,
                        primaryColor: primaryColor,
                        textSmallColor: textSmallColor,
                        dividerColor: dividerColor,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        label: 'Versión',
                        controller: _appVersionCtrl,
                        primaryColor: primaryColor,
                        textSmallColor: textSmallColor,
                        dividerColor: dividerColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle('Modo Mantenimiento', primaryColor),
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Activar modo mantenimiento',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                        subtitle: Text('Los usuarios no podrán acceder a la app',
                            style: TextStyle(color: textSmallColor, fontSize: 12)),
                        value: _maintenanceMode,
                        activeColor: primaryColor,
                        onChanged: (v) => setState(() => _maintenanceMode = v),
                      ),
                      if (_maintenanceMode) ...[
                        const SizedBox(height: 8),
                        _buildTextField(
                          label: 'Mensaje para usuarios',
                          controller: _maintenanceMsgCtrl,
                          primaryColor: primaryColor,
                          textSmallColor: textSmallColor,
                          dividerColor: dividerColor,
                          maxLines: 3,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle('Valores por Defecto (Nuevos Usuarios)', primaryColor),
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Ratio HC (g/U)',
                              controller: _ratioCtrl,
                              primaryColor: primaryColor,
                              textSmallColor: textSmallColor,
                              dividerColor: dividerColor,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'FSI (mg/dL/U)',
                              controller: _fsiCtrl,
                              primaryColor: primaryColor,
                              textSmallColor: textSmallColor,
                              dividerColor: dividerColor,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'Glucosa mín (mg/dL)',
                              controller: _glucoseMinCtrl,
                              primaryColor: primaryColor,
                              textSmallColor: textSmallColor,
                              dividerColor: dividerColor,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              label: 'Glucosa máx (mg/dL)',
                              controller: _glucoseMaxCtrl,
                              primaryColor: primaryColor,
                              textSmallColor: textSmallColor,
                              dividerColor: dividerColor,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _resetToDefaults,
                          icon: Icon(Icons.restore, size: 16, color: primaryColor),
                          label: Text('Restablecer valores',
                              style: TextStyle(color: primaryColor, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle('Notificaciones', primaryColor),
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Habilitar notificaciones',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                        subtitle: Text('Activar/desactivar todas las notificaciones',
                            style: TextStyle(color: textSmallColor, fontSize: 12)),
                        value: _enableNotifications,
                        activeColor: primaryColor,
                        onChanged: (v) => setState(() => _enableNotifications = v),
                      ),
                      if (_enableNotifications) ...[
                        const Divider(color: Color(0x1A000000), height: 1),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Recordatorio de comidas',
                              style: TextStyle(color: textColor)),
                          value: _enableMealReminders,
                          activeColor: primaryColor,
                          onChanged: (v) => setState(() => _enableMealReminders = v),
                        ),
                        if (_enableMealReminders) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 12),
                            child: Row(
                              children: [
                                Text('Hora:', style: TextStyle(color: textSmallColor, fontSize: 12)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _pickTime(context, _mealTimeCtrl, primaryColor),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: primaryColor),
                                        const SizedBox(width: 6),
                                        Text(_mealTimeCtrl.text,
                                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(color: Color(0x1A000000), height: 1),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Recordatorio de glucosa',
                              style: TextStyle(color: textColor)),
                          value: _enableGlucoseReminders,
                          activeColor: primaryColor,
                          onChanged: (v) => setState(() => _enableGlucoseReminders = v),
                        ),
                        if (_enableGlucoseReminders) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 12),
                            child: Row(
                              children: [
                                Text('Hora:', style: TextStyle(color: textSmallColor, fontSize: 12)),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _pickTime(context, _glucoseTimeCtrl, primaryColor),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: primaryColor),
                                        const SizedBox(width: 6),
                                        Text(_glucoseTimeCtrl.text,
                                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle('Seguridad', primaryColor),
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Contraseña fuerte requerida',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                        subtitle: Text('Mínimo 8 caracteres con números y símbolos',
                            style: TextStyle(color: textSmallColor, fontSize: 12)),
                        value: _requireStrongPassword,
                        activeColor: primaryColor,
                        onChanged: (v) => setState(() => _requireStrongPassword = v),
                      ),
                      const Divider(color: Color(0x1A000000), height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tiempo de sesión',
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                  Text('Minutos antes de cerrar sesión automáticamente',
                                      style: TextStyle(color: textSmallColor, fontSize: 12)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: _buildTextField(
                                label: 'Minutos',
                                controller: _sessionTimeoutCtrl,
                                primaryColor: primaryColor,
                                textSmallColor: textSmallColor,
                                dividerColor: dividerColor,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveConfig,
                      icon: _saving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: onPrimaryColor, strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Guardando...' : 'Guardar Configuración',
                          style: TextStyle(
                              color: onPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Color primaryColor,
    required Color? textSmallColor,
    required Color dividerColor,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textSmallColor, fontSize: 12),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: dividerColor)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: primaryColor)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, TextEditingController ctrl, Color primaryColor) async {
    final parts = ctrl.text.split(':');
    final initialHour = parts.length == 2 ? int.tryParse(parts[0]) ?? 8 : 8;
    final initialMinute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: primaryColor,
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );

    if (picked != null) {
      final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => ctrl.text = timeStr);
    }
  }
}