import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/local_database_service.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/data/repositories/game_repository.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/models/user_alert.dart';
import '../fixtures/catalog_html.dart';

class _Web extends LiveWebScraperService {
  int cents = 1999;
  DateTime now = DateTime.utc(2026, 9, 26);
  @override
  Future<LiveCatalogPage> searchWebGames(String query,
          {GamePlatform? platform, int page = 1}) async =>
      LiveCatalogPage(LiveWebScraperService.parseItem(
          offerHtml(price: cents),
          Uri.parse('https://www.dekudeals.com/items/example?country=us'),
          now));
}

void main() {
  late Database db;
  late LocalDatabaseService local;
  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
        'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE favorites (game_id TEXT PRIMARY KEY, added_at TEXT NOT NULL)');
    await db.execute(
        '''CREATE TABLE user_alerts (id TEXT PRIMARY KEY, game_id TEXT NOT NULL,
      edition_id TEXT NOT NULL, game_title TEXT NOT NULL, platform TEXT NOT NULL,
      edition_name TEXT NOT NULL, target_price REAL NOT NULL, alert_on_atl INTEGER NOT NULL,
      alert_on_ending INTEGER NOT NULL, is_active INTEGER NOT NULL, created_at TEXT NOT NULL, last_notified_at TEXT)''');
    local = LocalDatabaseService.withDatabase(db);
  });
  tearDown(() async => db.close());

  test('fresh prices replace same IDs and favorites survive repository restart',
      () async {
    final web = _Web();
    final repo = GameRepository(localDb: local, web: web);
    final Game first = (await repo.searchOnline('Example')).games.single;
    await repo.toggleFavorite(first.id);
    web.cents = 1499;
    web.now = web.now.add(const Duration(hours: 1));
    await repo.searchOnline('Example');
    expect((await repo.getGameById(first.id))!.currentPrice, 14.99);
    final restarted = GameRepository(localDb: local);
    final favorite = (await restarted.getFavoriteGames()).single;
    expect(favorite.id, first.id);
    expect(favorite.currentPrice, 14.99);
    expect(favorite.review!.checkedAt, web.now);
    final history =
        await restarted.getPriceHistory(first.primaryEdition!.id, 59.99);
    expect(history.map((o) => o.price), [19.99, 14.99]);
    expect(history.first.recordedAt, DateTime.utc(2026, 9, 26));
    await repo.searchOnline('Example');
    expect(await repo.getPriceHistory(first.id, 59.99), hasLength(2));
  });

  test(
      'alerts use existing SQLite columns and preserve target, toggles and notification time',
      () async {
    final alert = UserAlert(
        id: 'a',
        gameId: 'game',
        editionId: 'edition',
        gameTitle: 'Example',
        platform: GamePlatform.xbox,
        editionName: 'Example',
        targetPrice: 2.99,
        alertOnAllTimeLow: false,
        createdAt: DateTime.utc(2026, 9, 26));
    await local.saveAlert(alert);
    expect((await local.getAlerts()).single.targetPrice, 2.99);
    expect((await local.getAlerts()).single.platform, GamePlatform.xbox);
    await local.toggleAlertActive('a', false);
    expect((await local.getAlerts()).single.isActive, false);
    final stamp = DateTime.utc(2026, 9, 27);
    await local.saveAlert(alert.copyWith(lastNotifiedAt: stamp));
    expect((await local.getAlerts()).single.lastNotifiedAt, stamp);
    await local.deleteAlert('a');
    expect(await local.getAlerts(), isEmpty);
  });
}
