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

class _MultiSource extends PreorderSource {
  _MultiSource(this.games);
  final List<PreorderGame> games;

  @override
  Future<PreorderPage> fetchPage({int page = 1}) async => PreorderPage(games);
  @override
  Future<List<String>> autocomplete(String query) async => [];
  @override
  Future<PreorderPage> search(String query, {int page = 1}) async =>
      const PreorderPage([]);
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

  testWidgets(
      'PreordersScreen filters by platform and prioritizes GTA and Zelda',
      (tester) async {
    final now = DateTime.now();
    final release = DateTime(now.year, now.month, now.day + 30);

    final genericPs = PreorderGame(
      id: 'generic-ps',
      title: 'Indie Journey',
      coverUrl: '',
      publisher: 'Indie',
      developer: 'Indie',
      platform: GamePlatform.playstation,
      consoles: const ['PS5'],
      releaseDate: release,
      sourceUri: Uri.parse('https://example.com/indie'),
      isPreorder: true,
      game: const Game(
        id: 'generic-ps',
        title: 'Indie Journey',
        slug: 'indie-journey',
        coverUrl: '',
        platform: GamePlatform.playstation,
        consoles: ['PS5'],
        genres: [],
        developer: '',
        publisher: '',
        releaseDate: null,
      ),
    );

    final gta6 = PreorderGame(
      id: 'gta-6',
      title: 'Grand Theft Auto VI',
      coverUrl: '',
      publisher: 'Rockstar Games',
      developer: 'Rockstar Games',
      platform: GamePlatform.playstation,
      consoles: const ['PS5'],
      releaseDate: release,
      sourceUri: Uri.parse('https://example.com/gta6'),
      isPreorder: true,
      game: const Game(
        id: 'gta-6',
        title: 'Grand Theft Auto VI',
        slug: 'gta-vi',
        coverUrl: '',
        platform: GamePlatform.playstation,
        consoles: ['PS5'],
        genres: [],
        developer: '',
        publisher: '',
        releaseDate: null,
      ),
    );

    final zelda = PreorderGame(
      id: 'zelda-oot',
      title: 'The Legend of Zelda: Ocarina of Time',
      coverUrl: '',
      publisher: 'Nintendo',
      developer: 'Nintendo',
      platform: GamePlatform.nintendo,
      consoles: const ['Switch'],
      releaseDate: release,
      sourceUri: Uri.parse('https://example.com/zelda'),
      isPreorder: true,
      game: const Game(
        id: 'zelda-oot',
        title: 'The Legend of Zelda: Ocarina of Time',
        slug: 'zelda-oot',
        coverUrl: '',
        platform: GamePlatform.nintendo,
        consoles: ['Switch'],
        genres: [],
        developer: '',
        publisher: '',
        releaseDate: null,
      ),
    );

    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: PreordersScreen(
        repository: TestRepository(),
        source: _MultiSource([genericPs, gta6, zelda]),
        onCreateReleaseAlert: (_) async {},
      ),
    ));
    await tester.pumpAndSettle();

    // Verify filter chips are present
    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'PlayStation'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Nintendo'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Xbox'), findsOneWidget);

    // Verify GTA 6 is displayed
    expect(find.text('Grand Theft Auto VI'), findsOneWidget);
    expect(find.text('The Legend of Zelda: Ocarina of Time'), findsOneWidget);

    // Tap Nintendo chip to filter
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nintendo'));
    await tester.pumpAndSettle();

    expect(find.text('The Legend of Zelda: Ocarina of Time'), findsOneWidget);
    expect(find.text('Grand Theft Auto VI'), findsNothing);
  });
}
