import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../domain/models/game.dart';
import '../../domain/models/game_edition.dart';
import '../../domain/models/review_snapshot.dart';

class CatalogException implements Exception {
  final String message;
  const CatalogException(this.message);
  @override
  String toString() => message;
}

class LiveCatalogPage {
  final List<Game> games;
  final bool hasMore;
  final List<String> warnings;
  const LiveCatalogPage(this.games,
      {this.hasMore = false, this.warnings = const []});
}

/// On-demand public pages. No invented fallbacks, paid API or anti-bot bypass.
class LiveWebScraperService {
  final http.Client _client;
  final Map<GamePlatform?, Future<String>> _sessions = {};
  LiveWebScraperService({http.Client? client})
      : _client = client ?? http.Client();
  void close() => _client.close();
  static const host = 'www.dekudeals.com';

  Future<String> _session(GamePlatform? platform) async {
    try {
      return await _sessions.putIfAbsent(
          platform, () => _createSession(platform));
    } catch (_) {
      _sessions.remove(platform);
      rethrow;
    }
  }

  Future<String> _createSession(GamePlatform? platform) async {
    final form = <String, String>{'_method': 'PUT', 'return_to': '/'};
    const consoles = {
      'switch': GamePlatform.nintendo,
      'switch_2': GamePlatform.nintendo,
      'ps5': GamePlatform.playstation,
      'ps4': GamePlatform.playstation,
      'xbox_one': GamePlatform.xbox,
      'xbox_series': GamePlatform.xbox
    };
    for (final entry in consoles.entries) {
      form['platform_${entry.key}'] =
          (platform == null || platform == entry.value).toString();
      form['games_filter_${entry.key}'] = 'digital';
    }
    form['platform_steam'] = 'false';
    final request = http.Request('POST', Uri.https(host, '/platforms'))
      ..followRedirects = false
      ..bodyFields = form;
    final response =
        await _client.send(request).timeout(const Duration(seconds: 15));
    await response.stream.drain<void>();
    if (response.statusCode != 302 && response.statusCode != 303) {
      throw CatalogException(
          'La fuente no permite configurar las consolas (HTTP ${response.statusCode}). Reintenta más tarde.');
    }
    final match = RegExp(r'(?:^|,\s*)(rack\.session=[^;,]+)')
        .firstMatch(response.headers['set-cookie'] ?? '');
    if (match == null) {
      throw const CatalogException(
          'No se pudo confirmar la selección de consolas.');
    }
    return match.group(1)!;
  }

  Future<String> _get(Uri uri, String cookie) async {
    final response = await _client.get(uri, headers: {
      'Cookie': cookie,
      'Accept-Language': 'en-US,en;q=0.8'
    }).timeout(const Duration(seconds: 18));
    if (response.statusCode != 200) {
      throw CatalogException(
          'Fuente web no disponible (HTTP ${response.statusCode}).');
    }
    final text = utf8.decode(response.bodyBytes);
    if (text.contains('Just a moment...')) {
      throw const CatalogException(
          'La fuente solicita verificación en su web.');
    }
    return text;
  }

  Future<LiveCatalogPage> fetchLiveDeals(
      {GamePlatform? platform, int page = 1}) async {
    if (platform != null) {
      return _load('/recent-drops',
          platform: platform, page: page, dealsOnly: true);
    }
    final pages = await Future.wait(GamePlatform.values.map((p) async {
      try {
        return await _load('/recent-drops',
            platform: p, page: page, dealsOnly: true);
      } catch (e) {
        return LiveCatalogPage(const [],
            warnings: ['${AppConstants.platformDisplayName(p)}: $e']);
      }
    }));
    if (pages.every((p) => p.games.isEmpty) &&
        pages.any((p) => p.warnings.isNotEmpty)) {
      throw CatalogException(pages.expand((p) => p.warnings).join('\n'));
    }
    return LiveCatalogPage(
        {for (final g in pages.expand((p) => p.games)) g.id: g}.values.toList(),
        hasMore: pages.any((p) => p.hasMore),
        warnings: pages.expand((p) => p.warnings).toList());
  }

  Future<LiveCatalogPage> searchWebGames(String query,
      {GamePlatform? platform, int page = 1}) async {
    if (query.trim().length < 2) return const LiveCatalogPage([]);
    return _load('/search',
        query: query.trim(), platform: platform, page: page);
  }

