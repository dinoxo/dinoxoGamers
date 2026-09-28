import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/ui/features/game_details/game_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../fixtures/test_repository.dart';

void main() {
  testWidgets('a search result without a published price opens safely',
      (tester) async {
    const game = Game(
      id: 'unpriced',
      title: 'Announced game',
      slug: 'announced-game',
      coverUrl: '',
      platform: GamePlatform.playstation,
      consoles: ['PS5'],
      genres: [],
      developer: '',
      publisher: '',
      releaseDate: null,
    );
    await tester.pumpWidget(MaterialApp(
        home: GameDetailsScreen(game: game, repository: TestRepository())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Announced game'), findsOneWidget);
    expect(find.text('Crear Alerta'), findsNothing);
  });
}
