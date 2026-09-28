import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/ui/features/search/search_screen.dart';
import 'package:dinoxo_gamers/ui/core/widgets/deal_card.dart';
import 'package:dinoxo_gamers/ui/features/game_details/game_details_screen.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../fixtures/test_repository.dart';

class _Repo extends TestRepository {
  String? searched;
  List<Game> results = [];
  bool hasMore = false;
  List<String> warnings = [];
  @override
  Future<LiveCatalogPage> searchOnline(String query,
      {GamePlatform? platform, int page = 1}) async {
    searched = query;
    return LiveCatalogPage(results, hasMore: hasMore, warnings: warnings);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  testWidgets('a failed edition prevents automatic photo navigation',
      (tester) async {
    final repo = _Repo()
      ..warnings = ['Una ficha no se pudo consultar.']
      ..results = [
        const Game(
            id: 'ghost_ps4',
            title: 'Ghost of Tsushima',
            slug: 'ghost',
            coverUrl: '',
            platform: GamePlatform.playstation,
            consoles: ['PS4'],
            genres: [],
            developer: '',
            publisher: '',
            releaseDate: null)
      ];
    await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
            repository: repo,
            pickPhoto: (_) async => XFile('/gallery/game.jpg'),
            readPhoto: (_) async => ['Ghost of Tsushima'])));
    await tester.tap(find.byTooltip('Leer título de una imagen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar en la web'));
    await tester.pumpAndSettle();
    expect(find.byType(GameDetailsScreen), findsNothing);
    expect(find.text('Una ficha no se pudo consultar.'), findsOneWidget);
  });
  testWidgets(
      'a partial first page cannot auto-open an apparently unique photo match',
      (tester) async {
    final repo = _Repo()
      ..hasMore = true
      ..results = [
        const Game(
            id: 'ghost_ps4',
            title: 'Ghost of Tsushima',
            slug: 'ghost',
            coverUrl: '',
            platform: GamePlatform.playstation,
            consoles: ['PS4'],
            genres: [],
            developer: '',
            publisher: '',
            releaseDate: null)
      ];
    await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
            repository: repo,
            pickPhoto: (_) async => XFile('/gallery/game.jpg'),
            readPhoto: (_) async => ['Ghost of Tsushima'])));
    await tester.tap(find.byTooltip('Leer título de una imagen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar en la web'));
    await tester.pumpAndSettle();
    expect(find.byType(GameDetailsScreen), findsNothing);
    expect(find.text('Cargar más resultados'), findsOneWidget);
  });
  testWidgets(
      'ambiguous editions stay as results instead of opening the first game',
      (tester) async {
    final repo = _Repo()
      ..results = [
        for (final console in ['PS4', 'PS5'])
          Game(
              id: 'ghost_$console',
              title: "Ghost of Tsushima DIRECTOR'S CUT",
              slug: 'ghost',
              coverUrl: '',
              platform: GamePlatform.playstation,
              consoles: [console],
              genres: [],
              developer: '',
              publisher: '',
              releaseDate: null),
      ];
    await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
            repository: repo,
            pickPhoto: (_) async => XFile('/camera/game.jpg'),
            readPhoto: (_) async => ["Ghost of Tsushima DIRECTOR'S CUT"])));
    await tester.tap(find.byTooltip('Leer título con la cámara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar en la web'));
    await tester.pumpAndSettle();
    expect(repo.searched, "Ghost of Tsushima DIRECTOR'S CUT");
    expect(find.byType(GameDetailsScreen), findsNothing);
    expect(
        find.descendant(
            of: find.byType(DealCard),
            matching: find.text("Ghost of Tsushima DIRECTOR'S CUT")),
        findsNWidgets(2));
  });
  testWidgets('a unique confirmed photo title opens that game details',
      (tester) async {
    final repo = _Repo()
      ..results = [
        const Game(
            id: 'photo_ghost',
            title: "Ghost of Tsushima DIRECTOR'S CUT",
            slug: 'ghost',
            coverUrl: '',
            platform: GamePlatform.playstation,
            consoles: ['PS5'],
            genres: [],
            developer: '',
            publisher: '',
            releaseDate: null)
      ];
    await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
            repository: repo,
            pickPhoto: (_) async => XFile('/gallery/game.jpg'),
            readPhoto: (_) async => ["Ghost of Tsushima DIRECTOR'S CUT"])));
    await tester.tap(find.byTooltip('Leer título de una imagen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar en la web'));
    await tester.pumpAndSettle();
    expect(find.byType(GameDetailsScreen), findsOneWidget);
  });
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
