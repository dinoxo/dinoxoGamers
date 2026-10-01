import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/game.dart';
import '../../domain/models/price_observation.dart';
import '../../domain/models/user_alert.dart';
import '../../domain/models/release_alert.dart';
import '../../domain/services/notification_service.dart';
import '../../domain/services/price_alert_scheduler.dart';
import '../datasources/local_database_service.dart';
import '../datasources/web_scraper_service.dart';

class GameFilterOptions {
  final GamePlatform? platform;
  final String? console;
  final double? maxPrice;
  final int? minDiscountPercent;
  final bool onlyAllTimeLows;
  final bool onlyEndingSoon;
  final ProductType? productType;
  final bool? requiresSubscription;
  final String? genre;

  const GameFilterOptions({
    this.platform,
    this.console,
    this.maxPrice,
    this.minDiscountPercent,
    this.onlyAllTimeLows = false,
    this.onlyEndingSoon = false,
    this.productType,
    this.requiresSubscription,
    this.genre,
  });

  bool get hasActiveFilters =>
      platform != null ||
      console != null ||
      maxPrice != null ||
      (minDiscountPercent != null && minDiscountPercent! > 0) ||
      onlyAllTimeLows ||
      onlyEndingSoon ||
      productType != null ||
      requiresSubscription != null ||
      genre != null;
}

class GameRepository extends ChangeNotifier {
  final LocalDatabaseService _localDb;
  final LiveWebScraperService _web;
  List<Game> _cachedCatalog = [];
  bool _loadedCache = false;
  final Future<bool> Function(UserAlert alert, double price) _notifyPrice;

  GameRepository(
      {LocalDatabaseService? localDb,
      LiveWebScraperService? web,
      Future<bool> Function(UserAlert alert, double price)? notifyPrice})
      : _localDb = localDb ?? LocalDatabaseService.instance,
        _web = web ?? LiveWebScraperService(),
        _notifyPrice = notifyPrice ??
            ((alert, price) => NotificationService.instance
                .showPriceAlertNotification(alert: alert, newPrice: price));

  Future<List<Game>> getGames({GameFilterOptions? filters}) async {
    List<Game> results = List<Game>.from(_cachedCatalog);

    if (filters == null) return results;

    if (filters.platform != null) {
      results = results.where((g) => g.platform == filters.platform).toList();
    }

    if (filters.console != null && filters.console!.isNotEmpty) {
      results =
          results.where((g) => g.consoles.contains(filters.console)).toList();
    }

    if (filters.genre != null && filters.genre!.isNotEmpty) {
      results = results.where((g) => g.genres.contains(filters.genre)).toList();
    }

    if (filters.maxPrice != null) {
      results =
          results.where((g) => g.currentPrice <= filters.maxPrice!).toList();
    }

    if (filters.minDiscountPercent != null && filters.minDiscountPercent! > 0) {
      results = results
          .where((g) => g.discountPercent >= filters.minDiscountPercent!)
          .toList();
    }

    if (filters.onlyAllTimeLows) {
      results = results.where((g) => g.isLowestHistorical).toList();
    }

    if (filters.onlyEndingSoon) {
      final now = DateTime.now();
      results = results.where((g) {
        final promoEnd = g.primaryEdition?.promoEndDate;
        if (promoEnd == null) return false;
        final diff = promoEnd.difference(now);
        return !diff.isNegative && diff.inDays <= 3;
      }).toList();
    }

    if (filters.productType != null) {
      results = results
          .where((g) => g.primaryEdition?.productType == filters.productType)
          .toList();
    }

    if (filters.requiresSubscription != null) {
      results = results
          .where((g) =>
              (g.primaryEdition?.requiresSubscription ?? false) ==
              filters.requiresSubscription)
          .toList();
    }

    return results;
  }

