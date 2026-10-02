import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/core/theme/app_theme.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/ui/core/widgets/deal_card.dart';
import 'package:dinoxo_gamers/ui/features/deals/deals_screen.dart';
import '../fixtures/catalog_html.dart';
import '../fixtures/test_repository.dart';

class _OffersRepository extends TestRepository {
  @override
  Future<LiveCatalogPage> refreshLiveDeals(
          {GamePlatform? platform, int page = 1}) async =>
      LiveCatalogPage([
        ...LiveWebScraperService.parseItem(
            offerHtml(
                title: 'Expensive',
                key: 'playstation_us:EXPENSIVE',
                price: 4500,
                discount: 500),
            Uri.parse('https://www.dekudeals.com/items/expensive?country=us'),
            DateTime.now()),
        ...LiveWebScraperService.parseItem(
            offerHtml(
                title: 'Cheap',
                key: 'playstation_us:CHEAP',
                price: 900,
                discount: 5100),
            Uri.parse('https://www.dekudeals.com/items/cheap?country=us'),
            DateTime.now()),
      ]);
}

void main() {
  testWidgets('the gaming header fits a phone at double text size',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 700), textScaler: TextScaler.linear(2)),
            child: DealsScreen(repository: TestRepository()))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ofertas Destacadas'), findsOneWidget);
  });
  testWidgets('price and order controls use the fetched offers',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: DealsScreen(repository: _OffersRepository())));
    await tester.pumpAndSettle();
    expect(tester.widgetList<DealCard>(find.byType(DealCard)).first.game.title,
        'Expensive');
    await tester.tap(find.text('Más relevantes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menor precio').last);
    await tester.pumpAndSettle();
    expect(tester.widgetList<DealCard>(find.byType(DealCard)).first.game.title,
        'Cheap');
    await tester.tap(find.text('Cualquier precio').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hasta \$10').last);
    await tester.pumpAndSettle();
    expect(find.text('Expensive'), findsNothing);
    expect(find.text('Cheap'), findsOneWidget);
    await tester.tap(find.text('Hasta \$10').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cualquier precio').last);
    await tester.pumpAndSettle();
    expect(find.text('Expensive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search controls scroll when the keyboard reduces phone space',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.darkTheme,
        home: MediaQuery(
            data: const MediaQueryData(
                size: Size(320, 640), viewInsets: EdgeInsets.only(bottom: 300)),
            child: DealsScreen(repository: _OffersRepository()))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
