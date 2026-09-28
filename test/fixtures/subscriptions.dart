import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/subscription_source.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/models/membership_benefits.dart';

class TestSubscriptionSource extends SubscriptionSource {
  TestSubscriptionSource(this.items);
  final List<SubscriptionItem> items;
  GamePlatform? failingPlatform;
  int calls = 0;
  List<MembershipBenefits> benefits = [];
  @override
  Future<SubscriptionCatalog> fetchCatalog(
          GamePlatform platform, DateTime now) async =>
      SubscriptionCatalog(
          items: await fetch(platform, now),
          benefits:
              benefits.where((p) => p.tier.platform == platform).toList());
  @override
  Future<List<SubscriptionItem>> fetch(
      GamePlatform platform, DateTime now) async {
    calls++;
    if (platform == failingPlatform) throw StateError('HTTP 503');
    return items.where((item) => item.platform == platform).toList();
  }
}

SubscriptionItem subscription(
        {String title = 'Resident Evil 2',
        GamePlatform platform = GamePlatform.playstation,
        SubscriptionTier tier = SubscriptionTier.psExtra,
        DateTime? start,
        DateTime? end,
        DateTime? checked,
        bool confirmed = true}) =>
    SubscriptionItem(
        id: '${platform.name}_$title',
        title: title,
        platform: platform,
        tier: tier,
        status: SubscriptionStatus.included,
        category: SubscriptionCategory.catalog,
        coverUrl: '',
        consoles: platform == GamePlatform.playstation ? ['PS5'] : ['NES'],
        checkedAt: checked ?? DateTime(2026, 9, 27),
        addedAt: start,
        availableUntil: end,
        availabilityConfirmed: confirmed,
        sourceUrl: 'https://www.playstation.com/en-us/ps-plus/games/');