  Future<List<Game>> fetchGame(Game game) async {
    final uri = Uri.tryParse(
        game.review?.sourceUrl ?? game.primaryEdition?.sourceUrl ?? '');
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != host ||
        !uri.path.startsWith('/items/') ||
        uri.queryParameters['country'] != 'us') {
      throw const CatalogException(
          'Este juego no tiene una fuente USA consultable. Búscalo de nuevo.');
    }
    final cookie = await _session(game.platform);
    final games =
        parseItem(await _get(uri, cookie), uri, DateTime.now().toUtc())
            .where((g) => g.platform == game.platform)
            .toList();
    if (games.isEmpty) {
      throw const CatalogException(
          'La ficha no contiene datos actuales para esta consola.');
    }
    return games;
  }

  Future<LiveCatalogPage> _load(String path,
      {String? query,
      GamePlatform? platform,
      int page = 1,
      bool dealsOnly = false}) async {
    final cookie = await _session(platform);
    const batchSize = 6;
    final remotePage = (page - 1) ~/ 6 + 1;
    final uri = Uri.https(host, path, {
      'country': 'us',
      if (query != null) 'q': query,
      'page': '$remotePage'
    });
    final document = html.parse(await _get(uri, cookie));
    final links = document
        .querySelectorAll('a.main-link')
        .where((a) => a.querySelector('h6') != null)
        .map((a) => a.attributes['href'] ?? '')
        .where((p) => p.startsWith('/items/'))
        .toSet()
        .toList();
    if (links.isEmpty &&
        document.querySelector('form[action="/search"]') == null) {
      throw const CatalogException(
          'La estructura de la fuente cambió. No se pudieron leer los juegos.');
    }
    final start = ((page - 1) % 6) * batchSize;
    final paths = links.skip(start).take(batchSize).toList();
    final games = <Game>[];
    final warnings = <String>[];
    for (var offset = 0; offset < paths.length; offset += 2) {
      final groups =
          await Future.wait(paths.skip(offset).take(2).map((itemPath) async {
        final source = Uri.https(host, itemPath, {'country': 'us'});
        try {
          final parsed = parseItem(
              await _get(source, cookie), source, DateTime.now().toUtc());
          if (parsed.isEmpty) {
            throw const CatalogException('No se pudo interpretar la ficha.');
          }
          return parsed;
        } catch (_) {
          warnings.add('Una ficha no está disponible.');
          return <Game>[];
        }
      }));
      games.addAll(groups.expand((g) => g).where((g) =>
          (platform == null || g.platform == platform) &&
          (!dealsOnly || g.hasDiscount)));
    }
    if (paths.isNotEmpty && warnings.length == paths.length) {
      throw const CatalogException(
          'No se pudieron consultar los precios de las fichas. Reintenta.');
    }
    final hasNextPage = document
        .querySelectorAll('.pagination li:not(.disabled) a')
        .any((a) =>
            (int.tryParse(Uri.tryParse(a.attributes['href'] ?? '')
                        ?.queryParameters['page'] ??
                    '') ??
                0) >
            remotePage);
    return LiveCatalogPage(games,
        hasMore: start + batchSize < links.length || hasNextPage,
        warnings: warnings.isEmpty
            ? []
            : ['Algunas fichas no se pudieron consultar.']);
  }

  static List<Game> parseItem(String text, Uri source, DateTime checkedAt) {
    if (source.host != host || source.queryParameters['country'] != 'us') {
      return [];
    }
    final doc = html.parse(text);
    String metadata(String label) {
      for (final row in doc.querySelectorAll('li.list-group-item')) {
        if (row.querySelector('strong')?.text.trim() == '$label:') {
          return row.text.trim().substring(label.length + 1).trim();
        }
      }
      return '';
    }

    final cover =
        doc.querySelector('meta[property="og:image"]')?.attributes['content'] ??
            '';
    final reviewLink = doc.querySelector('a.metacritic');
    final scores = reviewLink
            ?.querySelectorAll('span')
            .map((s) => double.tryParse(s.text.trim()))
            .toList() ??
        [];
    final oc = doc.querySelector('a.opencritic');
    String? reviewUrl(String? raw, String domain) {
      final uri = Uri.tryParse(raw ?? '');
      return uri?.scheme == 'https' &&
              (uri!.host == domain || uri.host == 'www.$domain')
          ? raw
          : null;
    }

    double? valid(double? value, double max) =>
        value != null && value >= 0 && value <= max ? value : null;
    final review = ReviewSnapshot(
        criticScore: valid(scores.isEmpty ? null : scores.first, 100),
        userScore: valid(scores.length < 2 ? null : scores[1], 10),
        openCriticScore: valid(double.tryParse(oc?.text.trim() ?? ''), 100),
        metacriticUrl:
            reviewUrl(reviewLink?.attributes['href'], 'metacritic.com'),
        openCriticUrl: reviewUrl(oc?.attributes['href'], 'opencritic.com'),
        sourceUrl: source.toString(),
        checkedAt: checkedAt);
    final results = <String, Game>{};
    const labels = {
      'ps5': 'PS5',
      'ps4': 'PS4',
      'switch': 'Nintendo Switch',
      'switch_2': 'Nintendo Switch 2',
      'xbox_series': 'Xbox Series X|S',
      'xbox_one': 'Xbox One'
    };
    final pattern = RegExp(r'''outAnalytics\['([^']+)'\]\s*=\s*(\{[^\n]+\})''');
    for (final match in pattern.allMatches(text)) {
      try {
        final data = jsonDecode(match.group(2)!) as Map<String, dynamic>;
        if (data['currency'] != 'USD') continue;
        final item = (data['items'] as List).single as Map<String, dynamic>;
        if (item['item_variant'] != 'digital') continue;
        final platform = switch (item['affiliation']) {
          'eshop' => GamePlatform.nintendo,
          'playstation_us' => GamePlatform.playstation,
          'microsoft_us' => GamePlatform.xbox,
          _ => null
        };
        if (platform == null) continue;
        final price = (item['price'] as num).toDouble() / 100;
        final reduction = (item['discount'] as num).toDouble() / 100;
        if (!price.isFinite ||
            price < 0 ||
            !reduction.isFinite ||
            reduction < 0) {
          continue;
        }
        final anchors = doc
            .querySelectorAll('a[data-out-analytics-id]')
            .where(
                (a) => a.attributes['data-out-analytics-id'] == match.group(1))
            .toList();
        if (anchors.isEmpty) continue;
        final row = anchors.first.parent?.parent;
        if (row == null || !row.text.contains(RegExp(r'\$[0-9]'))) continue;
        final official = anchors.first.attributes['href'] ?? '';
        final target = Uri.tryParse(official);
        if (target == null || target.scheme != 'https') continue;
        final usStore = switch (platform) {
          GamePlatform.nintendo =>
            target.host == 'www.nintendo.com' && target.path.startsWith('/us/'),
          GamePlatform.playstation => target.host == 'store.playstation.com' &&
              target.path.startsWith('/en-us/'),
          GamePlatform.xbox => (target.host == 'www.xbox.com' ||
                  target.host == 'www.microsoft.com') &&
              target.path.startsWith('/en-us/'),
        };
        if (!usStore) continue;
        final title = item['item_name'] as String;
        final id = 'deku_${match.group(1)}';
        final consoles = (item['item_category'] as String)
            .split('+')
            .map((c) => labels[c])
            .whereType<String>()
            .toList();
        if (consoles.isEmpty) continue;
        final notes = anchors
            .map((a) => a.text.trim())
            .where((s) => s.startsWith('Sale ends'));
        final edition = GameEdition(
            id: id,
            gameId: id,
            name: title,
            productType: ProductType.unknown,
            currentPrice: price,
            regularPrice: price + reduction,
            discountPercent: price + reduction == 0
                ? 0
                : (reduction / (price + reduction) * 100).round(),
            lowestObservedPrice: price,
            lowestObservedDate: checkedAt,
            sourceUrl: source.toString(),
            officialStoreUrl: official,
            lastChecked: checkedAt,
            promoEndLabel: notes.isEmpty ? null : notes.first);
        results[id] = Game(
            id: id,
            title: title,
            slug: source.pathSegments.last,
            coverUrl: cover,
            platform: platform,
            consoles: consoles,
            genres: metadata('Genre')
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
            developer: metadata('Developer'),
            publisher: metadata('Publisher'),
            releaseDate: null,
            editions: [edition],
            review: review);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      } on StateError {
        continue;
      }
    }
    // A real listing without an offer (e.g. an upcoming game) is not a free game.
    final platformRows = doc
        .querySelectorAll('li.list-group-item')
        .where((e) => e.text.trim().startsWith('Platforms:'));
    final title = doc.querySelector('h1, h2.d-inline')?.text.trim() ?? '';
    final platformText = platformRows.map((e) => e.text).join(' ');
    if (title.isNotEmpty) {
      for (final p in GamePlatform.values) {
        if (results.values.any((g) => g.platform == p)) continue;
        final consoles = switch (p) {
          GamePlatform.playstation => [
              if (platformText.contains('PlayStation 5')) 'PS5',
              if (platformText.contains('PlayStation 4')) 'PS4'
            ],
          GamePlatform.nintendo => [
              if (platformText.contains('Switch 2')) 'Nintendo Switch 2',
              if (RegExp(r'Switch(?! 2)').hasMatch(platformText))
                'Nintendo Switch'
            ],
          GamePlatform.xbox => [
              if (platformText.contains('Xbox Series')) 'Xbox Series X|S',
              if (platformText.contains('Xbox One')) 'Xbox One'
            ],
        };
        if (consoles.isEmpty) continue;
        final id = 'deku_unpriced_${p.name}_${source.pathSegments.last}';
        results[id] = Game(
            id: id,
            title: title,
            slug: source.pathSegments.last,
            coverUrl: cover,
            platform: p,
            consoles: consoles,
            genres: const [],
            developer: '',
            publisher: '',
            releaseDate: null,
            review: review);
      }
    }
    return results.values.toList();
  }
}
