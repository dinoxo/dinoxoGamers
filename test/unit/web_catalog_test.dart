import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import '../fixtures/catalog_html.dart';

void main() {
  final source =
      Uri.parse('https://www.dekudeals.com/items/example?country=us');
  final now = DateTime.utc(2026, 9, 26);
  test(
      'parses real cents, discount, source and review scores without inventing history',
      () {
    final games = LiveWebScraperService.parseItem('''${offerHtml()}
      <a class="metacritic" href="https://www.metacritic.com/game/example/"><span>81</span><span>7.2</span></a>
      <a class="opencritic" href="https://opencritic.com/game/123/example">79</a>''',
        source, now);
    final game = games.single;
    expect(game.platform, GamePlatform.playstation);
    expect(game.currentPrice, 19.99);
    expect(game.regularPrice, closeTo(59.99, .001));
    expect(game.discountPercent, 67);
    expect(game.primaryEdition!.lastChecked, now);
    expect(game.primaryEdition!.promoEndLabel, 'Sale ends October 8');
    expect(game.primaryEdition!.promoEndDate, isNull);
    expect(game.isLowestHistorical, false);
    expect(game.primaryEdition!.providerReportedLowest, isNull);
    expect(game.releaseDate, isNull);
    expect(game.review!.criticScore, 81);
    expect(game.review!.userScore, 7.2);
    expect(game.review!.openCriticScore, 79);
  });

  test('separates the three storefronts and consoles with verified US URLs',
      () {
    final games = LiveWebScraperService.parseItem(
        offerHtml() +
            offerHtml(
                key: 'eshop:EXAMPLE',
                affiliation: 'eshop',
                category: 'switch_2',
                url: 'https://www.nintendo.com/us/store/products/example/') +
            offerHtml(
                key: 'microsoft_us:EXAMPLE',
                affiliation: 'microsoft_us',
                category: 'xbox_one+xbox_series',
                url: 'https://www.microsoft.com/en-us/p/example/id'),
        source,
        now);
    expect(games.map((g) => g.platform).toSet(), GamePlatform.values.toSet());
    expect(games[1].consoles, ['Nintendo Switch 2']);
    expect(games[2].consoles, ['Xbox One', 'Xbox Series X|S']);
  });

  test(
      'rejects foreign currency, regions, physical copies, PC and unavailable prices',
      () {
    for (final body in [
      offerHtml(currency: 'CAD'),
      offerHtml(variant: 'physical'),
      offerHtml(affiliation: 'steam'),
      offerHtml(url: 'https://store.playstation.com/en-ca/product/EXAMPLE'),
      offerHtml(price: -1),
      offerHtml(available: false),
      '<h1>Unknown</h1>',
      'broken html'
    ]) {
      expect(LiveWebScraperService.parseItem(body, source, now), isEmpty);
    }
    expect(
        LiveWebScraperService.parseItem(
            offerHtml(), source.replace(query: 'country=ca'), now),
        isEmpty);
  });

  test('catalog listing without a price is not presented as free', () {
    final game = LiveWebScraperService.parseItem('''<h1>Upcoming</h1>
      <li class="list-group-item"><strong>Platforms:</strong> Nintendo Switch 2</li>''',
            source, now)
        .single;
    expect(game.editions, isEmpty);
    expect(game.consoles, ['Nintendo Switch 2']);
    expect(game.review!.criticScore, isNull);
    expect(game.review!.summary, contains('No hay'));
  });

  test(
      'empty search remains empty and sessions select all consoles without Steam',
      () async {
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        expect(request.bodyFields['platform_ps5'], 'true');
        expect(request.bodyFields['platform_switch_2'], 'true');
        expect(request.bodyFields['platform_xbox_series'], 'true');
        expect(request.bodyFields['platform_steam'], 'false');
        return http.Response('', 303,
            headers: {'set-cookie': 'rack.session=test; Path=/; HttpOnly'});
      }
      expect(request.url.queryParameters['q'], 'Pokémon');
      expect(request.url.queryParameters['country'], 'us');
      expect(request.headers['Cookie'], 'rack.session=test');
      return http.Response(listingHtml([]), 200);
    });
    final result =
        await LiveWebScraperService(client: client).searchWebGames(' Pokémon ');
    expect(result.games, isEmpty);
    expect(result.hasMore, false);
  });

  test('HTTP errors never produce fake search results', () async {
    final web = LiveWebScraperService(
        client: MockClient((r) async => r.method == 'POST'
            ? http.Response('', 303,
                headers: {'set-cookie': 'rack.session=test;'})
            : http.Response('Blocked', 403)));
    expect(() => web.searchWebGames('Wolverine'),
        throwsA(isA<CatalogException>()));
  });

  test(
      'one failed edition remains a visible partial search, not a unique match',
      () async {
    final web = LiveWebScraperService(client: MockClient((request) async {
      if (request.method == 'POST') {
        return http.Response('', 303,
            headers: {'set-cookie': 'rack.session=test;'});
      }
      if (request.url.path == '/search') {
        return http.Response(listingHtml(['ghost-ps4', 'ghost-ps5']), 200);
      }
      if (request.url.path.endsWith('ghost-ps5')) {
        return http.Response('Unavailable', 503);
      }
      return http.Response(
          '<h1>Ghost of Tsushima</h1>${offerHtml(title: 'Ghost of Tsushima')}',
          200);
    }));
    addTearDown(web.close);
    final result = await web.searchWebGames('Ghost of Tsushima');
    expect(result.games, hasLength(1));
    expect(result.hasMore, false);
    expect(result.warnings, isNotEmpty);
  });

  test(
      'pagination reaches second source page after six batches, preserving search',
      () async {
    final requests = <Uri>[];
    final web = LiveWebScraperService(client: MockClient((r) async {
      if (r.method == 'POST') {
        return http.Response('', 303,
            headers: {'set-cookie': 'rack.session=test;'});
      }
      requests.add(r.url);
      if (r.url.path == '/search') {
        return http.Response(
            listingHtml(
                List.generate(
                    36, (i) => 'game-${r.url.queryParameters['page']}-$i'),
                nextPage: 2),
            200);
      }
      return http.Response(
          offerHtml(key: 'playstation_us:${r.url.pathSegments.last}'), 200);
    }));
    final last = await web.searchWebGames('Halo', page: 6);
    expect(last.games, hasLength(6));
    expect(last.hasMore, true);
    await web.searchWebGames('Halo', page: 7);
    expect(requests.where((u) => u.path == '/search').last.queryParameters,
        containsPair('page', '2'));
    expect(requests.any((u) => u.path.endsWith('game-1-30')), true);
    expect(requests.any((u) => u.path.endsWith('game-2-0')), true);
  });
}
