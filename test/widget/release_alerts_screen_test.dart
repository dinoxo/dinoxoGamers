import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/domain/models/release_alert.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/ui/features/alerts/alerts_screen.dart';
import 'package:dinoxo_gamers/ui/features/game_details/game_details_screen.dart';
import '../fixtures/test_repository.dart';

class _ReleaseRepo extends TestRepository {
  @override
  Future<LiveCatalogPage> searchOnline(String query,
          {GamePlatform? platform, int page = 1}) async =>
      const LiveCatalogPage([
        Game(
            id: 'live-game',
            title: 'New Adventure',
            slug: 'new-adventure',
            coverUrl: '',
            platform: GamePlatform.nintendo,
            consoles: ['Switch 2'],
            genres: [],
            developer: '',
            releaseDate: null,
            publisher: '')
      ]);

  @override
  Future<List<ReleaseAlert>> getReleaseAlerts() async => [
        ReleaseAlert(
            id: 'r1',
            gameTitle: 'New Adventure',
            platform: GamePlatform.nintendo,
            coverUrl: '',
            sourceUrl: 'https://www.dekudeals.com/items/new-adventure',
            releaseDate: DateTime.now().add(const Duration(days: 5)),
            createdAt: DateTime.now())
      ];
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('Mis Alertas shows a date reminder without a price target',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: AlertsScreen(repository: _ReleaseRepo())));
    await tester.pumpAndSettle();
    expect(find.text('New Adventure'), findsOneWidget);
    expect(find.textContaining('Aviso de lanzamiento'), findsOneWidget);
    expect(find.textContaining('Objetivo:'), findsNothing);
  });
  testWidgets('an upcoming game ficha shows days until its announced date',
      (tester) async {
    final date = DateTime.now().add(const Duration(days: 8));
    await tester.pumpWidget(MaterialApp(
        home: GameDetailsScreen(
            repository: TestRepository(),
            game: Game(
                id: 'upcoming',
                title: 'New Adventure',
                slug: 'new-adventure',
                coverUrl: '',
                platform: GamePlatform.nintendo,
                consoles: const ['Switch 2'],
                genres: const [],
                developer: '',
                publisher: '',
                releaseDate: date))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Faltan'), findsOneWidget);
    expect(
        find.textContaining('fecha anunciada de lanzamiento'), findsOneWidget);
  });
  testWidgets('tapping a release alert opens its fiche with the saved date',
      (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: AlertsScreen(repository: _ReleaseRepo())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Adventure'));
    await tester.pumpAndSettle();
    expect(find.byType(GameDetailsScreen), findsOneWidget);
    expect(
        find.textContaining('fecha anunciada de lanzamiento'), findsOneWidget);
  });
}
