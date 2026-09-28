import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../fixtures/catalog_html.dart';

void main() {
  test('missing page identity cannot assign any page artwork to analytics rows',
      () {
    final body =
        '''<meta property="og:image" content="https://example.com/zelda.jpg">
      ${offerHtml(title: "Ghost of Tsushima DIRECTOR'S CUT", includeTitle: false)}''';
    final games = LiveWebScraperService.parseItem(
        body,
        Uri.parse('https://www.dekudeals.com/items/unknown?country=us'),
        DateTime(2026, 9, 28));
    expect(games, isEmpty);
  });
  test(
      'refreshing a legacy wrong source cannot replace Ghost with another PS game',
      () async {
    final uri = Uri.parse('https://www.dekudeals.com/items/spider?country=us');
    final ghost = LiveWebScraperService.parseItem(
            '<h1>Ghost of Tsushima</h1>${offerHtml(title: 'Ghost of Tsushima')}',
            uri,
            DateTime(2026, 9, 28))
        .single;
    final source = LiveWebScraperService(
        client: MockClient((request) async => request.method == 'POST'
            ? http.Response('', 303,
                headers: {'set-cookie': 'rack.session=test;'})
            : http.Response(
                '<h1>Spider-Man</h1>${offerHtml(title: 'Spider-Man', key: 'playstation_us:SPIDER')}',
                200)));
    expect(() => source.fetchGame(ghost), throwsA(isA<CatalogException>()));
  });
  test('a related-game offer cannot inherit another game artwork or review',
      () {
    final body = '''<h1>The Legend of Zelda: Breath of the Wild</h1>
      <meta property="og:image" content="https://assets.nintendo.com/zelda-cover.jpg">
      ${offerHtml(title: "Ghost of Tsushima DIRECTOR'S CUT")}
      ${offerHtml(key: 'eshop:ZELDA', affiliation: 'eshop', category: 'switch', title: 'The Legend of Zelda: Breath of the Wild', url: 'https://www.nintendo.com/us/store/products/zelda/')}''';
    final games = LiveWebScraperService.parseItem(
        body,
        Uri.parse('https://www.dekudeals.com/items/zelda?country=us'),
        DateTime(2026, 9, 28));
    expect(games.any((game) => game.title.contains('Ghost')), false);
    expect(games.single.title, 'The Legend of Zelda: Breath of the Wild');
  });
}
