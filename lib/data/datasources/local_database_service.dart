import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/user_alert.dart';
import '../../domain/models/game.dart';
import '../../domain/models/game_edition.dart';
import '../../domain/models/price_observation.dart';
import '../../domain/models/release_alert.dart';

class LocalDatabaseService {
  LocalDatabaseService._();
  LocalDatabaseService.withDatabase(Database database) : _db = database;
  LocalDatabaseService.withPath(String path) : _databasePathOverride = path;
  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _db;
  String? _databasePathOverride;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_db != null) return _db!;
    try {
      _db = await (_opening ??= _initDb());
    } catch (_) {
      _opening = null;
      rethrow;
    }
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = _databasePathOverride ??
        join(await getDatabasesPath(), 'dinoxo_gamers.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // Table: Favorites
        await db.execute('''
          CREATE TABLE favorites (
            game_id TEXT PRIMARY KEY,
            added_at TEXT NOT NULL
          )
        ''');

        // Table: User Alerts
        await db.execute('''
          CREATE TABLE user_alerts (
            id TEXT PRIMARY KEY,
            game_id TEXT NOT NULL,
            edition_id TEXT NOT NULL,
            game_title TEXT NOT NULL,
            platform TEXT NOT NULL,
            edition_name TEXT NOT NULL,
            target_price REAL NOT NULL,
            alert_on_atl INTEGER NOT NULL DEFAULT 1,
            alert_on_ending INTEGER NOT NULL DEFAULT 0,
            is_active INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            last_notified_at TEXT
          )
        ''');

        // Table: Owned Games (Biblioteca)
        await db.execute('''
          CREATE TABLE owned_games (
            game_id TEXT PRIMARY KEY,
            platform TEXT NOT NULL,
            edition_name TEXT NOT NULL,
            acquired_at TEXT NOT NULL
          )
        ''');

        // Table: Settings
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await _createReleaseAlerts(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createReleaseAlerts(db);
      },
    );
  }

  static Future<void> _createReleaseAlerts(DatabaseExecutor db) =>
      db.execute('''
    CREATE TABLE IF NOT EXISTS release_alerts (
      id TEXT PRIMARY KEY,
      game_title TEXT NOT NULL,
      platform TEXT NOT NULL,
      cover_url TEXT NOT NULL,
      source_url TEXT NOT NULL,
      release_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1
    )
  ''');

  Future<List<ReleaseAlert>> getReleaseAlerts() async {
    final rows = await (await database)
        .query('release_alerts', orderBy: 'created_at DESC');
    return rows
        .map((row) => ReleaseAlert(
            id: row['id'] as String,
            gameTitle: row['game_title'] as String,
            platform: GamePlatform.values
                .firstWhere((p) => p.name == row['platform']),
            coverUrl: row['cover_url'] as String,
            sourceUrl: row['source_url'] as String,
            releaseDate: DateTime.parse(row['release_date'] as String),
            createdAt: DateTime.parse(row['created_at'] as String),
            isActive: row['is_active'] == 1))
        .toList();
  }

  Future<void> saveReleaseAlert(ReleaseAlert alert) async {
    await (await database).insert(
        'release_alerts',
        {
          'id': alert.id,
          'game_title': alert.gameTitle,
          'platform': alert.platform.name,
          'cover_url': alert.coverUrl,
          'source_url': alert.sourceUrl,
          'release_date':
              '${alert.releaseDate.year.toString().padLeft(4, '0')}-'
                  '${alert.releaseDate.month.toString().padLeft(2, '0')}-'
                  '${alert.releaseDate.day.toString().padLeft(2, '0')}',
          'created_at': alert.createdAt.toIso8601String(),
          'is_active': alert.isActive ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteReleaseAlert(String id) async {
    await (await database)
        .delete('release_alerts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setReleaseAlertActive(String id, bool active) async {
    await (await database).update(
        'release_alerts', {'is_active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // --- FAVORITES ---
  // Versioned JSON entries in the existing settings table preserve user data.
  Future<void> saveCatalogSnapshot(Game game) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
          'settings',
          {
            'key': 'catalog_v1:${game.id}',
            'value': jsonEncode({
              ...game.toMap(),
              'artworkIdentityVersion': 2,
              'editions': game.editions.map((e) => e.toMap()).toList()
            })
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final edition in game.editions) {
        final key = 'observations_v1:${edition.id}';
        final rows =
            await txn.query('settings', where: 'key = ?', whereArgs: [key]);
        final history = rows.isEmpty
            ? <dynamic>[]
            : jsonDecode(rows.first['value'] as String) as List<dynamic>;
        // Keep changes and daily confirmations; never manufacture past dates.
        if (history.isEmpty ||
            history.last['price'] != edition.currentPrice ||
            DateTime.parse(history.last['recordedAt'] as String)
                    .difference(edition.lastChecked)
                    .abs()
                    .inHours >=
                24) {
          history.add({
            'id': '${edition.id}:${edition.lastChecked.toIso8601String()}',
            'editionId': edition.id,
            'price': edition.currentPrice,
            'recordedAt': edition.lastChecked.toIso8601String(),
            'isDiscounted': edition.hasDiscount
          });
          await txn.insert(
              'settings', {'key': key, 'value': jsonEncode(history)},
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  Future<List<Game>> readCatalogSnapshots() async {
    final db = await database;
    final rows = await db
        .query('settings', where: 'key LIKE ?', whereArgs: ['catalog_v1:%']);
    final games = <Game>[];
    for (final row in rows) {
      try {
        final m = jsonDecode(row['value'] as String) as Map<String, dynamic>;
        // Earlier parsers could attach another product's artwork/review.
        // Keep IDs, favorites, alerts and price history while awaiting a live refresh.
        if (m['artworkIdentityVersion'] != 2) {
          m['coverUrl'] = '';
          m['review'] = null;
        }
        games.add(Game.fromMap(m,
            editions: (m['editions'] as List)
                .map((e) =>
                    GameEdition.fromMap(Map<String, dynamic>.from(e as Map)))
                .toList()));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return games;
  }

  Future<List<PriceObservation>> getObservedPrices(String editionId) async {
    final db = await database;
    final rows = await db.query('settings',
        where: 'key = ?', whereArgs: ['observations_v1:$editionId']);
    if (rows.isEmpty) return [];
    final values = jsonDecode(rows.first['value'] as String) as List;
    return values
        .map((m) => PriceObservation(
            id: m['id'] as String,
            editionId: editionId,
            price: (m['price'] as num).toDouble(),
            recordedAt: DateTime.parse(m['recordedAt'] as String),
            isDiscounted: m['isDiscounted'] == true))
        .toList();
  }

  Future<List<String>> getFavoriteGameIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');
    return maps.map((e) => e['game_id'] as String).toList();
  }

  Future<bool> isFavorite(String gameId) async {
    final db = await database;
    final maps = await db.query('favorites',
        where: 'game_id = ?', whereArgs: [gameId], limit: 1);
    return maps.isNotEmpty;
  }

  Future<void> addFavorite(String gameId) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'game_id': gameId, 'added_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(String gameId) async {
    final db = await database;
    await db.delete('favorites', where: 'game_id = ?', whereArgs: [gameId]);
  }

  // --- ALERTS ---
  Future<List<UserAlert>> getAlerts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('user_alerts', orderBy: 'created_at DESC');
    return maps
        .map((e) => UserAlert.fromMap({
              'id': e['id'],
              'gameId': e['game_id'],
              'editionId': e['edition_id'],
              'gameTitle': e['game_title'],
              'platform': e['platform'],
              'editionName': e['edition_name'],
              'targetPrice': e['target_price'],
              'alertOnAllTimeLow': e['alert_on_atl'],
              'alertOnPromoEnding': e['alert_on_ending'],
              'isActive': e['is_active'],
              'createdAt': e['created_at'],
              'lastNotifiedAt': e['last_notified_at'],
            }))
        .toList();
  }

  Future<void> saveAlert(UserAlert alert) async {
    final db = await database;
    await db.insert(
      'user_alerts',
      {
        'id': alert.id,
        'game_id': alert.gameId,
        'edition_id': alert.editionId,
        'game_title': alert.gameTitle,
        'platform': alert.platform.name,
        'edition_name': alert.editionName,
        'target_price': alert.targetPrice,
        'alert_on_atl': alert.alertOnAllTimeLow ? 1 : 0,
        'alert_on_ending': alert.alertOnPromoEnding ? 1 : 0,
        'is_active': alert.isActive ? 1 : 0,
        'created_at': alert.createdAt.toIso8601String(),
        'last_notified_at': alert.lastNotifiedAt?.toIso8601String()
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAlert(String id) async {
    final db = await database;
    await db.delete('user_alerts', where: 'id = ?', whereArgs: [id]);
  }

  /// Atomic claim shared by foreground and background isolates. A failed
  /// notification releases the claim, so quiet hours/denial can retry later.
  Future<bool> claimNotification(UserAlert alert, DateTime now) async {
    final db = await database;
    final cutoff = now.subtract(const Duration(hours: 24)).toIso8601String();
    final updated = await db.rawUpdate(
        '''UPDATE user_alerts SET last_notified_at = ?
      WHERE id = ? AND is_active = 1 AND target_price = ?
      AND (last_notified_at IS NULL OR last_notified_at <= ?)''',
        [now.toIso8601String(), alert.id, alert.targetPrice, cutoff]);
    return updated == 1;
  }

  Future<void> releaseNotification(UserAlert alert, DateTime claim) async {
    final db = await database;
    await db.update('user_alerts',
        {'last_notified_at': alert.lastNotifiedAt?.toIso8601String()},
        where: 'id = ? AND last_notified_at = ?',
        whereArgs: [alert.id, claim.toIso8601String()]);
  }

  Future<void> toggleAlertActive(String id, bool isActive) async {
    final db = await database;
    await db.update(
      'user_alerts',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- OWNED LIBRARY ---
  Future<List<String>> getOwnedGameIds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('owned_games');
    return maps.map((e) => e['game_id'] as String).toList();
  }

  Future<bool> isGameOwned(String gameId) async {
    final db = await database;
    final maps = await db.query('owned_games',
        where: 'game_id = ?', whereArgs: [gameId], limit: 1);
    return maps.isNotEmpty;
  }

  Future<void> markGameAsOwned(
      String gameId, String platform, String editionName) async {
    final db = await database;
    await db.insert(
      'owned_games',
      {
        'game_id': gameId,
        'platform': platform,
        'edition_name': editionName,
        'acquired_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeGameFromOwned(String gameId) async {
    final db = await database;
    await db.delete('owned_games', where: 'game_id = ?', whereArgs: [gameId]);
  }
}
