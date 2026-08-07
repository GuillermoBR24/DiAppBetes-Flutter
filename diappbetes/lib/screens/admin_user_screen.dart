import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// AdminUsersScreen — Gestión completa de usuarios
// ---------------------------------------------------------------------------
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _users    = [];
  List<Map<String, dynamic>> _filtered = [];
  bool   _loading     = true;
  String _searchTerm  = '';
  String _filterRole  = 'todos';

  final _searchCtrl = TextEditingController();

  static const _roles = ['todos', 'usuario', 'administrador'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Cargar todos los perfiles ─────────────────────────────────────────── //
  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final snap = await _db
          .collection('profiles')
          .orderBy('created_at', descending: true)
          .get();
      final users = snap.docs.map((d) => {'_docId': d.id, ...d.data()}).toList();
      setState(() { _users = users; _loading = false; });
      _applyFilters();
    } catch (e) {
      setState(() => _loading = false);
      _snack('Error al cargar usuarios: $e', isError: true);
    }
  }

  void _applyFilters() {
    var list = List<Map<String, dynamic>>.from(_users);
    if (_searchTerm.isNotEmpty) {
      final t = _searchTerm.toLowerCase();
      list = list.where((u) =>
          (u['username']?.toString().toLowerCase().contains(t) ?? false) ||
          (u['email']?.toString().toLowerCase().contains(t) ?? false)).toList();
    }
    if (_filterRole != 'todos') {
      list = list.where((u) =>
          (u['role']?.toString().toLowerCase() ?? '') == _filterRole).toList();
    }
    setState(() => _filtered = list);
  }

  // ── Editar usuario ────────────────────────────────────────────────────── //
  Future<void> _editUser(Map<String, dynamic> user) async {
    final docId = user['_docId'] as String;
    final usernameCtrl = TextEditingController(text: user['username']?.toString() ?? '');
    String selectedRole = (user['role']?.toString().toLowerCase() == 'administrador')
        ? 'administrador' : 'usuario';

    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Theme.of(ctx).cardColor,
          title: Text('Editar Usuario',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email (solo lectura)
              Text('Email:', style: TextStyle(color: textSmallColor, fontSize: 12)),
              const SizedBox(height: 2),
              Text(user['email']?.toString() ?? '—',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),

              // Username editable
              TextField(
                controller: usernameCtrl,
                style: TextStyle(color: Theme.of(ctx).textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  labelStyle: TextStyle(color: textSmallColor, fontSize: 13),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: dividerColor)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                ),
              ),
              const SizedBox(height: 16),

              // Rol
              Text('Rol:', style: TextStyle(color: textSmallColor, fontSize: 12)),
              const SizedBox(height: 8),
              Row(children: [
                _roleChipDialog('Usuario', 'usuario', selectedRole,
                    (v) => setS(() => selectedRole = v), ctx),
                const SizedBox(width: 10),
                _roleChipDialog('Admin', 'administrador', selectedRole,
                    (v) => setS(() => selectedRole = v), ctx),
              ]),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancelar', style: TextStyle(color: textSmallColor))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Guardar', style: TextStyle(color: onPrimaryColor)),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await _db.collection('profiles').doc(docId).update({
        'username': usernameCtrl.text.trim(),
        'role':     selectedRole == 'administrador' ? 'administrador' : 'Usuario',
        'updated_at': FieldValue.serverTimestamp(),
      });
      _snack('Usuario actualizado');
      _loadUsers();
    } catch (e) {
      _snack('Error al actualizar: $e', isError: true);
    }
    usernameCtrl.dispose();
  }
  // ── Helpers ───────────────────────────────────────────────────────────── //
  Widget _roleChipDialog(String label, String value, String current,
      Function(String) onSelect, BuildContext ctx) {
    final sel = current == value;
    final primaryColor = Theme.of(ctx).colorScheme.primary;
    final onPrimaryColor = Theme.of(ctx).colorScheme.onPrimary;
    final textSmallColor = Theme.of(ctx).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(ctx).dividerColor;

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? primaryColor : Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? primaryColor : dividerColor),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? onPrimaryColor : textSmallColor,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.rojoSuave : AppColors.verdesuave,
    ));
  }

  Color _roleColor(String? role, Color primaryColor) {
    if (role?.toLowerCase() == 'administrador' || role?.toLowerCase() == 'admin') {
      return AppColors.ambarSuave;
    }
    return primaryColor;
  }

  Color _roleBg(String? role, Color primaryColor) {
    if (role?.toLowerCase() == 'administrador' || role?.toLowerCase() == 'admin') {
      return AppColors.ambarSuave.withValues(alpha: 0.15);
    }
    return primaryColor.withValues(alpha: 0.1);
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return '—';
    try {
      final dt = (ts as Timestamp).toDate();
      return '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
    } catch (_) { return '—'; }
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.grisTexto;
    final textSmallColor = Theme.of(context).textTheme.bodySmall?.color;
    final dividerColor = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Gestión de Usuarios',
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor, 
              fontWeight: FontWeight.bold, 
              fontSize: 18,
            )),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador + filtro ──────────────────────────────────────── //
          Container(
            color: cardBg,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [
              // Buscador
              TextField(
                controller: _searchCtrl,
                style: TextStyle(color: textColor, fontSize: 14),
                onChanged: (v) { setState(() => _searchTerm = v); _applyFilters(); },
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email...',
                  hintStyle: TextStyle(color: textSmallColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: primaryColor, size: 20),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(icon: Icon(Icons.clear, size: 18, color: textSmallColor),
                          onPressed: () { _searchCtrl.clear(); setState(() => _searchTerm = ''); _applyFilters(); })
                      : null,
                  filled: true,
                  fillColor: bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 10),

              // Filtros de rol
              Row(children: [
                Text('Rol:', style: TextStyle(color: textSmallColor, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                ..._roles.map((r) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () { setState(() => _filterRole = r); _applyFilters(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: _filterRole == r ? primaryColor : bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _filterRole == r ? primaryColor : dividerColor),
                      ),
                      child: Text(r[0].toUpperCase() + r.substring(1),
                          style: TextStyle(
                              fontSize: 11,
                              color: _filterRole == r ? onPrimaryColor : textSmallColor,
                              fontWeight: _filterRole == r ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                )),
                const Spacer(),
                Text('${_filtered.length} usuarios',
                    style: TextStyle(fontSize: 11, color: textSmallColor)),
              ]),
            ]),
          ),

          // ── Lista de usuarios ─────────────────────────────────────── //
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _filtered.isEmpty
                    ? Center(child: Text('Sin resultados', style: TextStyle(color: textSmallColor)))
                    : RefreshIndicator(
                        color: primaryColor,
                        onRefresh: _loadUsers,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildUserCard(_filtered[i], cardBg, textColor, primaryColor, onPrimaryColor, textSmallColor, dividerColor),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, Color cardBg, Color txtColor, Color primaryColor, Color onPrimaryColor, Color? textSmallColor, Color dividerColor) {
    final role = user['role']?.toString() ?? 'usuario';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0x0F000000),
            blurRadius: 8, 
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _roleBg(role, primaryColor),
              shape: BoxShape.circle,
            ),
            child: Icon(
              role.toLowerCase() == 'administrador' ? Icons.admin_panel_settings : Icons.person,
              color: _roleColor(role, primaryColor), size: 24,
            ),
          ),
          const SizedBox(width: 12),

          // Datos básicos
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user['username']?.toString() ?? '—',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
            Text(user['email']?.toString() ?? '—',
                style: TextStyle(fontSize: 12, color: textSmallColor),
                overflow: TextOverflow.ellipsis),
          ])),

          // Badge de rol
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleBg(role, primaryColor),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _roleColor(role, primaryColor).withValues(alpha: 0.4)),
            ),
            child: Text(role[0].toUpperCase() + role.substring(1),
                style: TextStyle(fontSize: 10, color: _roleColor(role, primaryColor), fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 10),
        Divider(height: 1, color: dividerColor),
        const SizedBox(height: 10),

        // Datos secundarios
        Row(children: [
          _infoItem(Icons.cake_outlined, 'Nac.', user['birth_date']?.toString() ?? '—', primaryColor, textSmallColor),
          const SizedBox(width: 16),
          _infoItem(Icons.science_outlined, 'FSI', '${user['fsi'] ?? '—'} mg/dL/U', primaryColor, textSmallColor),
          const SizedBox(width: 16),
          _infoItem(Icons.calendar_today_outlined, 'Registro', _formatDate(user['created_at']), primaryColor, textSmallColor),
        ]),
        const SizedBox(height: 12),

        // Acciones
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(
            onPressed: () => _editUser(user),
            icon: Icon(Icons.edit, size: 16, color: primaryColor),
            label: Text('Editar', style: TextStyle(color: primaryColor, fontSize: 13)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          ),
        ]),
      ]),
    );
  }

  Widget _infoItem(IconData icon, String label, String value, Color primaryColor, Color? textSmallColor) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: textSmallColor),
      const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 9, color: textSmallColor)),
        Text(value, style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w500)),
      ]),
    ],
  );
}