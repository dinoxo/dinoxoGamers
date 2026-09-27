import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/repositories/game_repository.dart';
import '../../../domain/models/game.dart';
import '../../../domain/models/game_edition.dart';
import '../../../domain/models/price_observation.dart';
import '../../../domain/models/sale_estimation.dart';
import '../../../domain/models/user_alert.dart';
import '../../../domain/services/price_estimator_service.dart';
import '../../../domain/services/whatsapp_service.dart';
import '../../core/widgets/platform_badge.dart';
import '../../core/widgets/price_tag.dart';
import '../../core/widgets/usa_badge.dart';
import 'widgets/live_review_section.dart';
import 'widgets/price_history_chart.dart';
import 'widgets/sale_estimation_card.dart';

class GameDetailsScreen extends StatefulWidget {
  final Game game;
  final GameRepository repository;

  const GameDetailsScreen({
    super.key,
    required this.game,
    required this.repository,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  late Game _game;
  bool _refreshing = false;
  String? _refreshError;
  late GameEdition _selectedEdition;
  bool _isFavorite = false;
  bool _isOwned = false;
  List<PriceObservation> _observations = [];
  SaleEstimation _estimation = SaleEstimation.insufficient();
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _game = widget.game;
    if (_game.primaryEdition != null) _selectedEdition = _game.primaryEdition!;
    _loadData();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshError = null;
    });
    try {
      final current = await widget.repository.refreshGame(_game);
      if (!mounted) return;
      setState(() {
        _game = current;
        if (current.primaryEdition != null) {
          _selectedEdition = current.primaryEdition!;
        }
      });
      await _loadData();
    } catch (_) {
      if (mounted) {
        setState(() => _refreshError =
            'No se pudo actualizar. Se muestra la última consulta guardada.');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _loadData() async {
    final fav = await widget.repository.isFavorite(_game.id);
    final owned = await widget.repository.isGameOwned(_game.id);
    final obs = _game.primaryEdition == null
        ? <PriceObservation>[]
        : await widget.repository.getPriceHistory(
            _selectedEdition.id,
            _selectedEdition.regularPrice,
          );
    final est = PriceEstimatorService.estimateNextSale(
      observations: obs,
      regularPrice: _game.primaryEdition?.regularPrice ?? 0,
    );

    if (mounted) {
      setState(() {
        _isFavorite = fav;
        _isOwned = owned;
        _observations = obs;
        _estimation = est;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await widget.repository.toggleFavorite(_game.id);
    final fav = await widget.repository.isFavorite(_game.id);
    if (mounted) {
      setState(() => _isFavorite = fav);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fav ? 'Añadido a tus favoritos' : 'Eliminado de favoritos',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: fav ? AppTheme.primary : AppTheme.surfaceElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleOwned() async {
    await widget.repository.toggleGameOwned(_game);
    final owned = await widget.repository.isGameOwned(_game.id);
    if (mounted) {
      setState(() => _isOwned = owned);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            owned ? 'Añadido a tu biblioteca' : 'Eliminado de tu biblioteca',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCreateAlertDialog() {
    double targetPrice =
        (_selectedEdition.currentPrice * 0.85 * 100).round() / 100;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Crear Alerta de Precio',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.close, color: AppTheme.textMuted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_game.title} · ${_selectedEdition.name}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Avisarme si baja a:',
                        style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        CurrencyFormatter.formatUsd(targetPrice),
                        style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: targetPrice.clamp(
                        0.0,
                        _selectedEdition.currentPrice > 0
                            ? _selectedEdition.currentPrice
                            : 1.0),
                    min: 0.0,
                    max: _selectedEdition.currentPrice > 0
                        ? _selectedEdition.currentPrice
                        : 1.0,
                    divisions: 20,
                    activeColor: AppTheme.primary,
                    inactiveColor: AppTheme.border,
                    onChanged: (val) {
                      setModalState(
                          () => targetPrice = (val * 100).round() / 100);
                    },
                  ),
                  const Text(
                      'Se comprobará al consultar precios en la app. No hay monitoreo con la aplicación cerrada.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final alert = UserAlert(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        gameId: _game.id,
                        editionId: _selectedEdition.id,
                        gameTitle: _game.title,
                        platform: _game.platform,
                        editionName: _selectedEdition.name,
                        targetPrice: targetPrice,
                        alertOnAllTimeLow: false,
                        alertOnPromoEnding: false,
                        createdAt: DateTime.now(),
                      );
                      await widget.repository.saveAlert(alert);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Alerta guardada exitosamente'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      }
                    },
                    child: const Text('Guardar Alerta'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_game.primaryEdition == null) {
      return Scaffold(
          appBar: AppBar(title: Text(_game.title), actions: [
            IconButton(
                onPressed: _refreshing ? null : _refresh,
                icon: const Icon(Icons.refresh)),
          ]),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            if (_refreshing) const LinearProgressIndicator(),
            if (_refreshError != null) Text(_refreshError!),
            PlatformBadge(platform: _game.platform),
            const SizedBox(height: 16),
            const Text(
                'Este juego figura en el catálogo, pero no hay un precio digital de Estados Unidos disponible en la fuente consultada.'),
            const SizedBox(height: 16),
            LiveReviewSection(game: _game),
            TextButton(
                onPressed: () => WhatsAppService.launchExternalUrl(
                    AppConstants.officialStoreUrlForGame(
                        _game.platform, _game.title)),
                child: const Text('Consultar tienda USA')),
          ]));
    }
    final promoEnd = _selectedEdition.promoEndDate;

    return Scaffold(
      appBar: AppBar(
        title: Text(_game.title),
        actions: [
          IconButton(
              tooltip: 'Actualizar precio y reseñas',
              onPressed: _refreshing ? null : _refresh,
              icon: const Icon(Icons.refresh)),
          IconButton(
            icon: Icon(
              _isOwned ? Icons.inventory_2 : Icons.inventory_2_outlined,
              color: _isOwned ? AppTheme.secondary : AppTheme.textMuted,
            ),
            tooltip: _isOwned ? 'En mi biblioteca' : 'Añadir a mi biblioteca',
            onPressed: _toggleOwned,
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? AppTheme.danger : AppTheme.textMuted,
            ),
            tooltip: _isFavorite ? 'En favoritos' : 'Añadir a favoritos',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_refreshing) const LinearProgressIndicator(),
            if (_refreshError != null)
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_refreshError!)),
            // Header: Box Art & Core Metadata
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surface,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 110,
                      height: 150,
                      color: AppTheme.surfaceElevated,
                      child: Image.network(
                        _game.coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.sports_esports,
                              size: 40, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            PlatformBadge(platform: _game.platform),
                            const SizedBox(width: 6),
                            const UsaBadge(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _game.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_game.developer} · ${_game.consoles.join(', ')}',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        PriceTag(
                          currentPrice: _selectedEdition.currentPrice,
                          regularPrice: _selectedEdition.regularPrice,
                          discountPercent: _selectedEdition.discountPercent,
                          isLowestHistorical:
                              _selectedEdition.isLowestHistorical,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.divider),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Edition Selector (if multiple)
                  if (_game.editions.length > 1) ...[
                    const Text(
                      'Selecciona la Edición',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _game.editions.map((ed) {
                        final isSelected = ed.id == _selectedEdition.id;
                        return ChoiceChip(
                          label: Text(
                              '${ed.name} (${CurrencyFormatter.formatUsd(ed.currentPrice)})'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedEdition = ed;
                                _isLoadingHistory = true;
                              });
                              _loadData();
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Promo Status & Verification Details
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Fin de la oferta:',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12),
                            ),
                            Text(
                              _selectedEdition.promoEndLabel ??
                                  DateFormatter.formatPromoEndDate(promoEnd),
                              style: TextStyle(
                                color: promoEnd != null
                                    ? AppTheme.warning
                                    : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Última verificación:',
                              style: TextStyle(
                                  color: AppTheme.textMuted, fontSize: 12),
                            ),
                            Text(
                              DateFormatter.formatRelativeTime(
                                  _selectedEdition.lastChecked),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        if (_selectedEdition.requiresSubscription) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Condición especial:',
                                style: TextStyle(
                                    color: AppTheme.textMuted, fontSize: 12),
                              ),
                              Text(
                                _selectedEdition.subscriptionName ??
                                    'Requiere suscripción activa',
                                style: const TextStyle(
                                  color: AppTheme.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PRIMARY ACTIONS: Dinoxo Store & Alert
                  ElevatedButton.icon(
                    onPressed: () {
                      WhatsAppService.sendGameBalanceInquiry(
                        gameTitle: _game.title,
                        platform: _game.platform,
                        referencePrice: _selectedEdition.currentPrice,
                      );
                    },
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Comprar saldo en Dinoxo Store'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Button to Open the Official US Store directly for this game
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final storeUrl =
                            _selectedEdition.officialStoreUrl.isNotEmpty &&
                                    !_selectedEdition.officialStoreUrl
                                        .endsWith('/store/') &&
                                    !_selectedEdition.officialStoreUrl
                                        .endsWith('/store')
                                ? _selectedEdition.officialStoreUrl
                                : AppConstants.officialStoreUrlForGame(
                                    _game.platform,
                                    _game.title,
                                  );
                        WhatsAppService.launchExternalUrl(storeUrl);
                      },
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: Text(
                        'Abrir en ${AppConstants.platformDisplayName(_game.platform)} Store (USA)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.platformColor(_game.platform)
                            .withAlpha(160),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showCreateAlertDialog,
                          icon: const Icon(Icons.notifications_active_outlined,
                              size: 17),
                          label: const Text('Crear Alerta',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final trackerUrl =
                                _selectedEdition.sourceUrl.isNotEmpty &&
                                        !_selectedEdition.sourceUrl
                                            .endsWith('/us-store')
                                    ? _selectedEdition.sourceUrl
                                    : AppConstants.dealsTrackerUrlForGame(
                                        _game.platform,
                                        _game.title,
                                      );
                            WhatsAppService.launchExternalUrl(trackerUrl);
                          },
                          icon: const Icon(Icons.insights, size: 17),
                          label: const Text('Ver en Tracker Deals',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price History Chart
                  if (_isLoadingHistory)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    PriceHistoryChart(
                      observations: _observations,
                      regularPrice: _selectedEdition.regularPrice,
                      lowestObservedPrice: _observations.isEmpty
                          ? _selectedEdition.currentPrice
                          : _observations
                              .map((o) => o.price)
                              .reduce((a, b) => a < b ? a : b),
                      providerReportedLowest:
                          _selectedEdition.providerReportedLowest,
                    ),
                    const SizedBox(height: 16),

                    // Next-Sale Estimation
                    SaleEstimationCard(estimation: _estimation),
                    const SizedBox(height: 20),
                  ],

                  // "Antes de Comprar" Dossier
                  LiveReviewSection(game: _game),
                  const SizedBox(height: 20),

                  // Source & Tracker Reference Link
                  if (_selectedEdition.sourceUrl.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link,
                              size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Fuente de referencia y seguimiento externo:',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 11),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              WhatsAppService.launchExternalUrl(
                                  _selectedEdition.sourceUrl);
                            },
                            child: const Text('Ver tracker',
                                style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
