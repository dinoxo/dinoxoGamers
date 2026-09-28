import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import 'package:dinoxo_gamers/ui/features/subscriptions/plus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../fixtures/subscriptions.dart';

class _TrackedItem extends SubscriptionItem {
  _TrackedItem(int number)
      : super(
            id: 'large_$number',
            title: 'Game ${number.toString().padLeft(4, '0')}',
            platform: GamePlatform.playstation,
            tier: SubscriptionTier.psExtra,
            status: SubscriptionStatus.included,
            category: SubscriptionCategory.catalog,
            coverUrl: '',
            consoles: const ['PS5'],
            checkedAt: DateTime(2026, 9, 28));
  static final readCovers = <String>{};
  @override
  String get coverUrl {
    readCovers.add(id);
    return '';
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('a large catalog prepares artwork only for the visible viewport',
      (tester) async {
    final service = SubscriptionService(
        source: TestSubscriptionSource(List.generate(1700, _TrackedItem.new)),
        clock: () => DateTime(2026, 9, 28));
    await service.refresh();
    _TrackedItem.readCovers.clear();
    await tester.pumpWidget(
        MaterialApp(home: PlusScreen(service: service, autoLoad: false)));
    await tester.pumpAndSettle();
    expect(find.text('Game 0000'), findsOneWidget);
    expect(_TrackedItem.readCovers.length, lessThan(50),
        reason: 'Offscreen cards must not be prepared eagerly.');
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -1200));
    await tester.pumpAndSettle();
    expect(_TrackedItem.readCovers.length, lessThan(100));
    expect(tester.takeException(), isNull);
  });
}