  Future<Game?> getGameById(String id) async {
    await _loadCache();
    try {
      return _cachedCatalog.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<PriceObservation>> getPriceHistory(
      String editionId, double regularPrice) async {
    if (!editionId.startsWith('deku_')) return [];
    return _localDb.getObservedPrices(editionId);
  }

  /// Refreshes live deals from online aggregators into the active catalog
  Future<LiveCatalogPage> refreshLiveDeals(
      {GamePlatform? platform, int page = 1}) async {
    final result = await _web.fetchLiveDeals(platform: platform, page: page);
    await _remember(result.games);
    return result;
  }

  /// Live online web search for games across PlayStation, Nintendo, and Xbox
  Future<LiveCatalogPage> searchOnline(String query,
      {GamePlatform? platform, int page = 1}) async {
    final result =
        await _web.searchWebGames(query, platform: platform, page: page);
    await _remember(result.games);
    return result;
  }

  Future<List<String>> fetchAutocomplete(String query,
      {GamePlatform? platform}) async {
    return await _web.fetchAutocomplete(query, platform: platform);
  }

  Future<LiveCatalogPage> searchLiveDeals(String query,
      {GamePlatform? platform, int page = 1}) async {
    final result =
        await _web.searchLiveDeals(query, platform: platform, page: page);
    await _remember(result.games);
    return result;
  }

  Future<void> _loadCache() async {
    if (_loadedCache) return;
    final cached = await _localDb.readCatalogSnapshots();
    _cachedCatalog = {
      for (final game in cached) game.id: game,
      for (final game in _cachedCatalog) game.id: game
    }.values.toList();
    _loadedCache = true;
  }

  Future<void> _remember(List<Game> games) async {
    await _loadCache();
    _cachedCatalog = {
      for (final game in _cachedCatalog) game.id: game,
      for (final game in games) game.id: game
    }.values.toList();
    for (final game in games) {
      await _localDb.saveCatalogSnapshot(game);
    }
    // Notification failures must never discard a successful price request.
    try {
      await _checkTargets(games);
    } catch (_) {/* Retry at next refresh. */}
  }

  Future<Game> refreshGame(Game game) async {
    final games = await _web.fetchGame(game);
    await _remember(games);
    return games.firstWhere((g) => g.id == game.id, orElse: () => games.first);
  }

  Future<void> _checkTargets(List<Game> games) async {
    final alerts = await _localDb.getAlerts();
    for (final alert in alerts.where((a) => a.isActive)) {
      final editions =
          games.expand((g) => g.editions).where((e) => e.id == alert.editionId);
      if (editions.isEmpty) continue;
      final edition = editions.first;
      if (!edition.currentPrice.isFinite ||
          edition.currentPrice < 0 ||
          (edition.currentPrice * 100).round() >
              (alert.targetPrice * 100).round() ||
          alert.lastNotifiedAt != null &&
              DateTime.now().difference(alert.lastNotifiedAt!).inHours < 24) {
        continue;
      }
      final claim = DateTime.now();
      if (!await _localDb.claimNotification(alert, claim)) continue;
      var sent = false;
      try {
        sent = await _notifyPrice(alert, edition.currentPrice);
      } finally {
        if (!sent) await _localDb.releaseNotification(alert, claim);
      }
      if (sent) notifyListeners();
    }
  }

  Future<List<String>> refreshAlertPrices() async {
    final errors = <String>[];
    final alerts = await getAlerts();
    for (final id
        in alerts.where((a) => a.isActive).map((a) => a.gameId).toSet()) {
      try {
        final game = await getGameById(id);
        if (game == null) {
          throw const CatalogException(
              'Busca de nuevo el juego para actualizar esta alerta antigua.');
        }
        await refreshGame(game);
      } catch (e) {
        errors.add(e is CatalogException
            ? e.message
            : 'No se pudo consultar una alerta.');
      }
    }
    return errors;
  }

  static List<Game> applyFilters(List<Game> games, GameFilterOptions f) =>
      games.where((g) {
        final e = g.primaryEdition;
        return (f.platform == null || g.platform == f.platform) &&
            (f.console == null || g.consoles.contains(f.console)) &&
            (f.genre == null || g.genres.contains(f.genre)) &&
            (f.maxPrice == null ||
                e != null && e.currentPrice <= f.maxPrice!) &&
            (f.minDiscountPercent == null ||
                g.discountPercent >= f.minDiscountPercent!) &&
            (!f.onlyAllTimeLows || g.isLowestHistorical) &&
            (!f.onlyEndingSoon ||
                e?.promoEndDate != null &&
                    e!.promoEndDate!.isAfter(DateTime.now()) &&
                    e.promoEndDate!.difference(DateTime.now()).inHours <= 72) &&
            (f.productType == null || e?.productType == f.productType) &&
            (f.requiresSubscription == null ||
                e?.requiresSubscription == f.requiresSubscription);
      }).toList();

  // --- FAVORITES ---
  Future<List<Game>> getFavoriteGames() async {
    await _loadCache();
    final favIds = await _localDb.getFavoriteGameIds();
    return _cachedCatalog.where((g) => favIds.contains(g.id)).toList();
  }

  Future<bool> isFavorite(String gameId) async {
    return await _localDb.isFavorite(gameId);
  }

  Future<void> toggleFavorite(String gameId) async {
    final isFav = await _localDb.isFavorite(gameId);
    if (isFav) {
      await _localDb.removeFavorite(gameId);
    } else {
      await _localDb.addFavorite(gameId);
    }
  }

  // --- ALERTS ---
  Future<List<UserAlert>> getAlerts() async {
    return await _localDb.getAlerts();
  }

  Future<void> saveAlert(UserAlert alert) async {
    if (!alert.targetPrice.isFinite || alert.targetPrice < 0) {
      throw ArgumentError('El precio objetivo debe ser un importe válido.');
    }
    await _localDb.saveAlert(alert);
    notifyListeners();
    await synchronizeAlertMonitoring();
  }

  Future<void> deleteAlert(String id) async {
    await _localDb.deleteAlert(id);
    notifyListeners();
    await synchronizeAlertMonitoring();
  }

  Future<void> toggleAlertActive(String id, bool isActive) async {
    await _localDb.toggleAlertActive(id, isActive);
    notifyListeners();
    await synchronizeAlertMonitoring();
  }

  Future<void> synchronizeAlertMonitoring() async =>
      PriceAlertScheduler.instance.synchronize(
          hasActiveAlerts: (await getAlerts()).any((alert) => alert.isActive));

  Future<List<ReleaseAlert>> getReleaseAlerts() => _localDb.getReleaseAlerts();

  Future<bool> saveReleaseAlert(ReleaseAlert alert) async {
    final source = Uri.tryParse(alert.sourceUrl);
    if (source == null || source.scheme != 'https' || source.host.isEmpty) {
      throw ArgumentError(
          'El lanzamiento necesita una fuente web verificable.');
    }
    if (alert.releaseDate.isBefore(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
      throw ArgumentError('La fecha de salida ya pasó.');
    }
    await _localDb.saveReleaseAlert(alert);
    notifyListeners();
    try {
      await NotificationService.instance.scheduleReleaseAlert(alert);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteReleaseAlert(ReleaseAlert alert) async {
    await _localDb.deleteReleaseAlert(alert.id);
    await NotificationService.instance.cancelReleaseAlert(alert);
    notifyListeners();
  }

  Future<bool> toggleReleaseAlertActive(ReleaseAlert alert) async {
    final updated = alert.copyWith(isActive: !alert.isActive);
    await _localDb.setReleaseAlertActive(alert.id, updated.isActive);
    notifyListeners();
    try {
      await NotificationService.instance.scheduleReleaseAlert(updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> synchronizeReleaseNotifications() async {
    for (final alert in await getReleaseAlerts()) {
      try {
        await NotificationService.instance.scheduleReleaseAlert(alert);
      } catch (_) {
        // The saved reminder stays visible and can be retried in Mis Alertas.
      }
    }
  }

  // --- LIBRARY ---
  Future<List<Game>> getOwnedGames() async {
    await _loadCache();
    final ownedIds = await _localDb.getOwnedGameIds();
    return _cachedCatalog.where((g) => ownedIds.contains(g.id)).toList();
  }

  Future<bool> isGameOwned(String gameId) async {
    return await _localDb.isGameOwned(gameId);
  }

  Future<void> toggleGameOwned(Game game) async {
    final isOwned = await _localDb.isGameOwned(game.id);
    if (isOwned) {
      await _localDb.removeGameFromOwned(game.id);
    } else {
      await _localDb.markGameAsOwned(
        game.id,
        AppConstants.platformDisplayName(game.platform),
        game.primaryEdition?.name ?? 'Estándar',
      );
    }
  }
}
