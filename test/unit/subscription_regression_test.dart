import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';

void main() {
  test('starts without a fabricated subscription catalog', () {
    expect(SubscriptionService.instance.getItems(), isEmpty);
  });
  test('shared franchise words cannot make a different sequel included', () {
    expect(
        SubscriptionService.instance
            .checkGame('Resident Evil 20', platform: GamePlatform.playstation),
        isNull);
  });
  test('a Nintendo DLC does not make the complete base game included', () {
    expect(
        SubscriptionService.instance
            .checkGame('Mario Kart 8 Deluxe', platform: GamePlatform.nintendo),
        isNull);
  });
}
