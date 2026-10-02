import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/core/theme/app_theme.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/models/game_edition.dart';
import 'package:dinoxo_gamers/ui/core/widgets/deal_card.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('game cards remain usable on narrow screens with larger text',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var opened = false;
    var favorited = false;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 800), textScaler: TextScaler.linear(1.4)),
            child: Scaffold(
                body: ListView(children: [
              DealCard(
                game: Game(
                    id: 'long',
                    title: 'Ghost of Tsushima DIRECTOR’S CUT Deluxe Edition',
                    slug: 'long',
                    coverUrl: '',
                    platform: GamePlatform.playstation,
                    consoles: const ['PS5', 'PS4'],
                    genres: const [],
                    developer: '',
                    publisher: '',
                    releaseDate: null,
                    editions: [
                      GameEdition(
                          id: 'edition',
                          gameId: 'long',
                          name: 'Deluxe',
                          currentPrice: 119.99,
                          regularPrice: 149.99,
                          discountPercent: 20,
                          lowestObservedPrice: 119.99,
                          lowestObservedDate: DateTime(2026),
                          sourceUrl: '',
                          officialStoreUrl: '',
                          lastChecked: DateTime(2026))
                    ]),
                onTap: () => opened = true,
                onToggleFavorite: () => favorited = true,
              )
            ])))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('\$119.99'), findsOneWidget);
    await tester.tap(find.byTooltip('Añadir a favoritos'));
    expect(favorited, isTrue);
    expect(opened, isFalse);
    await tester
        .tap(find.text('Ghost of Tsushima DIRECTOR’S CUT Deluxe Edition'));
    expect(opened, isTrue);
  });
  testWidgets('DealCard renders title, USA badge, platform and prices',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final testGame = Game(
      id: 'test_game_1',
      title: 'Helldivers 2 Super Earth',
      slug: 'helldivers-2',
      coverUrl: '',
      platform: GamePlatform.playstation,
      consoles: ['PS5'],
      genres: ['Shooter', 'Cooperativo'],
      developer: 'Arrowhead Game Studios',
      publisher: 'PlayStation Publishing',
      releaseDate: DateTime(2024, 2, 8),
      editions: [
        GameEdition(
          id: 'hd2_std',
          gameId: 'test_game_1',
          name: 'Edición Estándar',
          currentPrice: 31.99,
          regularPrice: 39.99,
          discountPercent: 20,
          lowestObservedPrice: 31.99,
          lowestObservedDate: now,
          isLowestHistorical: true,
          sourceUrl: '',
          officialStoreUrl: '',
          lastChecked: now,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: DealCard(
            game: testGame,
            isFavorite: false,
            onTap: () {},
            onToggleFavorite: () {},
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('Helldivers 2 Super Earth'), findsOneWidget);

    // Verify USA · USD Badge
    expect(find.text('USA · USD'), findsOneWidget);

    // Verify Platform Name
    expect(find.text('PlayStation'), findsOneWidget);

    // Verify Prices
    expect(find.text('\$31.99'), findsOneWidget);
    expect(find.text('\$39.99'), findsOneWidget);
    expect(find.text('-20%'), findsOneWidget);
    expect(find.text('MÍNIMO HISTÓRICO'), findsOneWidget);
  });
}
