import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/ui/features/search/search_screen.dart';
import '../fixtures/test_repository.dart';

class _Repo extends TestRepository {
  String? searched;
  @override
  Future<LiveCatalogPage> searchOnline(String query,
      {GamePlatform? platform, int page = 1}) async {
    searched = query;
    return const LiveCatalogPage([]);
  }
}

void main() {
  testWidgets('gallery text can be corrected and is searched online',
      (tester) async {
    final repo = _Repo();
    await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
            repository: repo,
            pickPhoto: (_) async => XFile('/gallery/game.jpg'),
            readPhoto: (_) async => ['Pokemon Scarlet'])));
    await tester.tap(find.byTooltip('Leer título de una imagen'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, 'Título del juego'), 'Pokémon Scarlet');
    await tester.tap(find.text('Buscar en la web'));
    await tester.pumpAndSettle();
    expect(repo.searched, 'Pokémon Scarlet');
  });
  testWidgets(
      'OCR failure still allows an actual search and does not blame camera permission',
      (tester) async {
    final repo = _Repo();
    await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
            repository: repo,
            pickPhoto: (_) async => XFile('/gallery/game.jpg'),
            readPhoto: (_) async =>
                throw PlatformException(code: 'OCR_FAILED'))));
    await tester.tap(find.byTooltip('Leer título de una imagen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No se pudo reconocer'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Título del juego'), 'Wolverine');
    await tester.tap(find.text('Buscar en la web'));
    await tester.pumpAndSettle();
    expect(repo.searched, 'Wolverine');
  });
}
