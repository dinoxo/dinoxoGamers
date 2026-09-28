import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/subscription_source.dart';
import '../models/subscription_item.dart';
import '../models/membership_benefits.dart';
import 'subscription_title.dart';
export 'subscription_title.dart';

class SubscriptionService extends ChangeNotifier {
  SubscriptionService({SubscriptionSource? source, DateTime Function()? clock})
      : _source = source ?? SubscriptionSource(),
        _clock = clock ?? DateTime.now;
  static final instance = SubscriptionService();
  final SubscriptionSource _source;
  final DateTime Function() _clock;
  final Map<GamePlatform, List<SubscriptionItem>> _catalogs = {};
  final Map<String, List<SubscriptionItem>> _titleIndex = {};
  final Map<String, String> _searchKeys = {};
  List<SubscriptionItem> _sortedItems = [];
  final Map<GamePlatform, List<MembershipBenefits>> _benefits = {};
  final Map<GamePlatform, List<String>> notices = {};
  List<MembershipBenefits> getBenefits({GamePlatform? platform}) =>
      _benefits.entries
          .where((e) => platform == null || e.key == platform)
          .expand((e) => e.value)
          .toList();
  final Map<GamePlatform, String> errors = {};
  final Map<GamePlatform, DateTime> checkedAt = {};
  Future<void>? _pending;
  DateTime? _lastAttempt;
  bool get loading => _pending != null;

  Future<void> ensureLoaded() {
    if (_pending != null) return _pending!;
    if (_lastAttempt != null &&
        _clock().difference(_lastAttempt!) < const Duration(minutes: 2)) {
      return Future.value();
    }
    if (checkedAt.length == 3 &&
        checkedAt.values.every((time) =>
            _clock().difference(time) < const Duration(minutes: 30))) {
      return Future.value();
    }
    return refresh();
  }

  Future<void> refresh() {
    if (_pending != null) return _pending!;
    _lastAttempt = _clock();
    final task = _load();
    _pending = task;
    notifyListeners();
    return task;
  }

  Future<void> _load() async {
    // Serialize the three large downloads/parsers on memory-limited phones.
    for (final platform in GamePlatform.values) {
      try {
        final catalog = await _source.fetchCatalog(platform, _clock());
        if (catalog.gamesVerified) {
          _catalogs[platform] = catalog.items;
          checkedAt[platform] = _clock();
          errors.remove(platform);
        } else {
          errors[platform] =
              'No se pudo actualizar ${AppConstants.platformDisplayName(platform)}. La última consulta sigue disponible; su vigencia no está confirmada.';
        }
        if (catalog.benefits.isNotEmpty) _benefits[platform] = catalog.benefits;
        notices[platform] = catalog.notices;
      } catch (_) {
        errors[platform] =
            'No se pudo actualizar ${AppConstants.platformDisplayName(platform)}. Se conserva la última consulta; comprueba tu conexión y actualiza cuando puedas.';
      }
      _rebuildIndex();
      notifyListeners();
    }
    _pending = null;
    notifyListeners();
  }

  void _rebuildIndex() {
    _titleIndex.clear();
    _searchKeys.clear();
    _sortedItems = _catalogs.values.expand((items) => items).toList();
    for (final item in _sortedItems) {
      final key = subscriptionTitleKey(item.title);
      (_titleIndex[key] ??= []).add(item);
      _searchKeys[item.id] =
          '$key ${subscriptionTitleKey(item.tier.displayName)}';
    }
    _sortedItems
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  DateTime get now => _clock();

  List<SubscriptionItem> getItems(
      {GamePlatform? platform, SubscriptionCategory? category, String? query}) {
    final now = _clock();
    final next = DateTime(now.year, now.month + 1);
    final afterNext = DateTime(now.year, now.month + 2);
    final q = subscriptionTitleKey(query ?? '');
    return _sortedItems.where((item) {
      if (platform != null && item.platform != platform) return false;
      switch (category ?? SubscriptionCategory.all) {
        case SubscriptionCategory.monthly:
          if (item.addedAt == null ||
              item.addedAt!.year != now.year ||
              item.addedAt!.month != now.month) {
            return false;
          }
        case SubscriptionCategory.comingSoon:
          if (item.addedAt == null ||
              item.addedAt!.isBefore(next) ||
              !item.addedAt!.isBefore(afterNext)) {
            return false;
          }
        case SubscriptionCategory.all:
          if (!item.availableAt(now)) return false;
        case SubscriptionCategory.upcoming:
          if (item.addedAt?.isAfter(now) != true) return false;
        case SubscriptionCategory.leavingSoon:
          if (item.status != SubscriptionStatus.leavingSoon ||
              item.availableUntil?.isAfter(now) != true) {
            return false;
          }
        case SubscriptionCategory.benefits:
          return false;
        default:
          if (item.category != category || !item.availableAt(now)) return false;
      }
      return q.isEmpty || (_searchKeys[item.id]?.contains(q) ?? false);
    }).toList();
  }

  SubscriptionMatch? checkGame(String title,
      {GamePlatform? platform, List<String>? consoles}) {
    if (title.trim().isEmpty) return null;
    final key = subscriptionTitleKey(title);
    final now = _clock();
    SubscriptionItem? best;
    for (final item in _titleIndex[key] ?? <SubscriptionItem>[]) {
      if (errors.containsKey(item.platform)) continue;
      if (platform != null && item.platform != platform) continue;
      if (item.checkedAt == null ||
          now.difference(item.checkedAt!) > const Duration(hours: 24)) {
        continue;
      }
      if (!item.availableAt(now) && !(item.addedAt?.isAfter(now) == true)) {
        continue;
      }
      // An emulated original is not proof that a separately sold remake is included.
      if (item.platform == GamePlatform.nintendo &&
          consoles != null &&
          !consoles.any((c) => item.consoles.contains(c))) {
        continue;
      }
      final included = item.availableAt(now);
      if (best == null ||
          included && !best.availableAt(now) ||
          included == best.availableAt(now) &&
              item.tier.rank < best.tier.rank) {
        best = item;
      }
    }
    return best == null ? null : SubscriptionMatch(item: best, verifiedAt: now);
  }
}
