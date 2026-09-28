import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/core/theme/app_theme.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/models/game_edition.dart';
import 'package:dinoxo_gamers/domain/models/user_alert.dart';
import 'package:dinoxo_gamers/ui/features/alerts/alerts_screen.dart';
import 'package:dinoxo_gamers/ui/features/game_details/game_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../fixtures/test_repository.dart';

final _checkedAt = DateTime.utc(2026, 9, 28);

GameEdition _edition(String id, String name, double price) => GameEdition(
      id: id,
      gameId: 'target-game',
      name: name,
      currentPrice: price,
      regularPrice: price,
      discountPercent: 0,
      lowestObservedPrice: price,
      lowestObservedDate: _checkedAt,
      sourceUrl: '',
      officialStoreUrl: '',
      lastChecked: _checkedAt,
    );

final _targetGame = Game(
  id: 'target-game',
  title: 'Saved Game',
  slug: 'saved-game',
  coverUrl: 'https://example.test/saved-game-cover.jpg',
  platform: GamePlatform.playstation,
  consoles: const ['PS5'],
  genres: const [],
  developer: 'Studio',
  publisher: 'Publisher',
  releaseDate: null,
  editions: [
    _edition('standard', 'Estándar', 19.99),
    _edition('deluxe', 'Deluxe', 29.99),
  ],
);

UserAlert _alert(
        {String gameId = 'target-game', String editionId = 'deluxe'}) =>
    UserAlert(
      id: 'saved-alert',
      gameId: gameId,
      editionId: editionId,
      gameTitle: 'Saved Game',
      platform: GamePlatform.playstation,
      editionName: 'Deluxe',
      targetPrice: 14.99,
      createdAt: _checkedAt,
    );

class _AlertRepository extends TestRepository {
  _AlertRepository(this.alert, this.snapshot);

  UserAlert alert;
  final Game? snapshot;

  @override
  Future<List<UserAlert>> getAlerts() async => [alert];

  @override
  Future<Game?> getGameById(String id) async =>
      snapshot?.id == id ? snapshot : null;

  @override
  Future<void> toggleAlertActive(String id, bool isActive) async {
    if (alert.id == id) alert = alert.copyWith(isActive: isActive);
    notifyListeners();
  }
}

Future<void> _showAlerts(WidgetTester tester, _AlertRepository repo) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.darkTheme,
    home: AlertsScreen(repository: repo),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('saved alert shows its own cover and opens the saved edition',
      (tester) async {
    await _showAlerts(tester, _AlertRepository(_alert(), _targetGame));

    final cover = find.byWidgetPredicate((widget) {
      if (widget is! Image) return false;
      final provider = widget.image is ResizeImage
          ? (widget.image as ResizeImage).imageProvider
          : widget.image;
      return provider is NetworkImage &&
          provider.url == 'https://example.test/saved-game-cover.jpg';
    });
    expect(cover, findsOneWidget);
    await tester.tap(find.text('Saved Game'));
    await tester.pumpAndSettle();

    expect(find.byType(GameDetailsScreen), findsOneWidget);
    final selected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .singleWhere((chip) => chip.selected);
    expect((selected.label as Text).data, 'Deluxe (\$29.99)');
    expect(tester.takeException(), isNull);
  });

  testWidgets('view game action opens the alert edition after refreshing',
      (tester) async {
    await _showAlerts(tester, _AlertRepository(_alert(), _targetGame));
    await tester.tap(find.text('Ver Juego'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actualizar precio y reseñas'));
    await tester.pumpAndSettle();

    final selected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .singleWhere((chip) => chip.selected);
    expect((selected.label as Text).data, 'Deluxe (\$29.99)');
  });

  testWidgets(
      'missing snapshot shows neutral cover and explains unavailable game',
      (tester) async {
    await _showAlerts(tester, _AlertRepository(_alert(), null));
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Icon &&
            widget.icon == Icons.sports_esports &&
            widget.size == null),
        findsOneWidget);
    await tester.tap(find.text('Saved Game'));
    await tester.pumpAndSettle();
    expect(find.byType(GameDetailsScreen), findsNothing);
    expect(find.textContaining('Busca de nuevo el juego'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch toggles the alert without opening its game',
      (tester) async {
    await _showAlerts(tester, _AlertRepository(_alert(), _targetGame));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).value, false);
    expect(find.byType(GameDetailsScreen), findsNothing);
  });
}
