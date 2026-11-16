import 'dart:convert';
import 'dart:typed_data';
import 'package:diappbetes/widgets/custom_appbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/quick_glucose_modal.dart';
import '../widgets/setup_wizard.dart';
import '../widgets/skeleton.dart';
import '../widgets/tir_progress_ring.dart';
import '../services/profile_service.dart';
import '../services/glucose_service.dart';
import '../services/dose_service.dart';
import '../services/meal_service.dart';
import '../services/tir_service.dart';
import '../services/tip_service.dart';
import '../services/auth_service.dart';
import '../utils/admin_nav_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _profileService = ProfileService();
  final _glucoseService = GlucoseService();
  final _mealService    = MealService();
  final _tirService     = TirService();
  final _tipService     = TipService();
  final _authService    = AuthService();

  String _username        = '';
  int    _todayMealCount  = 0;
  TirStats _stats         = TirStats.empty;
  List<GlucoseReading> _readings = const [];
  String _tipContent      = '';
  Uint8List? _avatarBytes;

  bool _needsSetup  = false;
  bool _setupChecked = false;

  bool _isAdmin = false;
  int _selectedTab = 1;

  bool _loadingProfile  = true;
  bool _loadingGlucose  = true;
  bool _loadingMeals    = true;
  bool _loadingTir      = true;
  bool _loadingTip      = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _checkAdminRole();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadingProfile && !_loadingMeals) {
      _loadAll();
      _checkAdminRole();
    }
  }

  Future<void> _checkAdminRole() async {
    final isAdmin = await AdminNavHelper.getIsAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin);
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _loadingProfile = true;
      _loadingGlucose = true;
      _loadingMeals   = true;
      _loadingTir     = true;
      _loadingTip     = true;
    });

    _loadProfile();
    _loadGlucose();
    _loadMealCount();
    _loadTir();
    _loadTip();
    _checkSetup();
  }

  Future<void> _loadProfile() async {
    try {
      var profile = await _profileService.getMyProfile();
      if (profile == null) {
        await _profileService.ensureProfileExists();
        profile = await _profileService.getMyProfile();
      }

      final username = (profile?['username'] as String?)?.isNotEmpty == true
          ? profile!['username'] as String
          : (_authService.currentUser?.email?.split('@').first ?? '');

      Uint8List? avatarBytes;
      final avatarBase64 = profile?['avatar_base64'] as String?;
      if (avatarBase64 != null && avatarBase64.isNotEmpty) {
        try {
          avatarBytes = base64Decode(avatarBase64);
        } catch (_) {
          // Avatar corrupto: se muestra el icono por defecto.
        }
      }

      if (mounted) {
        setState(() {
          _username = username;
          _avatarBytes = avatarBytes;
          _loadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingProfile = false; });
    }
  }

  Future<void> _loadGlucose() async {
    try {
      final list = await _glucoseService.getLatestReadings(count: 2);
      if (mounted) setState(() { _readings = list; _loadingGlucose = false; });
    } catch (_) {
      if (mounted) setState(() { _readings = const []; _loadingGlucose = false; });
    }
  }

  Future<void> _loadMealCount() async {
    try {
      final count = await _mealService.getTodayMealCount();
      if (mounted) setState(() { _todayMealCount = count; _loadingMeals = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingMeals = false; });
    }
  }

  Future<void> _loadTir() async {
    try {
      final stats = await _tirService.getWeeklyStats();
      if (mounted) setState(() { _stats = stats; _loadingTir = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingTir = false; });
    }
  }

  Future<void> _loadTip() async {
    try {
      final tip = await _tipService.getRandomTip();
      if (mounted) setState(() { _tipContent = tip; _loadingTip = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingTip = false; });
    }
  }

  // ── Primer uso: configurar ratio y FSI ─────────────────────────────────── //

  Future<void> _checkSetup() async {
    final needs = await DoseService().needsSetup();
    if (!mounted) return;
    setState(() => _needsSetup = needs);

    if (!needs || _setupChecked) return;
    _setupChecked = true;

    // El asistente se ofrece solo la primera vez; luego queda el aviso en pantalla.
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'setup_prompted_$uid';
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
    } catch (_) {
      return;
    }
    if (mounted) _openSetup();
  }

  Future<void> _openSetup() async {
    final done = await SetupWizard.show(context);
    if (!mounted) return;
    if (done) {
      AppToast.success(context, 'Configuración guardada. Ya puedes calcular tu insulina');
      setState(() => _needsSetup = false);
    }
  }

  Future<void> _registerGlucose() async {
    final saved = await QuickGlucoseModal.show(context);
    if (!mounted || !saved) return;
    AppToast.success(context, 'Glucemia registrada');
    setState(() { _loadingGlucose = true; _loadingTir = true; });
    _loadGlucose();
    _loadTir();
  }

  // ── Utilidades de presentación ─────────────────────────────────────────── //

  String _relativeTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'ahora mismo';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    return 'hace ${d.inDays} ${d.inDays == 1 ? 'día' : 'días'}';
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
          case 2: Navigator.pushReplacementNamed(context, '/add-meal'); break;
        }
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────── //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'DiAppBetes',
        onSettingsPressed: () async {
          await Navigator.pushNamed(context, '/settings');
          _loadProfile();
          _checkAdminRole();
          _checkSetup();
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: () async {
            await _loadAll();
            await _checkAdminRole();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ringSize = (constraints.maxWidth * 0.34).clamp(100.0, 150.0);

              // Altura natural (sin Expanded/IntrinsicHeight): con textos grandes
              // el contenido simplemente hace scroll en vez de desbordarse.
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileCard(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Theme.of(context).dividerColor, thickness: 2),
                    ),
                    if (_needsSetup) ...[
                      _buildSetupBanner(),
                      const SizedBox(height: 12),
                    ],
                    _buildTirCard(ringSize),
                    const SizedBox(height: 12),
                    _buildLastReadingCard(),
                    const SizedBox(height: 12),
                    _buildMealsCard(),
                    const SizedBox(height: 12),
                    _buildTipCard(),
                  ],
                ),
              );
            },
          ),
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

  Widget _buildSetupBanner() {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.ambarSuave.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.ambarSuave.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune, color: AppColors.ambarSuave, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Configura tu insulina',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primary)),
                  const SizedBox(height: 2),
                  Text('Falta tu ratio de hidratos y FSI para calcular la dosis.',
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _openSetup,
              child: Text('Configurar',
                  style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          label: 'Foto de perfil',
          image: true,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primary, width: 3),
              image: _avatarBytes != null
                  ? DecorationImage(image: MemoryImage(_avatarBytes!), fit: BoxFit.cover)
                  : null,
            ),
            child: _avatarBytes == null
                ? Icon(Icons.person, size: 26, color: primary)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: _loadingProfile
              ? const SkeletonBox(width: 140, height: 24, radius: 8)
              : Text(
                  _username.isNotEmpty ? _username : '—',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        ),
      ],
    );
  }

  Widget _buildTirCard(double ringSize) {
    final primary = Theme.of(context).colorScheme.primary;
    final textSmall = Theme.of(context).textTheme.bodySmall?.color;

    return _Card(
      child: Column(
        children: [
          Text('Tiempo en Rango',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
              textAlign: TextAlign.center),
          Text('Últimos 7 días', style: TextStyle(fontSize: 13, color: textSmall)),
          const SizedBox(height: 16),
          if (_loadingTir) ...[
            SkeletonBox(width: ringSize, height: ringSize, radius: ringSize / 2),
            const SizedBox(height: 16),
            const SkeletonBox(height: 40, radius: 12),
          ] else if (_stats.count == 0) ...[
            Icon(Icons.show_chart, size: 44, color: Theme.of(context).dividerColor),
            const SizedBox(height: 8),
            Text('Aún no hay lecturas esta semana',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 4),
            Text('Registra una glucemia para ver aquí tu tiempo en rango.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textSmall)),
          ] else ...[
            TirProgressRing(percentage: _stats.inRangePct, size: ringSize),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _miniStat('Bajas', '${_stats.lowPct}%', AppColors.rojoSuave)),
                Expanded(child: _miniStat('Altas', '${_stats.highPct}%', AppColors.ambarSuave)),
                Expanded(child: _miniStat('Media', '${_stats.average.round()} mg/dL', primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  Widget _buildLastReadingCard() {
    final primary = Theme.of(context).colorScheme.primary;
    final textSmall = Theme.of(context).textTheme.bodySmall?.color;

    Widget body;
    if (_loadingGlucose) {
      body = const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 150, height: 40, radius: 10),
          SizedBox(height: 8),
          SkeletonBox(width: 110, height: 14),
        ],
      );
    } else if (_readings.isEmpty) {
      body = Text('Todavía no has registrado ninguna glucemia.',
          style: TextStyle(fontSize: 14, color: textSmall));
    } else {
      final last = _readings.first;
      final isLow = last.level < DoseService.hypoThreshold;
      final valueColor = isLow ? AppColors.rojoSuave : primary;

      IconData? trendIcon;
      String trendText = '';
      if (_readings.length > 1) {
        final delta = last.level - _readings[1].level;
        if (delta.abs() < 10) {
          trendIcon = Icons.trending_flat;
          trendText = 'Estable';
        } else if (delta > 0) {
          trendIcon = Icons.trending_up;
          trendText = 'Subiendo (+${delta.round()})';
        } else {
          trendIcon = Icons.trending_down;
          trendText = 'Bajando (${delta.round()})';
        }
      }

      body = Semantics(
        container: true,
        label: 'Última glucemia ${last.level.round()} miligramos por decilitro, '
            '${_relativeTime(last.time)}'
            '${trendText.isEmpty ? '' : ', $trendText'}'
            '${isLow ? '. Glucemia baja' : ''}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${last.level.round()}',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: valueColor, height: 1)),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('mg/dL', style: TextStyle(fontSize: 15, color: textSmall)),
                  ),
                  const Spacer(),
                  if (trendIcon != null)
                    Column(
                      children: [
                        Icon(trendIcon, size: 30, color: valueColor),
                        Text(trendText, style: TextStyle(fontSize: 12, color: textSmall)),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(_relativeTime(last.time), style: TextStyle(fontSize: 13, color: textSmall)),
              if (isLow) ...[
                const SizedBox(height: 6),
                const Text('Glucemia baja: trátala antes de ponerte insulina.',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.rojoSuave)),
              ],
            ],
          ),
        ),
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.water_drop_outlined, size: 20, color: primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text('Última Lectura',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primary),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 10),
          body,
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _registerGlucose,
              icon: Icon(Icons.add, color: primary),
              label: Text('Registrar glucemia',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.restaurant_outlined, size: 20, color: primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text('Comidas de hoy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 6),
          _loadingMeals
              ? const SkeletonBox(width: 50, height: 34, radius: 8)
              : Semantics(
                  label: '$_todayMealCount comidas hoy',
                  child: ExcludeSemantics(
                    child: Text('$_todayMealCount',
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    final primary = Theme.of(context).colorScheme.primary;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_outline, size: 20, color: primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text('Consejo de salud',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primary),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 8),
          _loadingTip
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 13),
                    SizedBox(height: 6),
                    SkeletonBox(width: 180, height: 13),
                  ],
                )
              : Text(
                  _tipContent.isNotEmpty ? _tipContent : 'Hoy no hay consejo disponible.',
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      height: 1.4),
                ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.3)
              : const Color(0x1A000000),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}
