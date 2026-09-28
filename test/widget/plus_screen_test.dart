import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import 'package:dinoxo_gamers/ui/features/subscriptions/plus_screen.dart';
import '../fixtures/subscriptions.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets(
      'Plus uses a verified catalog and shows no announcement as an explicit state',
      (tester) async {
    final service = SubscriptionService(
        source: TestSubscriptionSource([
          subscription(start: DateTime(2026, 9, 15)),
        ]),
        clock: () => DateTime(2026, 9, 27));
    await service.refresh();
    await tester.pumpWidget(
        MaterialApp(home: PlusScreen(service: service, autoLoad: false)));
    await tester.pumpAndSettle();
    expect(find.text('Plus & Suscripciones'), findsOneWidget);
    expect(find.text('Resident Evil 2'), findsOneWidget);
    await tester.tap(find.text('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aún no hay juegos con fecha confirmada'),
        findsOneWidget);
    expect(
        service.getItems(category: SubscriptionCategory.comingSoon), isEmpty);
  });
}
