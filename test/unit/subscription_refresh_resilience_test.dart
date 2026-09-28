import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import '../fixtures/subscriptions.dart';

void main() {
  test('failed refresh keeps last visible games but removes purchase advice',
      () async {
    final source = TestSubscriptionSource([subscription()]);
    final service =
        SubscriptionService(source: source, clock: () => DateTime(2026, 9, 28));
    await service.refresh();
    source.failingPlatform = GamePlatform.playstation;
    await service.refresh();
    expect(service.getItems().single.title, 'Resident Evil 2');
    expect(service.checkGame('Resident Evil 2'), isNull);
    expect(service.errors[GamePlatform.playstation], isNotNull);
  });
  test('opening Plus repeatedly after a failure does not restart every source',
      () async {
    final source = TestSubscriptionSource([])
      ..failingPlatform = GamePlatform.nintendo;
    final service =
        SubscriptionService(source: source, clock: () => DateTime(2026, 9, 28));
    await service.ensureLoaded();
    final calls = source.calls;
    await service.ensureLoaded();
    await service.ensureLoaded();
    expect(source.calls, calls);
  });
}
