import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import '../fixtures/subscriptions.dart';

void main() {
  test('the official PlayStation Plus product suffix matches the sold game',
      () async {
    final service = SubscriptionService(
        source: TestSubscriptionSource([
          subscription(
              title: "Ghost of Tsushima DIRECTOR’S CUT (PlayStation Plus)",
              checked: DateTime(2026, 9, 28)),
        ]),
        clock: () => DateTime(2026, 9, 28));
    await service.refresh();
    expect(
        service
            .checkGame("Ghost of Tsushima DIRECTOR'S CUT",
                platform: GamePlatform.playstation)
            ?.isIncluded,
        true);
    expect(
        service.checkGame('Ghost of Tsushima 2',
            platform: GamePlatform.playstation),
        isNull);
  });
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
