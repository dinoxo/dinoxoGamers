import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/subscription_source.dart';
import '../models/subscription_item.dart';
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
  final Map<GamePlatform, String> errors = {};
  final Map<GamePlatform, DateTime> checkedAt = {};
  Future<void>? _pending;
  bool get loading => _pending != null;

  Future<void> ensureLoaded() {
    if (checkedAt.length == 3 &&
        checkedAt.values.every((time) =>
            _clock().difference(time) < const Duration(minutes: 30))) {
      return Future.value();
    }
    return refresh();
  }

  Future<void> refresh() {
    if (_pending != null) return _pending!;
    final task = _load();
    _pending = task;
    notifyListeners();
    return task;
  }

  Future<void> _load() async {
    await Future.wait(GamePlatform.values.map((platform) async {
      try {
        final items = await _source.fetch(platform, _clock());
        _catalogs[platform] = items;
        checkedAt[platform] = _clock();
        errors.remove(platform);
      } catch (_) {
        _catalogs.remove(platform);
        checkedAt.remove(platform);
        errors[platform] =
            'No se pudo verificar ${AppConstants.platformDisplayName(platform)}. Reintenta la consulta.';
      }
      notifyListeners();
    }));
    _pending = null;
    notifyListeners();
  }

  List<SubscriptionItem> getItems(
      {GamePlatform? platform, SubscriptionCategory? category, String? query}) {
    final now = _clock();
    final next = DateTime(now.year, now.month + 1);
    final afterNext = DateTime(now.year, now.month + 2);
    final q = subscriptionTitleKey(query ?? '');
    return _catalogs.values.expand((items) => items).where((item) {
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
        default:
          if (item.category != category || !item.availableAt(now)) return false;
      }
      return q.isEmpty ||
          subscriptionTitleKey(item.title).contains(q) ||
          subscriptionTitleKey(item.tier.displayName).contains(q);
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  SubscriptionMatch? checkGame(String title,
      {GamePlatform? platform, List<String>? consoles}) {
    if (title.trim().isEmpty) return null;
    final key = subscriptionTitleKey(title);
    final now = _clock();
    SubscriptionItem? best;
    for (final item in _catalogs.values.expand((items) => items)) {
      if (platform != null && item.platform != platform) continue;
      if (item.checkedAt == null ||
          _clock().difference(item.checkedAt!) > const Duration(hours: 24)) {
        continue;
      }
      if (!item.availableAt(_clock()) &&
          !(item.addedAt?.isAfter(_clock()) == true)) {
        continue;
      }
      // An emulated original is not proof that a separately sold remake is included.
      if (item.platform == GamePlatform.nintendo &&
          consoles != null &&
          !consoles.any((c) => item.consoles.contains(c))) {
        continue;
      }
      if (subscriptionTitleKey(item.title) == key) {
        final included = item.availableAt(now);
        if (best == null ||
            included && !best.availableAt(now) ||
            included == best.availableAt(now) &&
                item.tier.rank < best.tier.rank) {
          best = item;
        }
      }
    }
    return best == null ? null : SubscriptionMatch(item: best, verifiedAt: now);
  }
}
