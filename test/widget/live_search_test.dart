import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/ui/features/search/search_screen.dart';
import 'package:dinoxo_gamers/ui/features/game_details/game_details_screen.dart';
import '../fixtures/catalog_html.dart';
import '../fixtures/test_repository.dart';

class _SearchRepo extends TestRepository {
  final requests = <String, Completer<LiveCatalogPage>>{};
  @override
  Future<LiveCatalogPage> searchOnline(String query,
          {GamePlatform? platform, int page = 1}) =>
      (requests[query] = Completer<LiveCatalogPage>()).future;
}

void main() {
  testWidgets(
      'late response cannot replace a newer query and clearing cancels UI results',
      (tester) async {
    final repo = _SearchRepo();
    await tester.pumpWidget(MaterialApp(home: SearchScreen(repository: repo)));
    await tester.enterText(find.byType(TextField), 'Wolverine');
    await tester.pump(const Duration(milliseconds: 601));
    expect(repo.requests.containsKey('Wolverine'), true);
    await tester.enterText(find.byType(TextField), 'pokemon');
    await tester.pump(const Duration(milliseconds: 601));
    final source = Uri.parse('https://www.dekudeals.com/items/test?country=us');
    repo.requests['pokemon']!.complete(LiveCatalogPage(
        LiveWebScraperService.parseItem(
            offerHtml(title: 'Pokémon test'), source, DateTime.now())));
    await tester.pumpAndSettle();
    expect(find.text('Pokémon test'), findsOneWidget);
    repo.requests['Wolverine']!.complete(LiveCatalogPage(
        LiveWebScraperService.parseItem(
            offerHtml(title: 'Wolverine test'), source, DateTime.now())));
    await tester.pumpAndSettle();
    expect(find.text('Wolverine test'), findsNothing);
    expect(find.text('Pokémon test'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Pokémon test'), findsNothing);
  });

  testWidgets(
      'failed web search is displayed as failure rather than a false empty catalog',
      (tester) async {
    final repo = _SearchRepo();
    await tester.pumpWidget(MaterialApp(home: SearchScreen(repository: repo)));
    await tester.enterText(find.byType(TextField), 'Wolverine');
    await tester.pump(const Duration(milliseconds: 601));
    repo.requests['Wolverine']!
        .completeError(const CatalogException('HTTP 403'));
    await tester.pumpAndSettle();
    expect(find.text('HTTP 403'), findsOneWidget);
    expect(find.text('Reintentar búsqueda'), findsOneWidget);
  });

  testWidgets('alert dialog accepts games cheaper than five dollars',
      (tester) async {
    final game = LiveWebScraperService.parseItem(
            offerHtml(price: 199),
            Uri.parse('https://www.dekudeals.com/items/test?country=us'),
            DateTime.now())
        .single;
    await tester.pumpWidget(MaterialApp(
        home: GameDetailsScreen(game: game, repository: TestRepository())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear Alerta'));
    await tester.tap(find.text('Crear Alerta'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('alert accepts an exact custom decimal price', (tester) async {
    final game = LiveWebScraperService.parseItem(
            offerHtml(price: 1999),
            Uri.parse('https://www.dekudeals.com/items/test?country=us'),
            DateTime.now())
        .single;
    await tester.pumpWidget(MaterialApp(
        home: GameDetailsScreen(game: game, repository: TestRepository())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Crear Alerta'));
    await tester.tap(find.text('Crear Alerta'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
