import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../domain/models/subscription_item.dart';
import '../../domain/services/subscription_title.dart';

/// Public content used by the official US storefronts. No account or paid key.
class SubscriptionSource {
  SubscriptionSource({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const psPage = 'https://www.playstation.com/en-us/ps-plus/games/';
  static const xboxPage = 'https://www.xbox.com/en-US/xbox-game-pass/games';
  static const nintendoPage =
      'https://www.nintendo.com/us/online/nintendo-switch-online/classic-games/';
  static const genesisPage =
      'https://www.nintendo.com/us/store/products/sega-genesis-nintendo-switch-online-switch/';

  Future<String> _get(String url) async {
    final response =
        await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError('Subscription HTTP ${response.statusCode}');
    }
    return utf8.decode(response.bodyBytes);
  }

  Future<List<SubscriptionItem>> fetch(
      GamePlatform platform, DateTime now) async {
    switch (platform) {
      case GamePlatform.playstation:
        return _playstation(now);
      case GamePlatform.xbox:
        return _xbox(now);
      case GamePlatform.nintendo:
        return _nintendo(now);
    }
  }

  Future<List<SubscriptionItem>> _playstation(DateTime now) async {
    final kinds = {
      'plus-games-list': SubscriptionTier.psExtra,
      'ubisoft-classics-list': SubscriptionTier.psExtra,
      'plus-classics-list': SubscriptionTier.psPremium,
      'plus-monthly-games-list': SubscriptionTier.psEssential,
    };
    final lists = await Future.wait(kinds.entries.map((kind) async {
      final url =
          'https://www.playstation.com/bin/imagic/gameslist?locale=en-us&categoryList=${kind.key}';
      return parsePlaystation(await _get(url), kind.value, now);
    }));
    final catalog = lists.expand((items) => items).toList();
    if (catalog.isEmpty) throw StateError('Empty official PS catalog');
    final announcements = parseAnnouncements(
        await _get('https://blog.playstation.com/category/ps-plus/feed/'),
        GamePlatform.playstation,
        now);
    return mergeAnnouncements(catalog, announcements, now);
  }

  static List<SubscriptionItem> parsePlaystation(
      String body, SubscriptionTier tier, DateTime now) {
    final groups = jsonDecode(body) as List;
    return groups
        .expand((group) => (group['games'] as List? ?? []))
        .where((game) =>
            (game['device'] as List? ?? []).isNotEmpty &&
            !RegExp(r'\b(trial|jump start|currency|coins|demo)\b',
                    caseSensitive: false)
                .hasMatch(game['name'] as String? ?? '') &&
            (game['conceptUrl'] as String? ?? '')
                .startsWith('https://store.playstation.com/en-us/'))
        .map((game) => SubscriptionItem(
              id: 'ps_${tier.name}_${game['productId'] ?? game['conceptId']}',
              title: game['name'] as String,
              platform: GamePlatform.playstation,
              tier: tier,
              status: SubscriptionStatus.included,
              category: tier == SubscriptionTier.psEssential
                  ? SubscriptionCategory.monthly
                  : tier == SubscriptionTier.psPremium
                      ? SubscriptionCategory.classics
                      : SubscriptionCategory.catalog,
              coverUrl: game['imageUrl'] as String? ?? '',
              consoles: (game['device'] as List).cast<String>(),
              officialStoreUrl: game['conceptUrl'] as String,
              sourceUrl: psPage,
              checkedAt: now,
              statusNote: tier == SubscriptionTier.psEssential
                  ? 'Para reclamar durante el periodo mensual; requiere membresía activa.'
                  : 'Catálogo oficial USA verificado.',
            ))
        .toList();
  }

  Future<List<SubscriptionItem>> _xbox(DateTime now) async {
    const tiers = {
      SubscriptionTier.xboxUltimate: [
        '97c6c862-d28a-4907-a3d5-c401f2296a53',
        'cfq7ttc0khs0'
      ],
      SubscriptionTier.xboxStandard: [
        '09a72c0d-c466-426a-9580-b78955d8173a',
        'cfq7ttc0p85b'
      ],
      SubscriptionTier.xboxCore: [
        '34031711-5a70-4196-bab7-45757dc2294e',
        'cfq7ttc0k5dj'
      ],
    };
    final memberships = <String, SubscriptionTier>{};
    // The order selects the lowest verified tier; console context excludes PC-only games.
    for (final entry in tiers.entries) {
      final uri = Uri.https('catalog.gamepass.com', '/sigls/v3', {
        'id': entry.value[0],
        'language': 'en-us',
        'market': 'US',
        'platformContext': 'ConsoleGen8;ConsoleGen9',
        'subscriptionContext': entry.value[1],
      });
      final list = jsonDecode(await _get(uri.toString())) as List;
      for (final item in list.skip(1)) {
        if (item['id'] is String) memberships[item['id'] as String] = entry.key;
      }
    }
    if (memberships.isEmpty) throw StateError('Empty official Xbox catalog');
    final ids = memberships.keys.toList();
    final catalog = <SubscriptionItem>[];
    for (var offset = 0; offset < ids.length; offset += 120) {
      final chunks = <Future<List<SubscriptionItem>>>[];
      for (var i = offset; i < ids.length && i < offset + 120; i += 40) {
        final batch = ids.skip(i).take(40).join(',');
        final uri = Uri.https(
            'displaycatalog.mp.microsoft.com',
            '/v7.0/products',
            {'bigIds': batch, 'market': 'US', 'languages': 'en-us'});
        chunks.add(_get(uri.toString())
            .then((body) => parseXbox(body, memberships, now)));
      }
      catalog.addAll((await Future.wait(chunks)).expand((items) => items));
    }
    if (catalog.isEmpty) throw StateError('Xbox titles not returned');
    final announcements = parseAnnouncements(
        await _get('https://news.xbox.com/en-us/tag/xbox-game-pass/feed/'),
        GamePlatform.xbox,
        now);
    return mergeAnnouncements(catalog, announcements, now);
  }

  static List<SubscriptionItem> parseXbox(
      String body, Map<String, SubscriptionTier> memberships, DateTime now) {
    final products = (jsonDecode(body) as Map)['Products'] as List? ?? [];
    final items = <SubscriptionItem>[];
    for (final product in products) {
      final id = product['ProductId'] as String;
      if (!memberships.containsKey(id) ||
          product['Properties']?['IsDemo'] == true) {
        continue;
      }
      final properties = product['Properties'] as Map? ?? {};
      final consoles =
          ((properties['XboxConsoleGenCompatible'] as List? ?? []) +
                  (properties['XboxConsoleGenOptimized'] as List? ?? []))
              .toSet();
      if (!consoles.any((c) => c == 'ConsoleGen8' || c == 'ConsoleGen9')) {
        continue;
      }
      final localized = (product['LocalizedProperties'] as List).first as Map;
      final images = localized['Images'] as List? ?? [];
      final cover = images
          .where(
              (image) => ['BoxArt', 'Poster'].contains(image['ImagePurpose']))
          .firstOrNull;
      final imageUrl = cover?['Uri'] as String? ?? '';
      items.add(SubscriptionItem(
        id: 'xbox_$id',
        title: localized['ProductTitle'] as String,
        platform: GamePlatform.xbox,
        tier: memberships[id]!,
        status: SubscriptionStatus.included,
        category: SubscriptionCategory.catalog,
        coverUrl: imageUrl.startsWith('//') ? 'https:$imageUrl' : imageUrl,
        consoles: [
          if (consoles.contains('ConsoleGen8')) 'Xbox One',
          if (consoles.contains('ConsoleGen9')) 'Xbox Series X/S'
        ],
        officialStoreUrl: 'https://www.xbox.com/en-us/games/store/-/$id',
        sourceUrl: xboxPage,
        checkedAt: now,
        statusNote: 'Catálogo de consola USA; nivel mínimo verificado.',
      ));
    }
    return items;
  }

  Future<List<SubscriptionItem>> _nintendo(DateTime now) async {
    final catalog = parseNintendo(await _get(nintendoPage), now);
    catalog.addAll(parseGenesis(await _get(genesisPage), now));
    if (catalog.isEmpty) throw StateError('Nintendo catalog not returned');
    final newsBody = await _get('https://www.nintendo.com/us/whatsnew/');
    final data = nextData(newsBody);
    final state =
        data['props']?['pageProps']?['initialApolloState'] as Map? ?? {};
    final candidates = state.values.whereType<Map>().where((article) =>
        RegExp(r'(new update.*nintendo switch online|nintendo classics.*(?:update|added|available|coming|arriv)|games.*(?:added|coming).*nintendo switch online)',
                caseSensitive: false)
            .hasMatch(article['title'] as String? ?? '') &&
        DateTime.tryParse(article['publishDate'] as String? ?? '')
                ?.isAfter(DateTime(now.year, now.month - 1)) ==
            true);
    final announcements = <SubscriptionItem>[];
    for (final article in candidates.take(6)) {
      final url = 'https://www.nintendo.com/us/whatsnew/${article['slug']}/';
      final body = await _get(url);
      final date = DateTime.tryParse(article['publishDate'] as String? ?? '');
      if (date != null) {
        announcements.addAll(parseNintendoNews(body, url, date, now));
      }
    }
    return mergeAnnouncements(catalog, announcements, now);
  }

  static List<SubscriptionItem> parseNintendoNews(
      String body, String url, DateTime publication, DateTime now) {
    final doc = html.parse(body);
    final main = doc.querySelector('main') ?? doc.body!;
    // Nintendo places a generic "News" heading before the article title.
    final title = main.querySelectorAll('h1').map((h) => h.text).join(' ');
    final text = main.text;
    final explicit = RegExp(
            '(?:available|arriv(?:e|ing|es)|added)[^.]{0,80}(?:${_months.join('|')})\\s+\\d{1,2}',
            caseSensitive: false)
        .firstMatch(text);
    final isUpdate =
        RegExp(r'new update.*nintendo switch online', caseSensitive: false)
            .hasMatch(title);
    var start = explicit != null
        ? _date(explicit[0]!, publication.year)
        : isUpdate
            ? publication
            : null;
    if (start == null || publication.isAfter(now)) return [];
    if (publication.month == 12 &&
        start.month == 1 &&
        start.year == publication.year) {
      start = DateTime(publication.year + 1, 1, start.day);
    }
    final result = <SubscriptionItem>[];
    String? console;
    for (final heading in main.querySelectorAll('h2,h3')) {
      final gameTitle = heading.text.trim();
      if (heading.localName == 'h2') {
        console = gameTitle.contains('Super Nintendo') ||
                gameTitle.contains('Super NES')
            ? 'Super NES'
            : gameTitle.contains('Entertainment System')
                ? 'NES'
                : gameTitle.contains('Game Boy Advance')
                    ? 'Game Boy Advance'
                    : gameTitle.contains('Game Boy')
                        ? 'Game Boy'
                        : gameTitle.contains('Nintendo 64')
                            ? 'Nintendo 64'
                            : gameTitle.contains('GameCube')
                                ? 'GameCube'
                                : gameTitle.contains('Genesis')
                                    ? 'SEGA Genesis'
                                    : null;
      } else if (console != null && gameTitle.isNotEmpty) {
        result.add(SubscriptionItem(
            id: 'nso_news_${subscriptionTitleKey(gameTitle)}',
            title: gameTitle,
            platform: GamePlatform.nintendo,
            tier: ['NES', 'Super NES', 'Game Boy'].contains(console)
                ? SubscriptionTier.nsoStandard
                : SubscriptionTier.nsoExpansion,
            status: start.isAfter(now)
                ? SubscriptionStatus.comingSoon
                : SubscriptionStatus.included,
            category: SubscriptionCategory.monthly,
            coverUrl: '',
            consoles: [console],
            sourceUrl: url,
            officialStoreUrl: url,
            checkedAt: now,
            addedAt: start,
            availabilityConfirmed: !start.isAfter(now),
            statusNote: 'Alta anunciada por Nintendo USA · $console'));
      }
    }
    return result;
  }

  static Map<String, dynamic> nextData(String body) {
    final script = html.parse(body).querySelector('script#__NEXT_DATA__');
    if (script == null) throw StateError('Official page data unavailable');
    return jsonDecode(script.text) as Map<String, dynamic>;
  }

  static List<SubscriptionItem> parseGenesis(String body, DateTime now) {
    final doc = html.parse(body);
    final result = <SubscriptionItem>[];
    var included = false;
    for (final element in doc.querySelectorAll('h2,h3,ul')) {
      if (element.localName != 'ul') {
        included = element.text.trim().toLowerCase() == 'included games:';
        continue;
      }
      if (!included) continue;
      for (final li in element.querySelectorAll('li')) {
        final title = li.text.trim();
        if (title.isEmpty) continue;
        result.add(SubscriptionItem(
            id: 'nso_genesis_${subscriptionTitleKey(title)}',
            title: title,
            platform: GamePlatform.nintendo,
            tier: SubscriptionTier.nsoExpansion,
            status: SubscriptionStatus.included,
            category: SubscriptionCategory.classics,
            coverUrl: '',
            consoles: ['SEGA Genesis'],
            sourceUrl: genesisPage,
            officialStoreUrl: genesisPage,
            checkedAt: now,
            statusNote: 'SEGA Genesis · Versión clásica emulada'));
      }
      break;
    }
    if (result.isEmpty) throw StateError('Genesis catalog unavailable');
    return result;
  }

  static List<SubscriptionItem> parseNintendo(String body, DateTime now) {
    final data = nextData(body);
    final games =
        data['props']?['pageProps']?['page']?['classicGamesData'] as Map? ?? {};
    final items = <SubscriptionItem>[];
    for (final entry in games.entries) {
      final expansion = !['NES', 'Super NES', 'Game Boy'].contains(entry.key);
      for (final game in entry.value as List) {
        final title = (game['caption'] ?? game['alt']) as String? ?? '';
        if (title.isEmpty) continue;
        final asset = game['primary']?['assetPath'] as String? ?? '';
        items.add(SubscriptionItem(
          id: 'nso_${game['__entryId']}',
          title: title,
          platform: GamePlatform.nintendo,
          tier: expansion
              ? SubscriptionTier.nsoExpansion
              : SubscriptionTier.nsoStandard,
          status: SubscriptionStatus.included,
          category: SubscriptionCategory.classics,
          coverUrl: asset.isEmpty
              ? ''
              : 'https://assets.nintendo.com/image/upload/${Uri.encodeFull(asset)}',
          consoles: [entry.key as String],
          sourceUrl: nintendoPage,
          officialStoreUrl: nintendoPage,
          checkedAt: now,
          statusNote:
              '${entry.key} · Versión clásica emulada${entry.key == 'GameCube' ? ' · Solo Switch 2' : ''}',
        ));
      }
    }
    return items;
  }

  static List<SubscriptionItem> mergeAnnouncements(
      List<SubscriptionItem> catalog,
      List<SubscriptionItem> announcements,
      DateTime now) {
    final result = [...catalog];
    for (final announcement in announcements) {
      final start = announcement.addedAt;
      if (start == null) continue;
      if (start.isAfter(now)) {
        // An addition to another plan must not erase access available today.
        if (!result.any((item) =>
            item.platform == announcement.platform &&
            item.tier == announcement.tier &&
            item.addedAt == start &&
            subscriptionTitleKey(item.title) ==
                subscriptionTitleKey(announcement.title))) {
          result.add(announcement);
        }
        continue;
      }
      final index = result.indexWhere((item) =>
          item.platform == announcement.platform &&
          item.tier == announcement.tier &&
          (item.platform != GamePlatform.nintendo ||
              item.consoles.any(announcement.consoles.contains)) &&
          subscriptionTitleKey(item.title) ==
              subscriptionTitleKey(announcement.title));
      if (index >= 0) {
        final previous = result[index].addedAt;
        if (previous == null || start.isAfter(previous)) {
          result[index] = result[index].withAnnouncement(announcement);
        }
      } else if (!start.isBefore(DateTime(now.year, now.month))) {
        result.add(announcement);
      }
    }
    return result;
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  static DateTime? _date(String text, int year) {
    final match = RegExp(
            '(${_months.join('|')})\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,?\\s+(20\\d{2}))?',
            caseSensitive: false)
        .firstMatch(text);
    if (match == null) return null;
    final month =
        _months.indexWhere((m) => m.toLowerCase() == match[1]!.toLowerCase()) +
            1;
    return DateTime(
        int.tryParse(match[3] ?? '') ?? year, month, int.parse(match[2]!));
  }

  static List<SubscriptionItem> parseAnnouncements(
      String feed, GamePlatform platform, DateTime now) {
    final items = <SubscriptionItem>[];
    for (final rss in RegExp(r'<item>([\s\S]*?)</item>').allMatches(feed)) {
      final xml = rss[1]!;
      String tag(String name) =>
          RegExp('<$name>([\\s\\S]*?)</$name>').firstMatch(xml)?[1] ?? '';
      final title = html
              .parseFragment(tag('title')
                  .replaceAll('<![CDATA[', '')
                  .replaceAll(']]>', ''))
              .text ??
          '';
      final valid = platform == GamePlatform.playstation
          ? title.startsWith('PlayStation Plus Monthly Games') ||
              title.startsWith('PlayStation Plus Game Catalog')
          : RegExp(r'^Coming to Xbox Game Pass', caseSensitive: false)
              .hasMatch(title);
      if (!valid) continue;
      final url = tag('link');
      final dateMatch = RegExp(r'/(20\d{2})/(\d{2})/(\d{2})/').firstMatch(url);
      if (dateMatch == null) continue;
      final year = int.parse(dateMatch[1]!);
      final publication =
          DateTime(year, int.parse(dateMatch[2]!), int.parse(dateMatch[3]!));
      if (publication.isBefore(DateTime(now.year, now.month - 1))) continue;
      final body =
          RegExp(r'<content:encoded><!\[CDATA\[([\s\S]*?)\]\]></content:encoded>')
                  .firstMatch(xml)?[1] ??
              '';
      final document = html.parse(body);
      final intro = document.body!.text;
      final isMonthly = title.startsWith('PlayStation Plus Monthly Games');
      final firstGame =
          RegExp(r'\|\s*PS[45]').firstMatch(intro)?.start ?? intro.length;
      final dates = RegExp(
              '(?:${_months.join('|')})\\s+\\d{1,2}(?:st|nd|rd|th)?(?:,?\\s+20\\d{2})?',
              caseSensitive: false)
          .allMatches(intro.substring(0, firstGame.clamp(0, 2000)))
          .toList();
      DateTime? psStart = dates.isEmpty ? null : _date(dates.first[0]!, year);
      if (psStart != null &&
          publication.month == 12 &&
          psStart.month == 1 &&
          psStart.year == year) {
        psStart = DateTime(year + 1, 1, psStart.day);
      }
      DateTime? psEnd = isMonthly && dates.length > 1
          ? _date(dates[1][0]!, psStart?.year ?? year)
              ?.add(const Duration(days: 1))
          : null;
      if (psEnd != null && psStart != null && psEnd.isBefore(psStart)) {
        psEnd = DateTime(psEnd.year + 1, psEnd.month, psEnd.day);
      }
      var tier =
          isMonthly ? SubscriptionTier.psEssential : SubscriptionTier.psExtra;
      String? image;
      for (final element in document.querySelectorAll('h2,h3,p,strong,img')) {
        if (element.localName == 'img') {
          image = element.attributes['src'];
          continue;
        }
        final text = element.text.trim();
        if (platform == GamePlatform.playstation &&
            text.contains('Premium') &&
            text.contains('Classics')) {
          tier = SubscriptionTier.psPremium;
        }
        String gameTitle;
        List<String> consoles;
        DateTime? start;
        if (platform == GamePlatform.playstation) {
          if (element.localName != 'strong' && element.localName != 'h3') {
            continue;
          }
          final parts = text.split('|');
          if (parts.length != 2 || !RegExp(r'PS[45]').hasMatch(parts[1])) {
            continue;
          }
          gameTitle = parts[0].trim();
          consoles = RegExp(r'PS[45]')
              .allMatches(parts[1])
              .map((m) => m[0]!)
              .toSet()
              .toList();
          start = psStart;
        } else {
          if (element.localName != 'strong') continue;
          final match =
              RegExp(r'^(.+?)\s*\(([^)]+)\)\s*[–—-]\s*(.+)$').firstMatch(text);
          if (match == null ||
              !RegExp(r'console|xbox', caseSensitive: false)
                  .hasMatch(match[2]!)) {
            continue;
          }
          gameTitle = match[1]!.trim();
          consoles = [match[2]!];
          start = _date(match[3]!, year);
          if (start != null &&
              publication.month == 12 &&
              start.month == 1 &&
              start.year == year) {
            start = DateTime(year + 1, 1, start.day);
          }
          final parent = element.parent;
          var plans = parent?.text.replaceFirst(text, '').trim() ?? '';
          if (plans.isEmpty) {
            plans = parent?.nextElementSibling?.text.trim() ?? '';
          }
          tier = plans.contains('Game Pass Essential')
              ? SubscriptionTier.xboxCore
              : plans.contains('Game Pass Premium')
                  ? SubscriptionTier.xboxStandard
                  : SubscriptionTier.xboxUltimate;
        }
        if (start == null) continue;
        items.add(SubscriptionItem(
          id: 'announcement_${platform.name}_${subscriptionTitleKey(gameTitle)}_${start.toIso8601String()}',
          title: gameTitle,
          platform: platform,
          tier: tier,
          status: start.isAfter(now)
              ? SubscriptionStatus.comingSoon
              : SubscriptionStatus.included,
          category: SubscriptionCategory.monthly,
          coverUrl: image ?? '',
          consoles: consoles,
          sourceUrl: url,
          officialStoreUrl: url,
          checkedAt: now,
          addedAt: start,
          availableUntil: psEnd,
          availabilityConfirmed: false,
          releaseDate: start.toIso8601String().split('T').first,
          expiryDate: psEnd
              ?.subtract(const Duration(days: 1))
              .toIso8601String()
              .split('T')
              .first,
          statusNote:
              'Alta anunciada oficialmente en USA; consulta el nivel y periodo de acceso.',
        ));
      }
    }
    return {for (final item in items) item.id: item}.values.toList();
  }
}
