import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import '../fixtures/subscriptions.dart';

void main() {
  test('verified catalogs can be filtered and reused without another download',
      () async {
    final now = DateTime(2026, 9, 27);
    final source = TestSubscriptionSource([
      subscription(),
      subscription(
          title: 'Halo',
          platform: GamePlatform.xbox,
          tier: SubscriptionTier.xboxUltimate),
    ]);
    final service = SubscriptionService(source: source, clock: () => now);
    await service.ensureLoaded();
    await service.ensureLoaded();
    expect(source.calls, 3);
    expect(service.getItems(platform: GamePlatform.xbox).single.title, 'Halo');
    expect(service.getItems(query: 'Resident').single.title, 'Resident Evil 2');
    expect(
        service.checkGame('Halo', platform: GamePlatform.xbox)!.advisoryMessage,
        contains('Si tienes'));
  });
}
