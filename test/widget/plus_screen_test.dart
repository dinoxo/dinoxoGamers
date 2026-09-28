import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/models/membership_benefits.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import 'package:dinoxo_gamers/ui/features/subscriptions/plus_screen.dart';
import '../fixtures/subscriptions.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets(
      'benefits are rendered from the loaded plan and are reachable on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = TestSubscriptionSource([])
      ..benefits = [
        MembershipBenefits(
            tier: SubscriptionTier.nsoExpansion,
            features: const ['Beneficio recibido de la fuente'],
            sourceUrl:
                'https://www.nintendo.com/us/online/nintendo-switch-online/expansion-pack/',
            checkedAt: DateTime(2026, 9, 28))
      ];
    final service =
        SubscriptionService(source: source, clock: () => DateTime(2026, 9, 28));
    await service.refresh();
    await tester.pumpWidget(
        MaterialApp(home: PlusScreen(service: service, autoLoad: false)));
    await tester.ensureVisible(find.text('Beneficios'));
    await tester.tap(find.text('Beneficios'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Beneficio recibido de la fuente'), findsOneWidget);
    expect(find.text('NSO + Paquete de Expansión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
    await tester.ensureVisible(find.text('Mes siguiente'));
    await tester.tap(find.text('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Aún no hay juegos con fecha confirmada'),
        findsOneWidget);
    expect(
        service.getItems(category: SubscriptionCategory.comingSoon), isEmpty);
  });
}
