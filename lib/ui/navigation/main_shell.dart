import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/game_repository.dart';
import '../../domain/models/release_alert.dart';
import '../../domain/models/preorder_game.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/subscription_service.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/deals/deals_screen.dart';
import '../features/more/more_screen.dart';
import '../features/preorders/preorders_screen.dart';
import '../features/search/search_screen.dart';
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
  // Search stays mounted to recover a photo after Android recreates the activity.
  final Set<int> _visited = {0, 1};
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DealsScreen(repository: widget.repository),
      SearchScreen(
          repository: widget.repository,
          onRecoveredPhoto: () {
            if (mounted) {
              setState(() {
                _visited.add(1);
                _currentIndex = 1;
              });
            }
          }),
      PlusScreen(autoLoad: false, repository: widget.repository),
      PreordersScreen(
          repository: widget.repository,
          onCreateReleaseAlert: _createReleaseAlert),
      AlertsScreen(repository: widget.repository),
      MoreScreen(repository: widget.repository),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRunPermissions();
    });
  }

  Future<void> _createReleaseAlert(PreorderGame game) async {
    final date = game.releaseDate;
    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Este anuncio aún no tiene una fecha confirmada.')));
      return;
    }
    try {
      final existing = await widget.repository.getReleaseAlerts();
      final duplicate = existing.any((alert) =>
          alert.platform == game.platform &&
          alert.gameTitle == game.title &&
          alert.releaseDate.year == date.year &&
          alert.releaseDate.month == date.month &&
          alert.releaseDate.day == date.day);
      if (duplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Este lanzamiento ya está en Mis Alertas.')));
        }
        return;
      }
      final permission = await NotificationService.instance.requestPermission();
      final scheduled = await widget.repository.saveReleaseAlert(ReleaseAlert(
          id: const Uuid().v4(),
          gameTitle: game.title,
          platform: game.platform,
          coverUrl: game.coverUrl,
          sourceUrl: game.sourceUri.toString(),
          releaseDate: date,
          createdAt: DateTime.now()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(!permission
              ? 'Aviso guardado en Mis Alertas. Activa las notificaciones de Android para recibirlo.'
              : scheduled
                  ? 'Aviso programado para los plazos pendientes de este lanzamiento.'
                  : 'Aviso guardado, pero Android no permitió programarlo.')));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No se pudo guardar este aviso. Reintenta.')));
      }
    }
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
            Icon(Icons.security_outlined,
                color: AppTheme.primaryLight, size: 24),
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
                          'Te avisará cuando una comprobación detecte que el juego alcanzó tu precio objetivo. Android puede retrasar las revisiones en segundo plano.',
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
                          'Se utiliza para reconocer el título de un videojuego en una foto y consultar su ficha USA.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          for (var i = 0; i < _screens.length; i++)
            _visited.contains(i) ? _screens[i] : const SizedBox.shrink()
        ],
      ),
      bottomNavigationBar: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: AppTheme.secondary.withAlpha(70)),
            boxShadow: [
              BoxShadow(color: AppTheme.secondary.withAlpha(22), blurRadius: 20)
            ],
          ),
          child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (index) {
                  setState(() {
                    _visited.add(index);
                    _currentIndex = index;
                  });
                  if (index == 2) SubscriptionService.instance.ensureLoaded();
                },
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
                    icon: Icon(Icons.event_outlined),
                    activeIcon: Icon(Icons.event),
                    label: 'Preventas',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications_none),
                    activeIcon: Icon(Icons.notifications),
                    label: 'Mis Alertas',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.more_horiz_rounded),
                    activeIcon: Icon(Icons.more_horiz_rounded),
                    label: 'Más',
                  ),
                ],
              ))),
    );
  }
}
