import 'package:flutter/material.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/models/membership_benefits.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import 'package:dinoxo_gamers/ui/features/subscriptions/plus_screen.dart';
import 'package:dinoxo_gamers/ui/features/game_details/game_details_screen.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import '../fixtures/subscriptions.dart';
import '../fixtures/test_repository.dart';

class _PlusGameRepository extends TestRepository {
  @override
  Future<LiveCatalogPage> searchOnline(String query,
          {GamePlatform? platform, int page = 1}) async =>
      LiveCatalogPage([
        Game(
            id: 'plus_game',
            title: query,
            slug: 'plus-game',
            coverUrl: '',
            platform: platform!,
            consoles: const ['PS5'],
            genres: const [],
            developer: '',
            publisher: '',
            releaseDate: null)
      ]);
}

void main() {
  testWidgets('Plus retains the visible query when changing categories',
      (tester) async {
    final service = SubscriptionService(
        source: TestSubscriptionSource([subscription()]),
        clock: () => DateTime(2026, 9, 28));
    await service.refresh();
    await tester.pumpWidget(
        MaterialApp(home: PlusScreen(service: service, autoLoad: false)));
    await tester.enterText(find.byType(TextField), 'Resident');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.text(SubscriptionCategory.monthly.label));
    await tester.tap(find.text(SubscriptionCategory.monthly.label));
    await tester.pumpAndSettle();
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Resident');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Nintendo opens internal plans, emulator library and DLC benefits',
      (tester) async {
    final source = TestSubscriptionSource([
      subscription(
          title: 'Super Mario Bros.',
          platform: GamePlatform.nintendo,
          tier: SubscriptionTier.nsoStandard)
    ])
      ..benefits = [
        MembershipBenefits(
            tier: SubscriptionTier.nsoStandard,
            features: const ['Juego en línea'],
            sourceUrl: 'https://www.nintendo.com/us/',
            checkedAt: DateTime(2026, 9, 28)),
        MembershipBenefits(
            tier: SubscriptionTier.nsoExpansion,
            features: const [
              'Mario Kart Booster Course Pass · Requiere juego base'
            ],
            sourceUrl: 'https://www.nintendo.com/us/',
            checkedAt: DateTime(2026, 9, 28))
      ];
    final service =
        SubscriptionService(source: source, clock: () => DateTime(2026, 9, 28));
    await service.refresh();
    await tester.pumpWidget(
        MaterialApp(home: PlusScreen(service: service, autoLoad: false)));
    await tester.ensureVisible(find.text('Nintendo Switch Online'));
    await tester.tap(find.text('Nintendo Switch Online'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Juego en línea'), findsOneWidget);
    await tester.tap(find.text('Ver membresía').first);
    await tester.pumpAndSettle();
    expect(find.text('Juegos incluidos'), findsOneWidget);
    expect(find.text('Super Mario Bros.'), findsOneWidget);
    expect(find.text('Fuente oficial USA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('Ver detalles from a Plus game opens that game ficha',
      (tester) async {
    final service = SubscriptionService(
        source: TestSubscriptionSource([subscription()]),
        clock: () => DateTime(2026, 9, 27));
    await service.refresh();
    await tester.pumpWidget(MaterialApp(
        home: PlusScreen(
            service: service,
            repository: _PlusGameRepository(),
            autoLoad: false)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver detalles').first);
    await tester.pumpAndSettle();
    expect(find.byType(GameDetailsScreen), findsOneWidget);
    expect(find.text('Resident Evil 2'), findsWidgets);
  });
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
