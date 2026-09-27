import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/game_repository.dart';
import '../core/widgets/usa_badge.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/deals/deals_screen.dart';
import '../features/library/library_screen.dart';
import '../features/search/search_screen.dart';
import '../features/store/dinoxo_store_screen.dart';

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
      AlertsScreen(repository: widget.repository),
      const DinoxoStoreScreen(),
    ];
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
