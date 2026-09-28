import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/services/notification_service.dart';
import '../core/widgets/usa_badge.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/deals/deals_screen.dart';
import '../features/library/library_screen.dart';
import '../features/search/search_screen.dart';
import '../features/store/dinoxo_store_screen.dart';
import '../features/subscriptions/plus_screen.dart';

class MainShell extends StatefulWidget {
  final GameRepository repository;

  const MainShell({
    super.key,
    required this.repository,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DealsScreen(repository: widget.repository),
      SearchScreen(repository: widget.repository),
      const PlusScreen(),
      AlertsScreen(repository: widget.repository),
      const DinoxoStoreScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRunPermissions();
    });
  }

  Future<void> _checkFirstRunPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenNotice =
          prefs.getBool('has_seen_permissions_notice') ?? false;
      if (!hasSeenNotice && mounted) {
        _showPermissionsNoticeDialog(prefs);
      }
    } catch (_) {}
  }

  void _showPermissionsNoticeDialog(SharedPreferences prefs) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.security_outlined, color: AppTheme.primaryLight, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Permisos en Dinoxo Gamers',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para brindarte la mejor experiencia al seguir ofertas y precios en tiempo real, la app puede requerir los siguientes permisos:',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // Permiso 1: Notificaciones
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notifications_active_outlined,
                      color: AppTheme.primaryLight, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificaciones (Recomendado)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Te avisará en tiempo real cuando un juego que sigas en Mis Alertas baje de precio o alcance tu valor deseado.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Permiso 2: Cámara
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: AppTheme.secondary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cámara y Fotos (Opcional)',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Se utiliza para escanear etiquetas de precios físicos mediante OCR y comprobar si conviene comprar en digital.',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool('has_seen_permissions_notice', true);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Más tarde',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await prefs.setBool('has_seen_permissions_notice', true);
              if (ctx.mounted) Navigator.pop(ctx);
              await NotificationService.instance.requestPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Activar y Continuar'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sports_esports, color: AppTheme.primaryLight),
            SizedBox(width: 8),
            Text(
              'Dinoxo Gamers',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Versión 1.0.0 · Edición Gratuita Universal',
              style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aplicación diseñada para la comunidad gamer. Permite consultar ofertas verificadas en PlayStation, Nintendo y Xbox para la región comercial de Estados Unidos (USD), analizar históricos y estimaciones, y adquirir saldo oficial en Dinoxo Store.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.35),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.success, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'App 100% libre de licencias, pruebas y pagos por desbloqueo.',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: AppTheme.surfaceElevated,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.background,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.sports_esports, color: AppTheme.primaryLight, size: 30),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    AppConstants.appName,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'PlayStation · Nintendo · Xbox (USA)',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: AppTheme.secondary),
              title: const Text('Mi Biblioteca de Juegos', style: TextStyle(color: AppTheme.textPrimary)),
              subtitle: const Text('Juegos que ya posees y comparador de ediciones', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LibraryScreen(repository: widget.repository),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primaryLight),
              title: const Text('Acerca de Dinoxo Gamers', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _showInfoDialog();
              },
            ),
            const Divider(color: AppTheme.border),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: UsaBadge(),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer_outlined),
            activeIcon: Icon(Icons.local_offer),
            label: 'Ofertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_membership_outlined),
            activeIcon: Icon(Icons.card_membership_rounded),
            label: 'Plus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            activeIcon: Icon(Icons.notifications),
            label: 'Mis Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Dinoxo Store',
          ),
        ],
      ),
    );
  }
}
