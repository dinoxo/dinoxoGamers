import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/domain/models/user_alert.dart';
import 'package:dinoxo_gamers/ui/features/alerts/create_price_alert_sheet.dart';
import '../fixtures/catalog_html.dart';
import '../fixtures/test_repository.dart';

class _Repo extends TestRepository {
  UserAlert? saved;
  @override
  Future<void> saveAlert(UserAlert alert) async {
    saved = alert;
    notifyListeners();
  }

  @override
  Future<List<String>> refreshAlertPrices() async => [];
}

void main() {
  test(
      'decimal amounts accept comma, cents and free targets, reject invalid values',
      () {
    expect(parseAlertPrice('9,99'), 9.99);
    expect(parseAlertPrice('0'), 0);
    expect(parseAlertPrice('-1'), isNull);
    expect(parseAlertPrice('NaN'), isNull);
    expect(parseAlertPrice('1.234'), isNull);
  });
  testWidgets(
      'exact price persists even when notification permission is denied',
      (tester) async {
    final repo = _Repo();
    final game = LiveWebScraperService.parseItem(
            offerHtml(price: 1999),
            Uri.parse('https://www.dekudeals.com/items/test?country=us'),
            DateTime.now())
        .single;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showModalBottomSheet<String>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => CreatePriceAlertSheet(
                            game: game,
                            edition: game.primaryEdition!,
                            repository: repo,
                            requestPermission: () async => false)),
                    child: const Text('Crear'))))));
    await tester.tap(find.text('Crear'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('alert-target-price')), '7,43');
    await tester.tap(find.text('Guardar Alerta'));
    await tester.pumpAndSettle();
    expect(repo.saved!.targetPrice, 7.43);
    expect(repo.saved!.editionId, game.primaryEdition!.id);
    expect(repo.saved!.isActive, true);
  });
}
