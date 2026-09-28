import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/user_alert.dart';
import '../../../domain/models/game.dart';
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
  Map<String, Game> _games = {};
  int _loadGeneration = 0;

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
    widget.repository.addListener(_loadAlerts);
    _loadAlerts();
  }

  @override
  void dispose() {
    widget.repository.removeListener(_loadAlerts);
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    final generation = ++_loadGeneration;
    final alerts = await widget.repository.getAlerts();
    final games = <String, Game>{};
    for (final id in alerts.map((a) => a.gameId).toSet()) {
      try {
        final game = await widget.repository.getGameById(id);
        if (game != null) games[id] = game;
      } catch (_) {
        // A missing/unreadable snapshot must not hide the saved price alert.
      }
    }
    if (mounted && generation == _loadGeneration) {
      setState(() {
        _alerts = alerts;
        _games = games;
        _isLoading = false;
      });
    }
  }

  void _openGame(UserAlert alert) {
    final game = _games[alert.gameId];
    if (game == null || game.platform != alert.platform) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Busca de nuevo el juego para recuperar su ficha. La alerta sigue guardada.')));
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (_) => GameDetailsScreen(
                game: game,
                repository: widget.repository,
                selectedEditionId: alert.editionId)));
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
              tooltip: 'Consultar precios ahora',
              onPressed: _checking ? null : _checkPrices,
              icon: const Icon(Icons.refresh)),
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
                        'Alertas de precio activas',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Android revisa los juegos con conexión aproximadamente cada 15 minutos, incluso en segundo plano. El sistema puede retrasar la revisión. Pulsa actualizar para consultar ahora. Los avisos necesitan permiso y respetan el silencio de 22:00 a 08:00.',
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: AppTheme.platformColor(
                                        alert.platform))),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            child: InkWell(
                                onTap: () => _openGame(alert),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          SizedBox(
                                              width: 52,
                                              height: 72,
                                              child: (_games[alert.gameId]
                                                          ?.coverUrl
                                                          .isNotEmpty ??
                                                      false)
                                                  ? Image.network(
                                                      _games[alert.gameId]!
                                                          .coverUrl,
                                                      fit: BoxFit.cover,
                                                      cacheWidth: 156,
                                                      errorBuilder: (_, __,
                                                              ___) =>
                                                          const Icon(Icons
                                                              .sports_esports))
                                                  : const Icon(
                                                      Icons.sports_esports)),
                                          const SizedBox(width: 10),
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
                                            activeThumbColor:
                                                AppTheme.platformColor(
                                                    alert.platform),
                                            onChanged: (_) =>
                                                _toggleAlert(alert),
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
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 6,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.hotDeal
                                                    .withAlpha(25),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Mínimo histórico: pendiente de datos',
                                                style: TextStyle(
                                                    color: AppTheme.hotDeal,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                          if (alert.alertOnPromoEnding)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppTheme.warning
                                                    .withAlpha(25),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Fin de oferta: pendiente de fecha exacta',
                                                style: TextStyle(
                                                    color: AppTheme.warning,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _openGame(alert),
                                            icon: const Icon(
                                                Icons.visibility_outlined,
                                                size: 16),
                                            label: const Text('Ver Juego',
                                                style: TextStyle(fontSize: 12)),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppTheme.danger,
                                                size: 20),
                                            onPressed: () =>
                                                _deleteAlert(alert),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
