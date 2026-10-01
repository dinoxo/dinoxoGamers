import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/local_database_service.dart';
import 'package:dinoxo_gamers/domain/models/release_alert.dart';
import 'package:dinoxo_gamers/domain/services/notification_service.dart';

void main() {
  test('release countdown uses calendar days across month boundaries', () {
    final alert = ReleaseAlert(
        id: 'r1',
        gameTitle: 'New Game',
        platform: GamePlatform.nintendo,
        coverUrl: '',
        sourceUrl: '',
        releaseDate: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 9, 20));
    expect(alert.daysRemaining(DateTime(2026, 9, 30, 23, 59)), 1);
    expect(alert.daysRemaining(DateTime(2026, 10, 1, 0, 1)), 0);
    expect(
        NotificationService.releaseNotificationTime(alert.releaseDate,
            dayBefore: true),
        DateTime(2026, 9, 30, 9));
    expect(
        NotificationService.releaseNotificationTime(alert.releaseDate,
            dayBefore: false),
        DateTime(2026, 10, 1, 9));
  });

  test('opening version one database preserves price alerts and adds releases',
      () async {
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
    final file =
        File('${Directory.current.path}/build/release-alert-migrate.db');
    await file.parent.create(recursive: true);
    if (await file.exists()) await file.delete();
    final old = await ffi.databaseFactoryFfi.openDatabase(file.path,
        options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await db.execute('''CREATE TABLE user_alerts (
        id TEXT PRIMARY KEY, game_id TEXT NOT NULL, edition_id TEXT NOT NULL,
        game_title TEXT NOT NULL, platform TEXT NOT NULL,
        edition_name TEXT NOT NULL, target_price REAL NOT NULL,
        alert_on_atl INTEGER NOT NULL, alert_on_ending INTEGER NOT NULL,
        is_active INTEGER NOT NULL, created_at TEXT NOT NULL,
        last_notified_at TEXT)''');
            }));
    await old.insert('user_alerts', {
      'id': 'price-1',
      'game_id': 'g',
      'edition_id': 'e',
      'game_title': 'Old Game',
      'platform': 'xbox',
      'edition_name': 'Standard',
      'target_price': 9.99,
      'alert_on_atl': 1,
      'alert_on_ending': 0,
      'is_active': 1,
      'created_at': '2026-09-01T00:00:00.000',
      'last_notified_at': null,
    });
    await old.close();
    final local = LocalDatabaseService.withPath(file.path);
    final release = ReleaseAlert(
        id: 'release-1',
        gameTitle: 'New Game',
        platform: GamePlatform.playstation,
        coverUrl: 'https://example.com/c.jpg',
        sourceUrl: 'https://www.dekudeals.com/items/new-game',
        releaseDate: DateTime(2026, 11, 2),
        createdAt: DateTime(2026, 9, 30));
    try {
      expect((await local.getAlerts()).single.targetPrice, 9.99);
      await local.saveReleaseAlert(release);
      expect((await local.getReleaseAlerts()).single.gameTitle, 'New Game');
      expect((await local.getAlerts()).single.gameTitle, 'Old Game');
    } finally {
      await (await local.database).close();
      await ffi.databaseFactoryFfi.deleteDatabase(file.path);
    }
  });
}
