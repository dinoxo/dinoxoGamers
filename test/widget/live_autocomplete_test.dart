import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/ui/features/deals/deals_screen.dart';
import 'package:dinoxo_gamers/ui/features/search/search_screen.dart';
import '../fixtures/catalog_html.dart';
import '../fixtures/test_repository.dart';

class _CatalogRepo extends TestRepository {
  final searched = <String>[];
  final dealSearches = <String>[];
  final platforms = <GamePlatform?>[];
  Completer<LiveCatalogPage>? pendingOldDeal;

  @override
  Future<List<String>> fetchAutocomplete(String query,
      {GamePlatform? platform}) async {
    platforms.add(platform);
    return query.toLowerCase().contains('ghost')
        ? ['Ghost of Tsushima', 'Ghost of Tsushima DIRECTOR’S CUT']
        : ['Hades'];
  }

  @override
  Future<LiveCatalogPage> searchOnline(String query,
      {GamePlatform? platform, int page = 1}) async {
    searched.add(query);
    return const LiveCatalogPage([]);
  }

  @override
  Future<LiveCatalogPage> searchLiveDeals(String query,
      {GamePlatform? platform, int page = 1}) async {
    dealSearches.add(query);
    if (query == 'old') return (pendingOldDeal = Completer()).future;
    return LiveCatalogPage(LiveWebScraperService.parseItem(
        offerHtml(title: 'Hades'),
        Uri.parse('https://www.dekudeals.com/items/hades?country=us'),
        DateTime.utc(2026, 9, 30)));
  }
}

void main() {
  testWidgets('Buscar shows live titles and searches the selected suggestion',
      (tester) async {
    final repo = _CatalogRepo();
    await tester.pumpWidget(MaterialApp(home: SearchScreen(repository: repo)));
    await tester.enterText(find.byType(TextField), 'ghost');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Ghost of Tsushima DIRECTOR’S CUT'), findsOneWidget);
    await tester.tap(find.text('Ghost of Tsushima DIRECTOR’S CUT'));
    await tester.pumpAndSettle();
    expect(repo.searched, contains('Ghost of Tsushima DIRECTOR’S CUT'));
  });

  testWidgets('Ofertas queries the live catalog beyond initially loaded cards',
      (tester) async {
    final repo = _CatalogRepo();
    await tester.pumpWidget(MaterialApp(home: DealsScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Hades');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(repo.dealSearches, contains('Hades'));
    expect(find.text('Hades'), findsWidgets);
  });

  testWidgets('late offer results cannot replace a newer search',
      (tester) async {
    final repo = _CatalogRepo();
    await tester.pumpWidget(MaterialApp(home: DealsScreen(repository: repo)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 500));
    expect(repo.pendingOldDeal, isNotNull);
    await tester.enterText(find.byType(TextField), 'Hades');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    repo.pendingOldDeal!.complete(const LiveCatalogPage([]));
    await tester.pumpAndSettle();
    expect(find.text('Hades'), findsWidgets);
  });
}
