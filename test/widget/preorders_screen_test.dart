import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/preorder_source.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/models/preorder_game.dart';
import 'package:dinoxo_gamers/ui/features/preorders/preorders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/test_repository.dart';

class _Preorders extends PreorderSource {
  _Preorders(this.game);
  final PreorderGame game;

  @override
  Future<PreorderPage> fetchPage({int page = 1}) async =>
      PreorderPage(page == 1 ? [game] : []);

  @override
  Future<List<String>> autocomplete(String query) async =>
      game.title.toLowerCase().contains(query.toLowerCase())
          ? [game.title]
          : [];

  @override
  Future<PreorderPage> search(String query, {int page = 1}) async =>
      PreorderPage(
          page == 1 && game.title.toLowerCase().contains(query.toLowerCase())
              ? [game]
              : []);
}

void main() {
  testWidgets('Preventas suggests only its catalog and creates a date alert',
      (tester) async {
    final date = DateTime.now();
    final release = DateTime(date.year, date.month, date.day + 5);
    final game = Game(
        id: 'future-1',
        title: 'Future Odyssey',
        slug: 'future-odyssey',
        coverUrl: '',
        platform: GamePlatform.playstation,
        consoles: const ['PS5'],
        genres: const [],
        developer: '',
        publisher: 'Studio',
        releaseDate: release);
    final item = PreorderGame(
        id: game.id,
        title: game.title,
        coverUrl: '',
        publisher: 'Studio',
        developer: '',
        platform: game.platform,
        consoles: game.consoles,
        releaseDate: release,
        sourceUri: Uri.parse(
            'https://www.dekudeals.com/items/future-odyssey?country=us'),
        isPreorder: true,
        game: game);
    var alerts = 0;
    await tester.pumpWidget(MaterialApp(
        home: PreordersScreen(
            repository: TestRepository(),
            source: _Preorders(item),
            onCreateReleaseAlert: (_) async {
              alerts++;
            })));
    await tester.pumpAndSettle();

    expect(find.text('Faltan 5 días'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Future');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Future Odyssey'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Future Odyssey'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avisarme'));
    await tester.pumpAndSettle();
    expect(alerts, 1);
  });
}
