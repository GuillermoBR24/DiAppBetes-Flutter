import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/profile_service.dart';
import '../services/hc_ratio_service.dart';
import '../services/auth_service.dart';

// ---------------------------------------------------------------------------
// Modelo HcRatio
// ---------------------------------------------------------------------------
class HcRatio {
  String id;
  int startMins; // minutos desde 00:00
  int endMins;   // minutos desde 00:00
  double ratioValue;

  HcRatio({
    this.id = '',
    required this.startMins,
    required this.endMins,
    required this.ratioValue,
  });

  // Helpers de formato
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

/// Garantiza que la lista cubre exactamente 00:00–24:00 (1440 min)
/// sin huecos ni solapamientos.
/// Regla: los tramos son contiguos; startMins[i+1] == endMins[i].
/// El primer tramo SIEMPRE empieza en 0, el último SIEMPRE termina en 1440.
List<HcRatio> _enforceFullDay(List<HcRatio> ratios) {
  if (ratios.isEmpty) {
    return [HcRatio(startMins: 0, endMins: 1440, ratioValue: 10.0)];
  }
  final r = List<HcRatio>.from(ratios);
  r.first.startMins = 0;
  r.last.endMins    = 1440;
  // Encadena los tramos intermedios
  for (int i = 1; i < r.length; i++) {
    r[i].startMins = r[i - 1].endMins;
    // Si quedó invertido, forzar mínimo 1 minuto de duración
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

  bool _loadingProfile = true;
  bool _savingPersonal = false;
  bool _savingDiabetes = false;

  String _username  = '';
  String _email     = '';
  String _birthDate = '';
  String _role      = 'usuario';
  double _fsi       = 50.0;

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

      setState(() {
        _username  = profile['username']?.toString() ?? '';
        _email     = profile['email']?.toString() ?? '';
        _birthDate = profile['birth_date']?.toString() ?? '';
        _role      = profile['role']?.toString() ?? 'usuario';
        _fsi       = (profile['fsi'] as num?)?.toDouble() ?? 50.0;

        _set(_usernameCtrl,  _username);
        _set(_emailCtrl,     _email);
        _set(_birthDateCtrl, _birthDate);
        _set(_fsiCtrl,       _fsi.toString());

        // Convertir los mapas a objetos HcRatio con startMins/endMins
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

  // ── Guardar diabetes ──────────────────────────────────────────────────── //
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

  // =========================================================================
  // LÓGICA DE RATIOS HC — Edición de fronteras con validación en cascada
  // =========================================================================

  /// Cambia endTime del tramo [i] y automáticamente ajusta startTime de [i+1]
  /// para mantener la continuidad sin solapamientos.
  void _changeEndTime(int i, int newEndMins) {
    setState(() {
      final r = _hcRatios;

      // Límites: mínimo startMins+1, máximo startMins del siguiente o 1439
      final minEnd = r[i].startMins + 1;
      final maxEnd = (i < r.length - 1)
          ? r[i + 1].endMins - 1   // no puede sobrepasar el fin del siguiente
          : 1440;

      final clamped = newEndMins.clamp(minEnd, maxEnd);
      r[i].endMins = clamped;

      // El siguiente tramo arranca donde termina este
      if (i < r.length - 1) {
        r[i + 1].startMins = clamped;
        // Si quedó sin espacio, comprimir (siempre mínimo 1 min)
        if (r[i + 1].startMins >= r[i + 1].endMins) {
          r[i + 1].endMins = r[i + 1].startMins + 1;
        }
      }

      // El último siempre termina en 1440
      r.last.endMins = 1440;
    });
  }

  /// Cambia startTime del tramo [i] y ajusta endTime de [i-1]
  void _changeStartTime(int i, int newStartMins) {
    if (i == 0) return; // el primero siempre empieza en 00:00
    setState(() {
      final r = _hcRatios;

      final minStart = r[i - 1].startMins + 1;
      final maxStart = r[i].endMins - 1;

      final clamped = newStartMins.clamp(minStart, maxStart);
      r[i].startMins = clamped;

      // El tramo anterior termina donde empieza este
      r[i - 1].endMins = clamped;
    });
  }

  /// Añade un tramo dividiendo el último a la mitad
  void _addHcRatio() {
    setState(() {
      final last = _hcRatios.last;
      final duration = last.endMins - last.startMins;

      if (duration < 2) {
        // Sin espacio para dividir
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

  /// Elimina el tramo [i] y extiende el anterior para cubrir su hueco
  void _removeHcRatio(int i) {
    if (_hcRatios.length <= 1) return;
    setState(() {
      final removed = _hcRatios.removeAt(i);
      if (i == 0) {
        // El nuevo primero empieza en 00:00
        _hcRatios.first.startMins = 0;
      } else {
        // El anterior absorbe el hueco
        _hcRatios[i - 1].endMins = removed.endMins;
      }
      _hcRatios = _enforceFullDay(_hcRatios);
    });
  }

  // ── Abrir TimePicker ──────────────────────────────────────────────────── //
  Future<int?> _pickTime(int currentMins) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentMins ~/ 60, minute: currentMins % 60),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.azulFondo,
            onPrimary: AppColors.blanco,
            surface: AppColors.blanco,
            onSurface: AppColors.grisTexto,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.azulFondo)),
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

  // ── DatePicker para fecha de nacimiento ──────────────────────────────── //
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
          colorScheme: const ColorScheme.light(
            primary: AppColors.azulFondo, onPrimary: AppColors.blanco,
            surface: AppColors.blanco, onSurface: AppColors.grisTexto),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.azulFondo)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      final f = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
      setState(() { _set(_birthDateCtrl, f); _birthDate = f; });
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
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: AppColors.grisTexto)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.grisTexto))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: Text(btn, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
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
          title: const Text('Confirmar contraseña',
              style: TextStyle(color: AppColors.azulFondo, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl, obscureText: obs, autofocus: true,
            decoration: InputDecoration(
              labelText: 'Contraseña actual',
              labelStyle: const TextStyle(color: AppColors.grisTexto),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
              suffixIcon: IconButton(
                icon: Icon(obs ? Icons.visibility_off : Icons.visibility, color: AppColors.grisTexto, size: 20),
                onPressed: () => setS(() => obs = !obs),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.grisTexto))),
            TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Confirmar', style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.bold))),
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
          IconButton(icon: const Icon(Icons.settings, color: AppColors.blanco), onPressed: () {}),
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

  // ── Tarjeta perfil ────────────────────────────────────────────────────── //
  Widget _buildProfileCard() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 54, height: 54,
          decoration: BoxDecoration(shape: BoxShape.circle,
              border: Border.all(color: AppColors.azulFondo, width: 3)),
          child: const Icon(Icons.person, size: 30, color: AppColors.azulFondo),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
          const SizedBox(height: 2),
          Text(_email, style: const TextStyle(fontSize: 13, color: AppColors.grisTexto)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD),
                border: Border.all(color: AppColors.azulFondo), borderRadius: BorderRadius.circular(20)),
            child: Text(_role, style: const TextStyle(fontSize: 12, color: AppColors.azulFondo, fontWeight: FontWeight.w500)),
          ),
        ])),
      ]),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(Icons.logout, color: AppColors.rojoSuave, size: 20),
        label: const Text('Cerrar Sesión', style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.rojoSuave),
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

  // ── Tarjeta info personal ─────────────────────────────────────────────── //
  Widget _buildPersonalInfoCard() => _Card(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Información Personal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
        _editingPersonal
            ? Row(children: [
                IconButton(icon: const Icon(Icons.close, color: AppColors.grisTexto),
                    onPressed: () => setState(() {
                      _editingPersonal = false; _errorPersonal = '';
                      _set(_usernameCtrl, _username); _set(_emailCtrl, _email); _set(_birthDateCtrl, _birthDate);
                    })),
                _savingPersonal
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulFondo))
                    : IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _savePersonalInfo),
              ])
            : IconButton(icon: const Icon(Icons.edit, color: AppColors.azulFondo),
                onPressed: () => setState(() => _editingPersonal = true)),
      ]),
      if (_errorPersonal.isNotEmpty)
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(_errorPersonal, style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13))),
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
        const Text('Gestión Diabetes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
        _editingDiabetes
            ? Row(children: [
                IconButton(icon: const Icon(Icons.close, color: AppColors.grisTexto),
                    onPressed: () => setState(() {
                      _editingDiabetes = false; _errorDiabetes = '';
                      _set(_fsiCtrl, _fsi.toString());
                    })),
                _savingDiabetes
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.azulFondo))
                    : IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: _saveDiabetes),
              ])
            : IconButton(icon: const Icon(Icons.edit, color: AppColors.azulFondo),
                onPressed: () => setState(() => _editingDiabetes = true)),
      ]),
      if (_errorDiabetes.isNotEmpty)
        Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Text(_errorDiabetes, style: const TextStyle(color: AppColors.rojoSuave, fontSize: 13))),
      _field('FSI (mg/dl x Unidad)', _fsiCtrl, _editingDiabetes, TextInputType.number),
      const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Ratio HC', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.azulFondo)),
      ]),
      const SizedBox(height: 10),
      ..._hcRatios.asMap().entries.map((e) => _buildHcRow(e.key, e.value)),
      if (_editingDiabetes)
        Center(child: IconButton(
          icon: const Icon(Icons.add_circle, size: 34, color: AppColors.azulFondo),
          onPressed: _addHcRatio,
          tooltip: 'Añadir tramo',
        )),
    ]),
  );

  bool get _coversFullDay {
    if (_hcRatios.isEmpty) return false;
    return _hcRatios.first.startMins == 0 && _hcRatios.last.endMins == 1440;
  }

  // ── Fila de un tramo HC ──────────────────────────────────────────────── //
  Widget _buildHcRow(int i, HcRatio ratio) {
    final isFirst = i == 0;
    final isLast  = i == _hcRatios.length - 1;

    // La frontera izquierda (start) es editable si NO es el primer tramo
    // La frontera derecha (end) es editable si NO es el último tramo
    // (el último siempre termina en 23:59/24:00)
    final canEditStart = _editingDiabetes && !isFirst;
    final canEditEnd   = _editingDiabetes && !isLast;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.blanco, borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        // ── Hora inicio ─── //
        _timeChip(ratio.startTime, tappable: canEditStart,
            onTap: canEditStart ? () async {
              final picked = await _pickTime(ratio.startMins);
              if (picked != null) _changeStartTime(i, picked);
            } : null),

        const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('—', style: TextStyle(color: AppColors.grisTexto, fontWeight: FontWeight.bold))),

        // ── Hora fin ─── //
        _timeChip(ratio.endTime, tappable: canEditEnd,
            onTap: canEditEnd ? () async {
              final picked = await _pickTime(ratio.endMins);
              if (picked != null) _changeEndTime(i, picked);
            } : null),

        const SizedBox(width: 10),

        // ── Valor ratio ─── //
        Expanded(
          child: TextFormField(
            key: ValueKey('ratio_${ratio.id}_${ratio.startMins}'),
            initialValue: ratio.ratioValue.toString(),
            enabled: _editingDiabetes,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.azulFondo),
            decoration: const InputDecoration(
              isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero,
              suffixText: 'g/U', suffixStyle: TextStyle(fontSize: 11, color: AppColors.grisTexto),
            ),
            onChanged: (v) { final val = double.tryParse(v); if (val != null) setState(() => ratio.ratioValue = val); },
          ),
        ),

        // ── Eliminar ─── //
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
          color: tappable ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
          border: tappable ? Border.all(color: AppColors.azulFondo.withOpacity(0.4)) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(time, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: tappable ? AppColors.azulFondo : AppColors.grisTexto)),
          if (tappable) ...[
            const SizedBox(width: 3),
            const Icon(Icons.edit, size: 11, color: AppColors.azulFondo),
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
            style: TextStyle(fontSize: 15,
                color: enabled ? AppColors.grisTexto : AppColors.grisTexto.withOpacity(0.6)),
            decoration: InputDecoration(
              labelText: label, hintText: hint,
              labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.azulFondo)),
              disabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.grisDivider)),
              suffixIcon: onTap != null && enabled
                  ? const Icon(Icons.calendar_today, color: AppColors.azulFondo, size: 18) : null,
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
      color: AppColors.cardBackground, borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
    ),
    child: child,
  );
}