import 'dart:convert';
import 'dart:isolate';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/models/preorder_game.dart';
import 'web_scraper_service.dart';

class PreorderPage {
  const PreorderPage(this.games, {this.hasMore = false});
  final List<PreorderGame> games;
  final bool hasMore;
}

class _UpcomingListing {
  const _UpcomingListing(this.entries);
  final List<_UpcomingEntry> entries;
}

class _UpcomingEntry {
  const _UpcomingEntry(this.path, this.title);
  final String path;
  final String title;
}

class _IndexTask {
  const _IndexTask(this.body);
  final String body;
  _UpcomingListing call() => PreorderSource._parseListing(body);
}

class _DetailTask {
  const _DetailTask(this.body, this.uri, this.checkedAt);
  final String body;
  final Uri uri;
  final DateTime checkedAt;
  List<PreorderGame> call() => PreorderSource.parseDetail(body, uri, checkedAt);
}

/// Reads only Deku Deals' US upcoming list and verifies each product page.
class PreorderSource {
  PreorderSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _host = LiveWebScraperService.host;
  Future<_UpcomingListing>? _indexFuture;
  DateTime? _indexFetchedAt;
  final Map<String, Future<List<PreorderGame>>> _detailCache = {};

  void close() => _client.close();

  Future<String> _get(Uri uri) async {
    final response = await _client.get(uri, headers: {
      'Accept-Language': 'en-US,en;q=0.9',
      'User-Agent': 'Mozilla/5.0 DinoxoGamers/1.0',
    }).timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw CatalogException(
          'La lista de preventas no está disponible (${response.statusCode}).');
    }
    return utf8.decode(response.bodyBytes);
  }

  static _UpcomingListing _parseListing(String body) {
    final doc = html.parse(body);
    final entries = <_UpcomingEntry>[];
    final seen = <String>{};
    for (final anchor in doc.querySelectorAll('a.main-link')) {
      final path = anchor.attributes['href'] ?? '';
      final title = anchor.querySelector('h6')?.text.trim() ?? '';
      if (path.startsWith('/items/') &&
          title.isNotEmpty &&
          !_looksLikeAddOn(title) &&
          seen.add(path)) {
        entries.add(_UpcomingEntry(path, title));
      }
    }
    if (entries.isEmpty) {
      throw const CatalogException(
          'No se pudo leer la lista de próximos lanzamientos.');
    }
    return _UpcomingListing(entries);
  }

  Future<_UpcomingListing> _index() async {
    final now = DateTime.now();
    if (_indexFuture != null &&
        _indexFetchedAt != null &&
        now.difference(_indexFetchedAt!) < const Duration(minutes: 10)) {
      return _indexFuture!;
    }
    _detailCache.clear();
    _indexFetchedAt = now;
    final pending = () async {
      final body = await _get(Uri.https(_host, '/upcoming-releases', {
        'country': 'us',
        'page_size': 'all',
      }));
      return Isolate.run(_IndexTask(body).call);
    }();
    _indexFuture = pending;
    try {
      return await pending;
    } catch (_) {
      _indexFuture = null;
      _indexFetchedAt = null;
      rethrow;
    }
  }

  Future<PreorderPage> fetchPage({int page = 1}) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    final entries = (await _index()).entries;
    final start = (page - 1) * 12;
    if (start >= entries.length) return const PreorderPage([]);
    final games = await _loadPaths(
        entries.skip(start).take(12).map((e) => e.path).toList());
    return PreorderPage(games, hasMore: start + 12 < entries.length);
  }

  /// Suggestions come from the complete upcoming list, never generic search.
  Future<List<String>> autocomplete(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.length < 2) return const [];
    final paths = (await _index())
        .entries
        .where((entry) => entry.title.toLowerCase().contains(clean))
        .take(16)
        .map((entry) => entry.path)
        .toList();
    final verified = await _loadPaths(paths);
    return verified.map((game) => game.title).toSet().take(8).toList();
  }

  Future<PreorderPage> search(String query, {int page = 1}) async {
    final clean = query.trim().toLowerCase();
    if (clean.length < 2) return const PreorderPage([]);
    if (page < 1) throw ArgumentError.value(page, 'page');
    final matches = (await _index())
        .entries
        .where((entry) => entry.title.toLowerCase().contains(clean))
        .toList();
    final start = (page - 1) * 12;
    if (start >= matches.length) return const PreorderPage([]);
    final paths = matches.skip(start).take(12).map((e) => e.path).toList();
    return PreorderPage(await _loadPaths(paths),
        hasMore: start + 12 < matches.length);
  }

  Future<List<PreorderGame>> _loadPaths(List<String> paths) async {
    final results = <PreorderGame>[];
    // Two concurrent product pages keep image-heavy HTML off the UI isolate.
    for (var i = 0; i < paths.length; i += 2) {
      final batch = await Future.wait(paths.skip(i).take(2).map((path) =>
          _detailCache.putIfAbsent(path, () async {
            try {
              final uri = Uri.https(_host, path, {'country': 'us'});
              final body = await _get(uri);
              return Isolate.run(_DetailTask(body, uri, DateTime.now()).call);
            } catch (_) {
              // Do not cache a transient network failure as an empty game.
              _detailCache.remove(path);
              return <PreorderGame>[];
            }
          })));
      results.addAll(batch.expand((games) => games));
    }
    return {for (final game in results) game.id: game}.values.toList();
  }

  static final _exactDate = RegExp(
      r'\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4}\b');

  static bool _looksLikeAddOn(String title) => RegExp(
        r'\b(DLC|expansion pass|season pass|upgrade pack|costume set|character pack|bonus pack|soundtrack|artbook|currency pack|starter pack|battle pass)\b',
        caseSensitive: false,
      ).hasMatch(title);

  static DateTime? _dateIn(String text) {
    final match = _exactDate.firstMatch(text);
    if (match == null) return null;
    try {
      final normalized = match.group(0)!.replaceAll(RegExp(r'\s+'), ' ');
      final parsed = DateFormat('MMMM d, y', 'en_US').parseStrict(normalized);
      return DateTime.utc(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  static bool _groupMatches(String group, GamePlatform platform) {
    final lower = group.toLowerCase();
    return switch (platform) {
      GamePlatform.playstation => lower.contains('ps5') ||
          lower.contains('ps4') ||
          lower.contains('playstation'),
      GamePlatform.nintendo => lower.contains('switch'),
      GamePlatform.xbox => lower.contains('xbox'),
    };
  }

  static DateTime? _releaseFor(dom.Document doc, GamePlatform platform) {
    for (final row in doc.querySelectorAll('li.list-group-item')) {
      if (row.querySelector('strong')?.text.trim() != 'Release date:') continue;
      final groups = row.querySelectorAll('ul > li');
      if (groups.isEmpty) return _dateIn(row.text);
      for (final group in groups) {
        final heading = group.querySelector('strong')?.text ?? '';
        if (_groupMatches(heading, platform)) {
          return _dateIn(group.text.replaceFirst(heading, ''));
        }
      }
    }
    return null;
  }

  static String _metadata(dom.Document doc, String label) {
    for (final row in doc.querySelectorAll('li.list-group-item')) {
      if (row.querySelector('strong')?.text.trim() == '$label:') {
        return row.text.trim().substring(label.length + 1).trim();
      }
    }
    return '';
  }

  static List<PreorderGame> parseDetail(String body, Uri source, DateTime now) {
    if (source.host != _host ||
        source.queryParameters['country'] != 'us' ||
        !source.path.startsWith('/items/')) {
      return const [];
    }
    final parsed = LiveWebScraperService.parseItem(body, source, now);
    if (parsed.isEmpty || _looksLikeAddOn(parsed.first.title)) return const [];
    final doc = html.parse(body);
    final publisher = _metadata(doc, 'Publisher');
    final developer = _metadata(doc, 'Developer');
    final releaseRows = doc.querySelectorAll('li.list-group-item').where(
        (row) => row.querySelector('strong')?.text.trim() == 'Release date:');
    final datedGroups = releaseRows.isEmpty
        ? <dom.Element>[]
        : releaseRows.first.querySelectorAll('ul > li');
    final today = DateTime.utc(now.year, now.month, now.day);
    final games = <PreorderGame>[];
    for (final game in parsed) {
      if (datedGroups.isNotEmpty &&
          !datedGroups.any((group) => _groupMatches(
              group.querySelector('strong')?.text ?? '', game.platform))) {
        continue;
      }
      final date = _releaseFor(doc, game.platform);
      if (date != null && date.isBefore(today)) continue;
      // An undated announced title is allowed, but cannot schedule a reminder.
      games.add(PreorderGame(
        id: game.id,
        title: game.title,
        coverUrl: game.coverUrl,
        publisher: publisher,
        developer: developer,
        platform: game.platform,
        consoles: game.consoles,
        releaseDate: date,
        sourceUri: source,
        isPreorder: date != null && game.editions.isNotEmpty,
        game: game,
      ));
    }
    return games;
  }
}
