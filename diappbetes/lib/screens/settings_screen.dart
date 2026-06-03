import 'dart:convert';
import 'dart:typed_data';
import 'package:diappbetes/providers/theme_provider.dart';
import 'package:diappbetes/services/biometric_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';
import '../services/hc_ratio_service.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Modelo HcRatio
// ---------------------------------------------------------------------------
class HcRatio {
  String id;
  int startMins;
  int endMins;
  double ratioValue;

  HcRatio({
    this.id = '',
    required this.startMins,
    required this.endMins,
    required this.ratioValue,
  });

  String get startTime => _fmt(startMins);
  String get endTime   => _fmt(endMins);

  static String _fmt(int m) =>
      '${(m ~/ 60).toString().padLeft(2,'0')}:${(m % 60).toString().padLeft(2,'0')}';

  static int parse(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  Map<String, dynamic> toMap() => {
    'start_time':  startTime,
    'end_time':    endTime,
    'ratio_value': ratioValue,
  };
}

// ---------------------------------------------------------------------------
// Helpers de validación de ratios
// ---------------------------------------------------------------------------
List<HcRatio> _enforceFullDay(List<HcRatio> ratios) {
  if (ratios.isEmpty) {
    return [HcRatio(startMins: 0, endMins: 1440, ratioValue: 10.0)];
  }
  final r = List<HcRatio>.from(ratios);
  r.first.startMins = 0;
  r.last.endMins    = 1440;
  for (int i = 1; i < r.length; i++) {
    r[i].startMins = r[i - 1].endMins;
    if (r[i].startMins >= r[i].endMins) {
      r[i].endMins = r[i].startMins + 1;
    }
  }
  r.last.endMins = 1440;
  return r;
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
  final _profileService = ProfileService();
  final _hcRatioService = HcRatioService();
  final _authService    = AuthService();
  final _imagePicker    = ImagePicker();

  bool _loadingProfile = true;
  bool _savingPersonal = false;
  bool _savingDiabetes = false;
  bool _uploadingAvatar = false;
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;
  bool _loadingBiometric = true;

  String _username  = '';
  String _email     = '';
  String _birthDate = '';
  String _role      = 'Usuario';
  double _fsi       = 50.0;
  Uint8List? _avatarBytes;

  // ✅ MODO CELÍACO: declaración única
  bool _celiacMode = false;
  bool _savingCeliac = false;

  List<HcRatio> _hcRatios = [];

  bool _editingPersonal = false;
  bool _editingDiabetes = false;
  String _errorPersonal = '';
  String _errorDiabetes = '';

  TextEditingController? _usernameCtrl;
  TextEditingController? _emailCtrl;
  TextEditingController? _birthDateCtrl;
  TextEditingController? _fsiCtrl;

  @override
  void initState() {
    super.initState();
    _usernameCtrl  = TextEditingController();
    _emailCtrl     = TextEditingController();
    _birthDateCtrl = TextEditingController();
    _fsiCtrl       = TextEditingController();
    _loadData();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _usernameCtrl?.dispose();
    _emailCtrl?.dispose();
    _birthDateCtrl?.dispose();
    _fsiCtrl?.dispose();
    super.dispose();
  }

  String? _txt(TextEditingController? c) { try { return c?.text; } catch(_) { return null; } }
  void _set(TextEditingController? c, String v) { try { c?.text = v; } catch(_) {} }

  // ── Carga datos ──────────────────────────────────────────────────────── //
  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loadingProfile = true);
    try {
      if (_authService.currentUser == null) throw Exception('Sin sesión');
      final profile = await _profileService.getMyProfile();
      final ratioMaps = await _hcRatioService.getHcRatios();

      if (profile == null) throw Exception('Perfil no encontrado');
      if (!mounted) return;

      // Decodificar avatar si existe
      Uint8List? avatarBytes;
      final avatarBase64 = profile['avatar_base64'] as String?;
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          avatarBytes = base64Decode(avatarBase64);
          print('✅ [AVATAR] Avatar cargado: ${avatarBytes.length} bytes');
        } catch (e) {
          print('❌ [AVATAR] Error decodificando avatar: $e');
        }
      }

      // ✅ MODO CELÍACO: cargar dentro del setState
      setState(() {
        _username  = profile['username']?.toString() ?? '';
        _email     = profile['email']?.toString() ?? '';
        _birthDate = profile['birth_date']?.toString() ?? '';
        _role      = profile['role']?.toString() ?? 'Usuario';
        _fsi       = (profile['fsi'] as num?)?.toDouble() ?? 50.0;
        _avatarBytes = avatarBytes;
        _celiacMode = profile['celiac_mode'] == true;  // ✅ Aquí va la asignación

        _set(_usernameCtrl,  _username);
        _set(_emailCtrl,     _email);
        _set(_birthDateCtrl, _birthDate);
        _set(_fsiCtrl,       _fsi.toString());

        final loaded = ratioMaps.map((r) => HcRatio(
          id:         r['id']?.toString() ?? '',
          startMins:  HcRatio.parse(r['start_time']?.toString() ?? '00:00'),
          endMins:    HcRatio.parse(r['end_time']?.toString() ?? '23:59'),
          ratioValue: (r['ratio_value'] as num?)?.toDouble() ?? 10.0,
        )).toList();

        _hcRatios = _enforceFullDay(
          loaded.isNotEmpty ? loaded
              : [HcRatio(startMins: 0, endMins: 1440, ratioValue: 10.0)],
        );
      });
    } catch (e) {
      if (mounted) _showSnack('Error al cargar: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadBiometricState() async {
    final biometricService = BiometricService();
    
    final canUse = await biometricService.canCheckBiometrics();
    final isAvailable = await biometricService.isBiometricAvailable();
    final userId = _authService.currentUser?.uid;
    
    // Solo está activo si el usuario actual tiene huella habilitada
    final isEnabled = userId != null 
        ? await biometricService.isCurrentUserBiometricEnabled(userId)
        : false;
    
    if (mounted) {
      setState(() {
        _canUseBiometric = canUse && isAvailable;
        _biometricEnabled = isEnabled;
        _loadingBiometric = false;
      });
    }
  }

  // ── Toggle de autenticación biométrica ────────────────────────────────── //
  Future<void> _toggleBiometric() async {
    if (!_canUseBiometric) return;
    
    final biometricService = BiometricService();
    final userId = _authService.currentUser?.uid;
    final userEmail = _authService.currentUser?.email;
    
    if (userId == null || userEmail == null) return;

    if (!_biometricEnabled) {
      // Activar: pedir contraseña
      final password = await _askPasswordForBiometric();
      
      if (password == null || password.isEmpty) {
        _showSnack('Se requiere contraseña para activar la huella', isError: true);
        return;
      }
      
      // Verificar huella
      final authenticated = await biometricService.authenticate();
      if (authenticated && mounted) {
        // Guardar credenciales para ESTE usuario
        await biometricService.enableForUser(
          userId: userId,
          email: userEmail,
          password: password,
        );
        await _profileService.setBiometricLoginEnabled(true);
        setState(() => _biometricEnabled = true);
        _showSnack('Autenticación biométrica activada');
      }
    } else {
      // Desactivar: borrar credenciales
      await biometricService.disable();
      await _profileService.setBiometricLoginEnabled(false);
      setState(() => _biometricEnabled = false);
      _showSnack('Autenticación biométrica desactivada');
    }
  }

  Future<String?> _askPasswordForBiometric() async {
    final ctrl = TextEditingController();
    bool obs = true;
    
    final r = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          title: Text('Activar huella dactilar',
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.primary, 
                fontWeight: FontWeight.bold,
              )),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Introduce tu contraseña para guardarla de forma segura y poder iniciar sesión con tu huella.',
                  style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                obscureText: obs,
                autofocus: true,
                style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(ctx).dividerColor)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(ctx).colorScheme.primary)),
                  suffixIcon: IconButton(
                    icon: Icon(obs ? Icons.visibility_off : Icons.visibility, 
                        color: Theme.of(ctx).textTheme.bodySmall?.color, size: 20),
                    onPressed: () => setS(() => obs = !obs),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), 
                child: Text('Cancelar', 
                    style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color))),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Guardar', 
                    style: TextStyle(color: AppColors.verdesuave, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return r;
  }

  // ── Guardar info personal ─────────────────────────────────────────────── //
  Future<void> _savePersonalInfo() async {
    setState(() => _errorPersonal = '');
    final u = _txt(_usernameCtrl)?.trim() ?? '';
    final e = _txt(_emailCtrl)?.trim() ?? '';
    final b = _txt(_birthDateCtrl)?.trim() ?? '';

    if (u.isEmpty || e.isEmpty || b.isEmpty) {
      setState(() => _errorPersonal = 'Todos los campos son obligatorios');
      return;
    }
    setState(() => _savingPersonal = true);
    try {
      await _profileService.updatePersonalInfo(username: u, email: e, birthDate: b);
      setState(() { _username = u; _email = e; _birthDate = b; _editingPersonal = false; });
      _showSnack('Perfil actualizado');
    } on FirebaseAuthException catch (e) {
      setState(() => _errorPersonal = AuthService.translateError(e));
    } catch (_) {
      setState(() => _errorPersonal = 'Error al guardar.');
    } finally {
      if (mounted) setState(() => _savingPersonal = false);
    }
  }

  // ─ Guardar diabetes ──────────────────────────────────────────────────── //
  Future<void> _saveDiabetes() async {
    setState(() => _errorDiabetes = '');
    final fsiVal = double.tryParse(_txt(_fsiCtrl) ?? '');
    if (fsiVal == null || fsiVal <= 0) {
      setState(() => _errorDiabetes = 'El FSI debe ser mayor que 0');
      return;
    }
    setState(() => _savingDiabetes = true);
    try {
      await _profileService.updateFsi(fsiVal);
      await _hcRatioService.saveAll(_hcRatios.map((r) => r.toMap()).toList());
      setState(() { _fsi = fsiVal; _editingDiabetes = false; });
      _showSnack('Datos de diabetes actualizados');
    } catch (_) {
      setState(() => _errorDiabetes = 'Error al guardar.');
    } finally {
      if (mounted) setState(() => _savingDiabetes = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MODO CELÍACO
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _toggleCeliacMode(bool value) async {
    setState(() => _savingCeliac = true);
    try {
      await _profileService.updateCeliacMode(value);
      if (mounted) {
        setState(() {
          _celiacMode = value;
          _savingCeliac = false;
        });
        _showSnack(value ? 'Modo celíaco activado' : 'Modo celíaco desactivado');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingCeliac = false);
        _showSnack('Error al guardar', isError: true);
      }
    }
  }

  // =========================================================================
  // LÓGICA DE RATIOS HC
  // =========================================================================

  void _changeEndTime(int i, int newEndMins) {
    setState(() {
      final r = _hcRatios;
      final minEnd = r[i].startMins + 1;
      final maxEnd = (i < r.length - 1)
          ? r[i + 1].endMins - 1
          : 1440;

      final clamped = newEndMins.clamp(minEnd, maxEnd);
      r[i].endMins = clamped;

      if (i < r.length - 1) {
        r[i + 1].startMins = clamped;
        if (r[i + 1].startMins >= r[i + 1].endMins) {
          r[i + 1].endMins = r[i + 1].startMins + 1;
        }
      }
      r.last.endMins = 1440;
    });
  }

  void _changeStartTime(int i, int newStartMins) {
    if (i == 0) return;
    setState(() {
      final r = _hcRatios;
      final minStart = r[i - 1].startMins + 1;
      final maxStart = r[i].endMins - 1;

      final clamped = newStartMins.clamp(minStart, maxStart);
      r[i].startMins = clamped;
      r[i - 1].endMins = clamped;
    });
  }

  void _addHcRatio() {
    setState(() {
      final last = _hcRatios.last;
      final duration = last.endMins - last.startMins;

      if (duration < 2) {
        _showSnack('No hay espacio para añadir otro tramo', isError: true);
        return;
      }

      final mid = last.startMins + (duration ~/ 2);
      final newRatio = HcRatio(
        startMins: mid,
        endMins:   last.endMins,
        ratioValue: last.ratioValue,
      );
      last.endMins = mid;
      _hcRatios.add(newRatio);
      _hcRatios = _enforceFullDay(_hcRatios);
    });
  }

  void _removeHcRatio(int i) {
    if (_hcRatios.length <= 1) return;
    setState(() {
      final removed = _hcRatios.removeAt(i);
      if (i == 0) {
        _hcRatios.first.startMins = 0;
      } else {
        _hcRatios[i - 1].endMins = removed.endMins;
      }
      _hcRatios = _enforceFullDay(_hcRatios);
    });
  }

  // ─ TimePicker ────────────────────────────────────────────────────────── //
  Future<int?> _pickTime(int currentMins) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentMins ~/ 60, minute: currentMins % 60),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: Theme.of(ctx).colorScheme.primary,
            onPrimary: Theme.of(ctx).colorScheme.onPrimary,
            surface: Theme.of(ctx).colorScheme.surface,
            onSurface: Theme.of(ctx).colorScheme.onSurface,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.primary,
            ),
          ),
        ),
        child: MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      ),
    );
    if (picked == null) return null;
    return picked.hour * 60 + picked.minute;
  }

  // ── DatePicker ────────────────────────────────────────────────────────── //
  Future<void> _pickBirthDate() async {
    DateTime? init;
    try {
      final p = (_txt(_birthDateCtrl) ?? '').split('-');
      if (p.length == 3) init = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {}
    init ??= DateTime.now().subtract(const Duration(days: 365 * 20));

    final picked = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
            primary: Theme.of(ctx).colorScheme.primary,
            onPrimary: Theme.of(ctx).colorScheme.onPrimary,
            surface: Theme.of(ctx).colorScheme.surface,
            onSurface: Theme.of(ctx).colorScheme.onSurface,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.primary,
            ),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final f = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
      setState(() { _set(_birthDateCtrl, f); _birthDate = f; });
    }
  }

  // =========================================================================
  // SISTEMA DE AVATAR (base64 en Firestore)
  // =========================================================================

  Future<void> _showAvatarOptions() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text('Cambiar foto de perfil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  )),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
                title: Text('Seleccionar de la galería',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSaveAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryColor),
                title: Text('Tomar una foto',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSaveAvatar(ImageSource.camera);
                },
              ),
              if (_avatarBytes != null) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.rojoSuave),
                  title: const Text('Eliminar foto actual',
                      style: TextStyle(color: AppColors.rojoSuave)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDeleteAvatar();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSaveAvatar(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 75,
      );

      if (image == null) return;
      if (!mounted) return;
      setState(() => _uploadingAvatar = true);

      final Uint8List imageBytes = await image.readAsBytes();
      print('📏 [AVATAR] Tamaño: ${(imageBytes.length / 1024).toStringAsFixed(1)} KB');

      final success = await _profileService.updateAvatarBase64(imageBytes);

      if (!mounted) return;

      if (success) {
        setState(() {
          _avatarBytes = imageBytes;
          _uploadingAvatar = false;
        });
        _showSnack('Foto de perfil actualizada');
      } else {
        setState(() => _uploadingAvatar = false);
        _showSnack('Error al guardar la imagen', isError: true);
      }
    } catch (e) {
      print('❌ [AVATAR] Error: $e');
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        _showSnack('Error: $e', isError: true);
      }
    }
  }

  Future<void> _confirmDeleteAvatar() async {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text('Eliminar foto',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que quieres eliminar tu foto de perfil?',
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: textSmallColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _uploadingAvatar = true);

    try {
      await _profileService.deleteAvatar();
      if (mounted) {
        setState(() {
          _avatarBytes = null;
          _uploadingAvatar = false;
        });
        _showSnack('Foto de perfil eliminada');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        _showSnack('Error al eliminar: $e', isError: true);
      }
    }
  }

  // ── Logout / Delete ───────────────────────────────────────────────────── //
  Future<void> _logout() async {
    final ok = await _confirm('Cierre de Sesión', '¿Estás seguro de cerrar sesión?',
        'Cerrar Sesión', AppColors.rojoSuave);
    if (!ok) return;
    await _authService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/auth');
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirm('¿Eliminar cuenta?',
        'Esta acción es irreversible.\nSe eliminarán todos tus datos.',
        'Eliminar', AppColors.rojoSuave);
    if (!ok) return;

    final pw = await _askPassword();
    if (pw == null || pw.isEmpty) return;

    try {
      final user = _authService.currentUser!;
      await user.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: user.email!, password: pw));
      await _profileService.deleteAccount();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/auth', (_) => false);
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.translateError(e), isError: true);
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    }
  }

  Future<bool> _confirm(String title, String msg, String btn, Color color) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).cardColor,
        title: Text(title, 
            style: TextStyle(
              color: Theme.of(ctx).colorScheme.primary, 
              fontWeight: FontWeight.bold,
            )),
        content: Text(msg, 
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', 
                  style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(btn, 
                  style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    return r ?? false;
  }

  Future<String?> _askPassword() async {
    final ctrl = TextEditingController();
    bool obs = true;
    final r = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          title: Text('Confirmar contraseña',
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.primary, 
                fontWeight: FontWeight.bold,
              )),
          content: TextField(
            controller: ctrl, obscureText: obs, autofocus: true,
            style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color),
            decoration: InputDecoration(
              labelText: 'Contraseña actual',
              labelStyle: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(ctx).dividerColor)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(ctx).colorScheme.primary)),
              suffixIcon: IconButton(
                icon: Icon(obs ? Icons.visibility_off : Icons.visibility, 
                    color: Theme.of(ctx).textTheme.bodySmall?.color, size: 20),
                onPressed: () => setS(() => obs = !obs),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), 
                child: Text('Cancelar', 
                    style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color))),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: Text('Confirmar', 
                    style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
    ctrl.dispose();
    return r;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.rojoSuave : AppColors.verdesuave,
      ));
    });
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
              color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('DiAppBetes',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor, 
              fontWeight: FontWeight.bold,
            )),
      ),
      body: _loadingProfile
          ? Center(child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mi Perfil',
                      style: TextStyle(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  const SizedBox(height: 14),
                  _buildProfileCard(),
                  const SizedBox(height: 12),
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 12),
                  _buildAppearanceCard(context),
                  const SizedBox(height: 12),
                  _buildCeliacCard(),
                  const SizedBox(height: 12),
                  _buildBiometricCard(),
                  const SizedBox(height: 12),
                  _buildDiabetesCard(),
                ],
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TARJETA MODO CELÍACO
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildCeliacCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grain, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modo celíaco',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        )),
                    Text('Mostrará si los alimentos contienen gluten',
                        style: TextStyle(fontSize: 12, color: textSmallColor)),
                  ],
                ),
              ),
              if (_savingCeliac)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: primaryColor),
                )
              else
                Switch(
                  value: _celiacMode,
                  onChanged: _toggleCeliacMode,
                  activeColor: primaryColor,
                ),
            ],
          ),
          if (_celiacMode) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Se mostrará un indicador junto a cada alimento indicando si contiene gluten.',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fingerprint, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Iniciar sesión con huella',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        )),
                    Text('Usa tu huella dactilar para acceder',
                        style: TextStyle(fontSize: 12, color: textSmallColor)),
                  ],
                ),
              ),
              if (_loadingBiometric)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: primaryColor),
                )
              else
                Switch(
                  value: _canUseBiometric && _biometricEnabled,
                  onChanged: _canUseBiometric ? (v) => _toggleBiometric() : null,
                  activeColor: primaryColor,
                ),
            ],
          ),
          if (!_canUseBiometric) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tu dispositivo no soporta autenticación biométrica o no tienes huella configurada.',
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tarjeta perfil ────────────────────────────────────────────────────── //
  Widget _buildProfileCard() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(
          onTap: _uploadingAvatar ? null : _showAvatarOptions,
          child: Stack(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary, 
                    width: 3,
                  ),
                  image: _avatarBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_avatarBytes!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _avatarBytes == null
                    ? Icon(Icons.person, 
                        size: 30, 
                        color: Theme.of(context).colorScheme.primary)
                    : null,
              ),
              if (!_uploadingAvatar)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).cardColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 10,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              if (_uploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_username, 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).colorScheme.primary,
              )),
          const SizedBox(height: 2),
          Text(_email, 
              style: TextStyle(
                fontSize: 13, 
                color: Theme.of(context).textTheme.bodySmall?.color,
              )),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                border: Border.all(color: Theme.of(context).colorScheme.primary), 
                borderRadius: BorderRadius.circular(20)),
            child: Text(_role, 
                style: TextStyle(
                  fontSize: 12, 
                  color: Theme.of(context).colorScheme.primary, 
                  fontWeight: FontWeight.w500,
                )),
          ),
        ])),
      ]),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: AppColors.rojoSuave, size: 20),
        label: const Text('Cerrar Sesión', 
            style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.rojoSuave),
            minimumSize: const Size(double.infinity, 46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      const SizedBox(height: 8),
      Center(child: GestureDetector(
        onTap: _deleteAccount,
        child: const Text('Eliminar Cuenta',
            style: TextStyle(fontSize: 13, color: AppColors.rojoSuave, fontWeight: FontWeight.w300)),
      )),
    ]),
  );

  Widget _buildAppearanceCard(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final cardColor = Theme.of(context).cardColor;
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color ?? AppColors.grisTexto;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0x1A000000),
            blurRadius: 12, 
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apariencia',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: Theme.of(context).colorScheme.primary,
              )),
          const SizedBox(height: 16),
          Text('Seguir configuración del sistema',
              style: TextStyle(fontSize: 13, color: subtitleColor)),
          const SizedBox(height: 8),
          Row(
            children: [
              _modeChip(context, 'Claro', Icons.light_mode, ThemeMode.light, themeProvider),
              const SizedBox(width: 8),
              _modeChip(context, 'Oscuro', Icons.dark_mode, ThemeMode.dark, themeProvider),
              const SizedBox(width: 8),
              _modeChip(context, 'Sistema', Icons.auto_mode, ThemeMode.system, themeProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, String label, IconData icon,
      ThemeMode mode, ThemeProvider provider) {
    final isSelected = provider.mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => context.read<ThemeProvider>().setMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: isSelected 
                      ? Theme.of(context).colorScheme.onPrimary 
                      : Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).textTheme.bodySmall?.color,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tarjeta info personal ─────────────────────────────────────────────── //
  Widget _buildPersonalInfoCard() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Información Personal',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary,
            )),
        _editingPersonal
            ? Row(children: [
                IconButton(icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodySmall?.color),
                    onPressed: () => setState(() {
                      _editingPersonal = false; _errorPersonal = '';
                      _set(_usernameCtrl, _username); _set(_emailCtrl, _email); _set(_birthDateCtrl, _birthDate);
                    })),
                _savingPersonal
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(
                        strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                    : IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _savePersonalInfo),
              ])
            : IconButton(icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                onPressed: () => setState(() => _editingPersonal = true)),
      ]),
      if (_errorPersonal.isNotEmpty)
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(_errorPersonal, 
                style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13))),
      _field('Nombre Usuario', _usernameCtrl, _editingPersonal, TextInputType.text),
      _field('Email', _emailCtrl, _editingPersonal, TextInputType.emailAddress),
      _field('Fecha de nacimiento', _birthDateCtrl, _editingPersonal, TextInputType.datetime,
          onTap: _editingPersonal ? _pickBirthDate : null, hint: 'YYYY-MM-DD'),
    ]),
  );

  // ── Tarjeta gestión diabetes ──────────────────────────────────────────── //
  Widget _buildDiabetesCard() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Gestión Diabetes',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary,
            )),
        _editingDiabetes
            ? Row(children: [
                IconButton(icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodySmall?.color),
                    onPressed: () => setState(() {
                      _editingDiabetes = false; _errorDiabetes = '';
                      _set(_fsiCtrl, _fsi.toString());
                    })),
                _savingDiabetes
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(
                        strokeWidth: 2, color: Theme.of(context).colorScheme.primary))
                    : IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveDiabetes),
              ])
            : IconButton(icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                onPressed: () => setState(() => _editingDiabetes = true)),
      ]),
      if (_errorDiabetes.isNotEmpty)
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(_errorDiabetes, 
                style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13))),
      _field('FSI (mg/dl x Unidad)', _fsiCtrl, _editingDiabetes, TextInputType.number),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Ratio HC', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary,
            )),
      ]),
      const SizedBox(height: 10),
      ..._hcRatios.asMap().entries.map((e) => _buildHcRow(e.key, e.value)),
      if (_editingDiabetes)
        Center(child: IconButton(
          icon: Icon(Icons.add_circle, size: 34, color: Theme.of(context).colorScheme.primary),
          onPressed: _addHcRatio,
          tooltip: 'Añadir tramo',
        )),
    ]),
  );

  // ── Fila de un tramo HC ──────────────────────────────────────────────── //
  Widget _buildHcRow(int i, HcRatio ratio) {
    final isFirst = i == 0;
    final isLast  = i == _hcRatios.length - 1;
    final canEditStart = _editingDiabetes && !isFirst;
    final canEditEnd   = _editingDiabetes && !isLast;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, 
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : const Color(0x1A000000),
            blurRadius: 6, 
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(children: [
        _timeChip(ratio.startTime, tappable: canEditStart,
            onTap: canEditStart ? () async {
              final picked = await _pickTime(ratio.startMins);
              if (picked != null) _changeStartTime(i, picked);
            } : null),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text('—', 
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color, 
                  fontWeight: FontWeight.bold,
                ))),

        _timeChip(ratio.endTime, tappable: canEditEnd,
            onTap: canEditEnd ? () async {
              final picked = await _pickTime(ratio.endMins);
              if (picked != null) _changeEndTime(i, picked);
            } : null),

        const SizedBox(width: 10),

        Expanded(
          child: TextFormField(
            key: ValueKey('ratio_${ratio.id}_${ratio.startMins}'),
            initialValue: ratio.ratioValue.toString(),
            enabled: _editingDiabetes,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14, 
              fontWeight: FontWeight.bold, 
              color: Theme.of(context).colorScheme.primary,
            ),
            decoration: InputDecoration(
              isDense: true, 
              border: InputBorder.none, 
              contentPadding: EdgeInsets.zero,
              suffixText: 'g/U', 
              suffixStyle: TextStyle(
                fontSize: 11, 
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            onChanged: (v) { final val = double.tryParse(v); if (val != null) setState(() => ratio.ratioValue = val); },
          ),
        ),

        if (_editingDiabetes && _hcRatios.length > 1)
          IconButton(
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            icon: const Icon(Icons.remove_circle_outline, color: AppColors.rojoSuave, size: 22),
            onPressed: () => _removeHcRatio(i),
          ),
      ]),
    );
  }

  Widget _timeChip(String time, {bool tappable = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: tappable 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
              : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkSurface
                  : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: tappable 
              ? Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.4)) 
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(time, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: tappable 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).textTheme.bodySmall?.color)),
          if (tappable) ...[
            const SizedBox(width: 3),
            Icon(Icons.edit, size: 11, color: Theme.of(context).colorScheme.primary),
          ],
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController? ctrl, bool enabled, TextInputType type,
      {String? hint, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AbsorbPointer(
          absorbing: onTap != null && enabled,
          child: TextField(
            controller: ctrl,
            enabled: enabled && onTap == null,
            keyboardType: type,
            readOnly: onTap != null && enabled,
            style: TextStyle(
              fontSize: 15,
              color: enabled 
                  ? Theme.of(context).textTheme.bodyLarge?.color 
                  : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
            ),
            decoration: InputDecoration(
              labelText: label, 
              hintText: hint,
              labelStyle: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color, 
                fontSize: 13,
              ),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
              disabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              suffixIcon: onTap != null && enabled
                  ? Icon(Icons.calendar_today, 
                      color: Theme.of(context).colorScheme.primary, size: 18) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor, 
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.3)
              : const Color(0x1A000000),
          blurRadius: 12, 
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: child,
  );
}