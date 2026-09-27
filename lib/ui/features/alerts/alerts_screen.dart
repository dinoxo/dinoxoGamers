import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/user_alert.dart';
import '../../../domain/services/notification_service.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/platform_badge.dart';
import '../game_details/game_details_screen.dart';

class AlertsScreen extends StatefulWidget {
  final GameRepository repository;

  const AlertsScreen({
    super.key,
    required this.repository,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<UserAlert> _alerts = [];
  bool _isLoading = true;
  bool _checking = false;

  Future<void> _checkPrices() async {
    setState(() => _checking = true);
    try {
      final errors = await widget.repository.refreshAlertPrices();
      await _loadAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errors.isEmpty
                ? 'Precios consultados. Se avisará si alcanzan tu objetivo y tienes notificaciones habilitadas.'
                : errors.join('\n'))));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final alerts = await widget.repository.getAlerts();
    if (mounted) {
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAlert(UserAlert alert) async {
    final newState = !alert.isActive;
    await widget.repository.toggleAlertActive(alert.id, newState);
    _loadAlerts();
  }

  Future<void> _deleteAlert(UserAlert alert) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        title: const Text('Eliminar Alerta',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '¿Deseas eliminar la alerta para ${alert.gameTitle}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          IconButton(
              tooltip: 'Consultar precios ahora',
              onPressed: _checking ? null : _checkPrices,
              icon: const Icon(Icons.refresh)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.repository.deleteAlert(alert.id);
      _loadAlerts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta eliminada')),
        );
      }
    }
  }

  Future<void> _testNotificationPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Permiso de notificaciones concedido con éxito.'
                : 'Permiso denegado o no disponible en este dispositivo.',
          ),
          backgroundColor: granted ? AppTheme.success : AppTheme.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Alertas de Precios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Configurar permisos de notificación',
            onPressed: _testNotificationPermission,
          ),
        ],
      ),
      body: Column(
        children: [
          // Push Server & Quiet Hours Information Box
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    size: 18, color: AppTheme.secondary),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consulta de alertas desde la app',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Pulsa actualizar para consultar tus juegos. También se revisa el precio al abrir una ficha o cargar ofertas. La app cerrada no comprueba precios. Las notificaciones requieren permiso y respetan el silencio de 22:00 a 08:00.',
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alerts List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alerts.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.notifications_off_outlined,
                        title: 'No tienes alertas activas',
                        message:
                            'Entra a la ficha de un juego y toca "Crear Alerta" para guardar tu precio objetivo.',
                      )
                    : ListView.builder(
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final alert = _alerts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      PlatformBadge(
                                          platform: alert.platform,
                                          compact: true),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          alert.gameTitle,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: alert.isActive,
                                        activeThumbColor: AppTheme.primary,
                                        onChanged: (_) => _toggleAlert(alert),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Edición: ${alert.editionName}',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Objetivo: ',
                                            style: TextStyle(
                                                color: AppTheme.textMuted,
                                                fontSize: 12),
                                          ),
                                          Text(
                                            '<= ${CurrencyFormatter.formatUsd(alert.targetPrice)}',
                                            style: const TextStyle(
                                              color: AppTheme.success,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'Creada: ${DateFormatter.formatShortDate(alert.createdAt)}',
                                        style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      if (alert.alertOnAllTimeLow)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                AppTheme.hotDeal.withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Mínimo histórico: pendiente de datos',
                                            style: TextStyle(
                                                color: AppTheme.hotDeal,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      if (alert.alertOnPromoEnding)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                AppTheme.warning.withAlpha(25),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Fin de oferta: pendiente de fecha exacta',
                                            style: TextStyle(
                                                color: AppTheme.warning,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () async {
                                          final game = await widget.repository
                                              .getGameById(alert.gameId);
                                          if (game != null && context.mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    GameDetailsScreen(
                                                  game: game,
                                                  repository: widget.repository,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 16),
                                        label: const Text('Ver Juego',
                                            style: TextStyle(fontSize: 12)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: AppTheme.danger, size: 20),
                                        onPressed: () => _deleteAlert(alert),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
