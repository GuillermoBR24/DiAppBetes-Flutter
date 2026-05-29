import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';
import '../services/hc_ratio_service.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Modelos
// ---------------------------------------------------------------------------
class HcRatio {
  String id;
  String startTime;
  String endTime;
  double ratioValue;

  HcRatio({
    this.id = '',
    required this.startTime,
    required this.endTime,
    required this.ratioValue,
  });

  Map<String, dynamic> toMap() => {
    'start_time':  startTime,
    'end_time':    endTime,
    'ratio_value': ratioValue,
  };
}

// ---------------------------------------------------------------------------
// SettingsScreen
// ---------------------------------------------------------------------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileService  = ProfileService();
  final _hcRatioService  = HcRatioService();
  final _authService     = AuthService();

  // ── Estado de carga ────────────────────────────────────────────────────── //
  bool _loadingProfile = true;
  bool _savingPersonal = false;
  bool _savingDiabetes = false;

  // ── Datos del perfil ───────────────────────────────────────────────────── //
  String _username  = '';
  String _email     = '';
  String _birthDate = '';
  String _phone     = '';
  String _role      = '';
  double _fsi       = 0;

  List<HcRatio> _hcRatios = [];

  // ── Modo edición ──────────────────────────────────────────────────────── //
  bool _editingPersonal  = false;
  bool _editingDiabetes  = false;

  // ── Errores ────────────────────────────────────────────────────────────── //
  String _errorPersonal = '';
  String _errorDiabetes = '';

  // ── Controllers ────────────────────────────────────────────────────────── //
  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _birthDateCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _fsiCtrl;

  @override
  void initState() {
    super.initState();
    _usernameCtrl  = TextEditingController();
    _emailCtrl     = TextEditingController();
    _birthDateCtrl = TextEditingController();
    _phoneCtrl     = TextEditingController();
    _fsiCtrl       = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _birthDateCtrl.dispose();
    _phoneCtrl.dispose();
    _fsiCtrl.dispose();
    super.dispose();
  }

  // ── Cargar datos desde Firestore ─────────────────────────────────────── //
  Future<void> _loadData() async {
    setState(() => _loadingProfile = true);
    try {
      // Debug: Verificar usuario actual
      final user = _authService.currentUser;
      print('🔍 Usuario actual: ${user?.uid}');
      print('🔍 Email: ${user?.email}');
      
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final profile = await _profileService.getMyProfile();
      print('📄 Perfil obtenido: ${profile != null ? "SI" : "NO"}');
      
      final ratios = await _hcRatioService.getHcRatios();
      print('📊 Ratios HC: ${ratios.length}');

      if (profile == null) {
        throw Exception('Perfil no encontrado en Firestore');
      }

      if (!mounted) return;

      setState(() {
        _username  = profile['username']?.toString() ?? '';
        _email     = profile['email']?.toString() ?? '';
        _birthDate = profile['birth_date']?.toString() ?? '';
        _phone     = profile['phone']?.toString() ?? '';
        _role      = profile['role']?.toString() ?? 'usuario';
        
        // Manejo seguro del campo fsi
        final fsiValue = profile['fsi'];
        if (fsiValue is num) {
          _fsi = fsiValue.toDouble();
        } else if (fsiValue is int) {
          _fsi = fsiValue.toDouble();
        } else {
          _fsi = 0;
        }

        _usernameCtrl.text  = _username;
        _emailCtrl.text     = _email;
        _birthDateCtrl.text = _birthDate;
        _phoneCtrl.text     = _phone;
        _fsiCtrl.text       = _fsi.toString();

        _hcRatios = ratios.map((r) => HcRatio(
          id:         r['id']?.toString() ?? '',
          startTime:  r['start_time']?.toString() ?? '00:00',
          endTime:    r['end_time']?.toString() ?? '23:59',
          ratioValue: (r['ratio_value'] is num) 
              ? (r['ratio_value'] as num).toDouble() 
              : 0,
        )).toList();

        if (_hcRatios.isEmpty) {
          _hcRatios = [HcRatio(startTime: '00:00', endTime: '23:59', ratioValue: 10.0)];
        }
      });
      
    } catch (e, stackTrace) {
      print('❌ Error al cargar perfil: $e');
      print('📋 Stack trace: $stackTrace');
      if (mounted) {
        _showSnack('Error al cargar el perfil: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingProfile = false);
      }
    }
  }

  // ── Guardar info personal ─────────────────────────────────────────────── //
  Future<void> _savePersonalInfo() async {
    setState(() => _errorPersonal = '');

    if (_usernameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty    ||
        _birthDateCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) {
      setState(() => _errorPersonal = 'Todos los campos son obligatorios');
      return;
    }

    setState(() => _savingPersonal = true);
    try {
      await _profileService.updatePersonalInfo(
        username:  _usernameCtrl.text.trim(),
        email:     _emailCtrl.text.trim(),
        birthDate: _birthDateCtrl.text.trim(),
        phone:     _phoneCtrl.text.trim(),
      );
      setState(() {
        _username  = _usernameCtrl.text.trim();
        _email     = _emailCtrl.text.trim();
        _birthDate = _birthDateCtrl.text.trim();
        _phone     = _phoneCtrl.text.trim();
        _editingPersonal = false;
      });
      _showSnack('Perfil actualizado');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorPersonal = AuthService.translateError(e));
    } catch (e) {
      setState(() => _errorPersonal = 'Error al guardar. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _savingPersonal = false);
    }
  }

  // ── Guardar gestión diabetes ──────────────────────────────────────────── //
  Future<void> _saveDiabetes() async {
    setState(() => _errorDiabetes = '');
    final fsiVal = double.tryParse(_fsiCtrl.text);

    if (fsiVal == null || fsiVal <= 0) {
      setState(() => _errorDiabetes = 'El FSI debe ser mayor que 0');
      return;
    }

    setState(() => _savingDiabetes = true);
    try {
      await _profileService.updateFsi(fsiVal);
      await _hcRatioService.saveAll(_hcRatios.map((r) => r.toMap()).toList());
      setState(() {
        _fsi = fsiVal;
        _editingDiabetes = false;
      });
      _showSnack('Datos de diabetes actualizados');
    } catch (e) {
      setState(() => _errorDiabetes = 'Error al guardar. Inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _savingDiabetes = false);
    }
  }

  // ── Cerrar sesión ─────────────────────────────────────────────────────── //
  Future<void> _logout() async {
    final ok = await _confirm(
      title: 'Cierre de Sesión',
      message: '¿Estás seguro de cerrar sesión?',
      confirmText: 'Cerrar Sesión',
      confirmColor: AppColors.rojoSuave,
    );
    if (!ok) return;
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/auth');
  }

  // ── Eliminar cuenta ───────────────────────────────────────────────────── //
  Future<void> _deleteAccount() async {
    final ok = await _confirm(
      title: '¿Eliminar cuenta?',
      message: 'Esta acción es irreversible.\nSe eliminarán todos tus datos permanentemente.',
      confirmText: 'Eliminar',
      confirmColor: AppColors.rojoSuave,
    );
    if (!ok) return;

    // Pedir contraseña para reautenticar (Firebase lo requiere para delete)
    final password = await _askPassword();
    if (password == null || password.isEmpty) return;

    try {
      // Reautenticar antes de eliminar (requisito de Firebase)
      final credential = EmailAuthProvider.credential(
        email: _authService.currentUser!.email!,
        password: password,
      );
      await _authService.currentUser!.reauthenticateWithCredential(credential);

      await _profileService.deleteAccount();
      if (mounted) Navigator.pushReplacementNamed(context, '/auth');
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.translateError(e), isError: true);
    } catch (e) {
      _showSnack('Error al eliminar la cuenta.', isError: true);
    }
  }

  // ── Añadir tramo HC ───────────────────────────────────────────────────── //
  void _addHcRatio() {
    setState(() {
      if (_hcRatios.isEmpty) {
        _hcRatios.add(HcRatio(startTime: '00:00', endTime: '23:59', ratioValue: 10.0));
        return;
      }
      final last = _hcRatios.last;
      final lastStartMins = _toMins(last.startTime);
      final lastEndMins   = _toMins(last.endTime);
      final half          = ((lastStartMins + lastEndMins) / 2).floor();
      final halfStr       = _fromMins(half);
      final oldEnd        = last.endTime;
      last.endTime        = halfStr;
      _hcRatios.add(HcRatio(startTime: halfStr, endTime: oldEnd, ratioValue: last.ratioValue));
    });
  }

  void _removeHcRatio(int index) {
    if (_hcRatios.length <= 1) return;
    setState(() {
      _hcRatios.removeAt(index);
      if (index == 0) {
        _hcRatios[0].startTime = '00:00';
      } else if (index >= _hcRatios.length) {
        _hcRatios.last.endTime = '23:59';
      } else {
        _hcRatios[index].startTime = _hcRatios[index - 1].endTime;
      }
    });
  }

  // ── Helpers tiempo ────────────────────────────────────────────────────── //
  int _toMins(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }
  String _fromMins(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  // ── Diálogos helper ───────────────────────────────────────────────────── //
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmText,
    Color confirmColor = AppColors.azulFondo,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title,
            style: const TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppColors.grisTexto)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.grisTexto)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: TextStyle(color: confirmColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<String?> _askPassword() async {
    final ctrl = TextEditingController();
    bool obscure = true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Confirmar contraseña',
              style: TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Contraseña actual',
              labelStyle: const TextStyle(color: AppColors.grisTexto),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.azulFondo)),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.grisTexto, size: 20),
                onPressed: () => setS(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.grisTexto)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Confirmar',
                  style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return result;
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.rojoSuave : AppColors.verdesuave,
    ));
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blanco,
      appBar: AppBar(
        backgroundColor: AppColors.azulFondo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.blanco),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('DiAppBetes',
            style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () {},
          ),
        ],
      ),
      body: _loadingProfile
          ? const Center(child: CircularProgressIndicator(color: AppColors.azulFondo))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mi Perfil',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
                  const SizedBox(height: 14),
                  _buildProfileCard(),
                  const SizedBox(height: 12),
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 12),
                  _buildDiabetesCard(),
                ],
              ),
            ),
    );
  }

  // =========================================================================
  // Tarjeta perfil
  // =========================================================================
  Widget _buildProfileCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.azulFondo, width: 3),
                ),
                child: const Icon(Icons.person, size: 30, color: AppColors.azulFondo),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_username,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
                    const SizedBox(height: 2),
                    Text(_email,
                        style: const TextStyle(fontSize: 13, color: AppColors.grisTexto)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        border: Border.all(color: AppColors.azulFondo),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_role,
                          style: const TextStyle(fontSize: 12, color: AppColors.azulFondo, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón cerrar sesión
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: AppColors.rojoSuave, size: 20),
            label: const Text('Cerrar Sesión',
                style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.rojoSuave),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          // Eliminar cuenta
          Center(
            child: GestureDetector(
              onTap: _deleteAccount,
              child: const Text('Eliminar Cuenta',
                  style: TextStyle(fontSize: 13, color: AppColors.rojoSuave, fontWeight: FontWeight.w300)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Tarjeta información personal
  // =========================================================================
  Widget _buildPersonalInfoCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Información Personal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
              _editingPersonal
                  ? Row(
                      children: [
                        // Cancelar
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.grisTexto),
                          onPressed: () => setState(() {
                            _editingPersonal = false;
                            _errorPersonal = '';
                            _usernameCtrl.text  = _username;
                            _emailCtrl.text     = _email;
                            _birthDateCtrl.text = _birthDate;
                            _phoneCtrl.text     = _phone;
                          }),
                        ),
                        // Guardar
                        _savingPersonal
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulFondo))
                            : IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: _savePersonalInfo,
                              ),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.azulFondo),
                      onPressed: () => setState(() => _editingPersonal = true),
                    ),
            ],
          ),

          if (_errorPersonal.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_errorPersonal,
                  style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13)),
            ),

          _buildField('Nombre Usuario', _usernameCtrl, _editingPersonal, TextInputType.text),
          _buildField('Email',          _emailCtrl,    _editingPersonal, TextInputType.emailAddress),
          _buildField('Fecha de nacimiento', _birthDateCtrl, _editingPersonal, TextInputType.datetime,
              hint: 'YYYY-MM-DD'),
          _buildField('Teléfono',       _phoneCtrl,    _editingPersonal, TextInputType.phone),
        ],
      ),
    );
  }

  // =========================================================================
  // Tarjeta gestión diabetes
  // =========================================================================
  Widget _buildDiabetesCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gestión Diabetes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
              _editingDiabetes
                  ? Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.grisTexto),
                          onPressed: () => setState(() {
                            _editingDiabetes = false;
                            _errorDiabetes = '';
                            _fsiCtrl.text = _fsi.toString();
                          }),
                        ),
                        _savingDiabetes
                            ? const SizedBox(width: 24, height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulFondo))
                            : IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: _saveDiabetes,
                              ),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit, color: AppColors.azulFondo),
                      onPressed: () => setState(() => _editingDiabetes = true),
                    ),
            ],
          ),

          if (_errorDiabetes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_errorDiabetes,
                  style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13)),
            ),

          _buildField('FSI (mg/dl x Unidad)', _fsiCtrl, _editingDiabetes, TextInputType.number),
          const SizedBox(height: 16),

          // ── Sección Ratio HC ────────────────────────────────────────── //
          const Text('Ratio HC',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          const SizedBox(height: 10),

          ..._hcRatios.asMap().entries.map((e) => _buildHcRow(e.key, e.value)),

          if (_editingDiabetes)
            Center(
              child: IconButton(
                icon: const Icon(Icons.add_circle, size: 34, color: AppColors.azulFondo),
                onPressed: _addHcRatio,
              ),
            ),
        ],
      ),
    );
  }

  // ── Fila de un tramo HC ──────────────────────────────────────────────── //
  Widget _buildHcRow(int i, HcRatio ratio) {
    final isFirst = i == 0;
    final isLast  = i == _hcRatios.length - 1;
    final timeEdit = _editingDiabetes && !isFirst && !isLast;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          _timeField(ratio.startTime, editable: timeEdit,
              onChanged: (v) => setState(() => ratio.startTime = v)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(' - ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.grisTexto)),
          ),
          _timeField(ratio.endTime, editable: timeEdit,
              onChanged: (v) => setState(() => ratio.endTime = v)),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextFormField(
              initialValue: ratio.ratioValue.toString(),
              enabled: _editingDiabetes,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.grisTexto),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
              onChanged: (v) { final val = double.tryParse(v); if (val != null) setState(() => ratio.ratioValue = val); },
            ),
          ),
          const Text('g/U', style: TextStyle(fontSize: 12, color: AppColors.grisTexto)),
          if (_editingDiabetes && _hcRatios.length > 1)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.remove_circle, color: AppColors.rojoSuave, size: 20),
              onPressed: () => _removeHcRatio(i),
            ),
        ],
      ),
    );
  }

  Widget _timeField(String time, {bool editable = false, required ValueChanged<String> onChanged}) {
    if (!editable) return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(time, style: const TextStyle(fontSize: 13, color: AppColors.grisTexto)),
    );
    return SizedBox(
      width: 58,
      child: TextFormField(
        initialValue: time,
        keyboardType: TextInputType.datetime,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.grisTexto),
        decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
        onChanged: onChanged,
      ),
    );
  }

  // ── Campo de texto reutilizable ──────────────────────────────────────── //
  Widget _buildField(String label, TextEditingController ctrl, bool enabled,
      TextInputType type, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: type,
        style: TextStyle(fontSize: 15,
            color: enabled ? AppColors.grisTexto : AppColors.grisTexto.withOpacity(0.7)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
          disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
        ),
      ),
    );
  }
}

// ── _Card ────────────────────────────────────────────────────────────────── //
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}