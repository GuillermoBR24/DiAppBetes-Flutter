import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Modelos de datos (hardcodeados — TODO: conectar con backend)
// ---------------------------------------------------------------------------
class Profile {
  String id;
  String username;
  String email;
  String birthDate;
  String phone;
  String role;
  double fsi;

  Profile({
    required this.id,
    required this.username,
    required this.email,
    required this.birthDate,
    required this.phone,
    required this.role,
    required this.fsi,
  });
}

class HcRatio {
  String startTime;
  String endTime;
  double ratioValue;

  HcRatio({
    required this.startTime,
    required this.endTime,
    required this.ratioValue,
  });
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
  // ── Datos hardcodeados (TODO: reemplazar con ProfileService.getMyProfile()) ──
  late Profile profile;
  late double editedFsi;

  // TODO: reemplazar con HcRatioService.getHcRatios()
  List<HcRatio> hcRatios = [];

  bool isEditingPersonalInfo = false;
  bool isEditingDiabetes = false;

  String errorPersonal = '';
  String errorDiabetes = '';

  // Controllers para los campos de texto editables
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _phoneController;
  late TextEditingController _fsiController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHcRatios();
  }

  void _loadProfile() {
    // TODO: reemplazar con llamada a ProfileService.getMyProfile()
    profile = Profile(
      id: '1',
      username: 'Guillermo',
      email: 'guillermo@example.com',
      birthDate: '1990-01-01',
      phone: '600-123-456',
      role: 'usuario',
      fsi: 50.0,
    );
    editedFsi = profile.fsi;

    _usernameController  = TextEditingController(text: profile.username);
    _emailController     = TextEditingController(text: profile.email);
    _birthDateController = TextEditingController(text: profile.birthDate);
    _phoneController     = TextEditingController(text: profile.phone);
    _fsiController       = TextEditingController(text: profile.fsi.toString());
  }

  void _loadHcRatios() {
    // TODO: reemplazar con llamada a HcRatioService.getHcRatios()
    hcRatios = [
      HcRatio(startTime: '00:00', endTime: '11:59', ratioValue: 10.0),
      HcRatio(startTime: '12:00', endTime: '17:59', ratioValue: 12.0),
      HcRatio(startTime: '18:00', endTime: '23:59', ratioValue: 8.0),
    ];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _fsiController.dispose();
    super.dispose();
  }

  // ── Lógica info personal ────────────────────────────────────────────── //
  void _toggleEditPersonalInfo() {
    setState(() => errorPersonal = '');

    if (isEditingPersonalInfo) {
      if (_usernameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _birthDateController.text.isEmpty ||
          _phoneController.text.isEmpty) {
        setState(() => errorPersonal = 'Todos los campos son obligatorios');
        return;
      }
      // TODO: llamar a ProfileService.updateProfile(...)
      setState(() {
        profile.username  = _usernameController.text;
        profile.email     = _emailController.text;
        profile.birthDate = _birthDateController.text;
        profile.phone     = _phoneController.text;
        isEditingPersonalInfo = false;
      });
    } else {
      setState(() => isEditingPersonalInfo = true);
    }
  }

  // ── Lógica gestión diabetes ─────────────────────────────────────────── //
  void _toggleEditDiabetes() {
    if (isEditingDiabetes) {
      final fsiVal = double.tryParse(_fsiController.text);
      if (fsiVal == null || fsiVal <= 0) {
        setState(() => errorDiabetes = 'El FSI debe ser mayor que 0');
        return;
      }
      // TODO: llamar a ProfileService.updateProfile(fsi) + HcRatioService.saveAll()
      setState(() {
        profile.fsi = fsiVal;
        editedFsi = fsiVal;
        isEditingDiabetes = false;
        errorDiabetes = '';
      });
    } else {
      setState(() {
        _fsiController.text = profile.fsi.toString();
        isEditingDiabetes = true;
      });
    }
  }

  // ── Añadir tramo HC ─────────────────────────────────────────────────── //
  void _addHcRatio() {
    setState(() {
      if (hcRatios.isEmpty) {
        hcRatios.add(HcRatio(startTime: '00:00', endTime: '23:59', ratioValue: 10.0));
        return;
      }
      final last = hcRatios.last;
      final lastStartMins = _timeToMinutes(last.startTime);
      final lastEndMins   = _timeToMinutes(last.endTime);
      final halfMins      = ((lastStartMins + lastEndMins) / 2).floor();
      final halfStr       = _minutesToTime(halfMins);

      last.endTime = halfStr;
      hcRatios.add(HcRatio(
        startTime: halfStr,
        endTime: last.endTime == halfStr ? _minutesToTime(lastEndMins) : last.endTime,
        ratioValue: last.ratioValue,
      ));
      // corrige el endTime del último al valor original
      hcRatios.last.endTime = _minutesToTime(lastEndMins);
    });
  }

  // ── Eliminar tramo HC ────────────────────────────────────────────────── //
  void _removeHcRatio(int index) {
    if (hcRatios.length <= 1) return;
    setState(() {
      hcRatios.removeAt(index);
      if (index == 0) {
        hcRatios[0].startTime = '00:00';
      } else if (index >= hcRatios.length) {
        hcRatios.last.endTime = '23:59';
      } else {
        final prev = hcRatios[index - 1];
        hcRatios[index].startTime = prev.endTime;
      }
    });
  }

  // ── Helpers tiempo ───────────────────────────────────────────────────── //
  int _timeToMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _minutesToTime(int mins) {
    final h = (mins ~/ 60).toString().padLeft(2, '0');
    final m = (mins % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Cerrar sesión ────────────────────────────────────────────────────── //
  Future<void> _cerrarSesion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cierre de Sesión'),
        content: const Text('¿Estás seguro de cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppColors.rojoSuave),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // TODO: llamar a AuthService.logout()
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  // ── Eliminar cuenta ──────────────────────────────────────────────────── //
  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
            'Esta acción es irreversible. Se eliminarán todos tus datos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.rojoSuave),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      // TODO: llamar a ProfileService.deleteUser() + AuthService.logout()
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
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
        title: const Text(
          'DiAppBetes',
          style: TextStyle(color: AppColors.blanco, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.blanco),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mi Perfil',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.azulFondo,
              ),
            ),
            const SizedBox(height: 12),

            // ── Tarjeta perfil ──────────────────────────────────────── //
            _buildProfileCard(),
            const SizedBox(height: 12),

            // ── Tarjeta info personal ───────────────────────────────── //
            _buildPersonalInfoCard(),
            const SizedBox(height: 12),

            // ── Tarjeta gestión diabetes ────────────────────────────── //
            _buildDiabetesCard(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Tarjeta perfil (avatar + nombre + email + rol + logout + eliminar)
  // =========================================================================
  Widget _buildProfileCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + info
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
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
                    Text(
                      profile.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.azulFondo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.grisTexto),
                    ),
                    const SizedBox(height: 6),
                    // Chip rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        border: Border.all(color: AppColors.azulFondo),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.role,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.azulFondo,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón cerrar sesión
          OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, color: AppColors.rojoSuave),
            label: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppColors.rojoSuave, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.rojoSuave),
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),

          // Eliminar cuenta
          Center(
            child: GestureDetector(
              onTap: _deleteUser,
              child: const Text(
                'Eliminar Cuenta',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.azulFondo,
                  fontWeight: FontWeight.w300,
                ),
              ),
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
          // Header con botón editar/guardar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
              IconButton(
                icon: Icon(
                  isEditingPersonalInfo ? Icons.check : Icons.edit,
                  color: isEditingPersonalInfo
                      ? Colors.green
                      : AppColors.azulFondo,
                ),
                onPressed: _toggleEditPersonalInfo,
              ),
            ],
          ),

          // Error
          if (errorPersonal.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(errorPersonal,
                  style: const TextStyle(
                      color: AppColors.rojoSuave, fontSize: 13)),
            ),

          _buildField(
            label: 'Nombre Usuario',
            controller: _usernameController,
            enabled: isEditingPersonalInfo,
            keyboardType: TextInputType.text,
          ),
          _buildField(
            label: 'Email',
            controller: _emailController,
            enabled: isEditingPersonalInfo,
            keyboardType: TextInputType.emailAddress,
          ),
          _buildField(
            label: 'Fecha de nacimiento',
            controller: _birthDateController,
            enabled: isEditingPersonalInfo,
            keyboardType: TextInputType.datetime,
          ),
          _buildField(
            label: 'Teléfono',
            controller: _phoneController,
            enabled: isEditingPersonalInfo,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Tarjeta gestión diabetes (FSI + ratios HC)
  // =========================================================================
  Widget _buildDiabetesCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gestión Diabetes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulFondo,
                ),
              ),
              IconButton(
                icon: Icon(
                  isEditingDiabetes ? Icons.check : Icons.edit,
                  color:
                      isEditingDiabetes ? Colors.green : AppColors.azulFondo,
                ),
                onPressed: _toggleEditDiabetes,
              ),
            ],
          ),

          // Error
          if (errorDiabetes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(errorDiabetes,
                  style: const TextStyle(
                      color: AppColors.rojoSuave, fontSize: 13)),
            ),

          // Campo FSI
          _buildField(
            label: 'FSI (mg/dl x Unidad)',
            controller: _fsiController,
            enabled: isEditingDiabetes,
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 16),

          // Sección Ratio HC
          const Text(
            'Ratio HC',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.azulFondo,
            ),
          ),
          const SizedBox(height: 10),

          // Lista de tramos HC
          ...hcRatios.asMap().entries.map((e) => _buildHcRatioRow(e.key, e.value)),

          // Botón añadir tramo
          if (isEditingDiabetes)
            Center(
              child: IconButton(
                icon: const Icon(Icons.add_circle,
                    size: 36, color: AppColors.azulFondo),
                onPressed: _addHcRatio,
              ),
            ),
        ],
      ),
    );
  }

  // ── Fila de un tramo HC ─────────────────────────────────────────────── //
  Widget _buildHcRatioRow(int index, HcRatio ratio) {
    final isFirst = index == 0;
    final isLast  = index == hcRatios.length - 1;
    final timeEditable = isEditingDiabetes && !isFirst && !isLast;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.blanco,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Hora inicio
          _timeChip(ratio.startTime, editable: timeEditable, onChanged: (v) {
            setState(() => ratio.startTime = v);
          }),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(' - ',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.grisTexto)),
          ),
          // Hora fin
          _timeChip(ratio.endTime, editable: timeEditable, onChanged: (v) {
            setState(() => ratio.endTime = v);
          }),
          const SizedBox(width: 8),

          // Valor ratio
          SizedBox(
            width: 58,
            child: TextFormField(
              initialValue: ratio.ratioValue.toString(),
              enabled: isEditingDiabetes,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.grisTexto),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                final val = double.tryParse(v);
                if (val != null) setState(() => ratio.ratioValue = val);
              },
            ),
          ),
          const Text('g/U',
              style: TextStyle(fontSize: 13, color: AppColors.grisTexto)),

          // Botón eliminar
          if (isEditingDiabetes && hcRatios.length > 1)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.remove_circle,
                  color: AppColors.azulFondo, size: 22),
              onPressed: () => _removeHcRatio(index),
            ),
        ],
      ),
    );
  }

  Widget _timeChip(String time,
      {bool editable = false, required ValueChanged<String> onChanged}) {
    if (!editable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(time,
            style: const TextStyle(fontSize: 13, color: AppColors.grisTexto)),
      );
    }
    return SizedBox(
      width: 60,
      child: TextFormField(
        initialValue: time,
        keyboardType: TextInputType.datetime,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: AppColors.grisTexto),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onChanged,
      ),
    );
  }

  // ── Campo de texto reutilizable ─────────────────────────────────────── //
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required TextInputType keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 15,
          color: enabled ? AppColors.grisTexto : AppColors.grisTexto.withOpacity(0.7),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.grisTexto, fontSize: 13),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.grisDivider),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.azulFondo),
          ),
          disabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.grisDivider),
          ),
        ),
      ),
    );
  }
}

// ── _Card reutilizable ───────────────────────────────────────────────────── //
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}