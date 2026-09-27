import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/core/theme/app_theme.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/models/game_edition.dart';
import 'package:dinoxo_gamers/ui/core/widgets/deal_card.dart';

void main() {
  testWidgets('DealCard renders title, USA badge, platform and prices', (WidgetTester tester) async {
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
