import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';

void main() {
  group('SubscriptionService tests', () {
    final service = SubscriptionService.instance;

    test('retrieves all items across all platforms', () {
      final items = service.getItems();
      expect(items.length, greaterThan(15));
      expect(items.any((i) => i.platform == GamePlatform.playstation), isTrue);
      expect(items.any((i) => i.platform == GamePlatform.xbox), isTrue);
      expect(items.any((i) => i.platform == GamePlatform.nintendo), isTrue);
    });

    test('filters items by platform correctly', () {
      final psItems = service.getItems(platform: GamePlatform.playstation);
      final xbItems = service.getItems(platform: GamePlatform.xbox);
      final nsoItems = service.getItems(platform: GamePlatform.nintendo);

      expect(psItems.every((i) => i.platform == GamePlatform.playstation), isTrue);
      expect(xbItems.every((i) => i.platform == GamePlatform.xbox), isTrue);
      expect(nsoItems.every((i) => i.platform == GamePlatform.nintendo), isTrue);
    });

    test('filters items by category correctly', () {
      final monthlyItems = service.getItems(category: SubscriptionCategory.monthly);
      expect(monthlyItems.every((i) => i.category == SubscriptionCategory.monthly), isTrue);

      final leavingItems = service.getItems(category: SubscriptionCategory.leavingSoon);
      expect(leavingItems.every((i) => i.status == SubscriptionStatus.leavingSoon), isTrue);

      final comingSoon = service.getItems(category: SubscriptionCategory.comingSoon);
      expect(comingSoon.every((i) => i.status == SubscriptionStatus.comingSoon), isTrue);
    });

    test('filters items by query', () {
      final searchStarfield = service.getItems(query: 'Starfield');
      expect(searchStarfield.isNotEmpty, isTrue);
      expect(searchStarfield.first.title, contains('Starfield'));
    });

    test('checkGame accurately identifies subscription games and cleans editions', () {
      // Direct PlayStation Extra game
      final psMatch = service.checkGame("Demon's Souls - Digital Deluxe Edition", platform: GamePlatform.playstation);
      expect(psMatch, isNotNull);
      expect(psMatch!.isIncluded, isTrue);
      expect(psMatch.advisoryTitle, contains('no comprar este juego'));

      // Direct Xbox Game Pass game
      final xbMatch = service.checkGame("Starfield Standard Edition", platform: GamePlatform.xbox);
      expect(xbMatch, isNotNull);
      expect(xbMatch!.isIncluded, isTrue);
      expect(xbMatch.item.tier, SubscriptionTier.xboxUltimate);

      // Leaving soon game
      final leavingMatch = service.checkGame("Gotham Knights", platform: GamePlatform.xbox);
      expect(leavingMatch, isNotNull);
      expect(leavingMatch!.isLeavingSoon, isTrue);
      expect(leavingMatch.advisoryTitle, contains('Sale pronto'));

      // Coming soon game
      final comingMatch = service.checkGame("Call of Duty: Black Ops 6", platform: GamePlatform.xbox);
      expect(comingMatch, isNotNull);
      expect(comingMatch!.isComingSoon, isTrue);
      expect(comingMatch.advisoryTitle, contains('Próximamente'));

      // Non-subscription game returns null
      final noMatch = service.checkGame("Nonexistent Mystery Indie 2029");
      expect(noMatch, isNull);
    });
  });
}
