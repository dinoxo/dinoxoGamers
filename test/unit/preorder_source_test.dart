import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/preorder_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String detail(String title,
        {String platforms = 'Nintendo Switch',
        String dates = 'October  2, 2026'}) =>
    '''
<html><head><meta property="og:image" content="https://cdn.dekudeals.com/cover.jpg"></head>
<body><h1>$title</h1><ul>
<li class="list-group-item"><strong>Platforms:</strong> $platforms</li>
<li class="list-group-item"><strong>Release date:</strong> $dates</li>
<li class="list-group-item"><strong>Publisher:</strong> Example Games</li>
</ul></body></html>
''';

void main() {
  test('dates are chosen for each US console despite extra spaces', () {
    final body = detail('New Adventure',
        platforms: 'PlayStation 5, Xbox Series X|S',
        dates: '<ul><li><strong>Steam</strong><br>September 30, 2026</li>'
            '<li><strong>PS5</strong><br>October  2, 2026</li>'
            '<li><strong>Xbox X|S</strong><br>October 5, 2026</li></ul>');
    final games = PreorderSource.parseDetail(
        body,
        Uri.parse('https://www.dekudeals.com/items/new-adventure?country=us'),
        DateTime.utc(2026, 9, 30));
    expect(games.map((g) => g.platform).toSet(),
        {GamePlatform.playstation, GamePlatform.xbox});
    expect(
        games
            .singleWhere((g) => g.platform == GamePlatform.playstation)
            .releaseDate,
        DateTime.utc(2026, 10, 2));
    expect(
        games.singleWhere((g) => g.platform == GamePlatform.xbox).releaseDate,
        DateTime.utc(2026, 10, 5));
    expect(games.every((g) => g.publisher == 'Example Games'), isTrue);
  });

  test('all-index pagination never skips a release and is fetched once',
      () async {
    var indexRequests = 0;
    final client = MockClient((request) async {
      expect(request.url.queryParameters['country'], 'us');
      if (request.url.path == '/upcoming-releases') {
        indexRequests++;
        expect(request.url.queryParameters['page_size'], 'all');
        return http.Response(
            '<html><body>${List.generate(13, (i) => '<a class="main-link" href="/items/game-$i"><h6>Game $i</h6></a>').join()}</body></html>',
            200);
      }
      final title =
          request.url.pathSegments.last.replaceFirst('game-', 'Game ');
      return http.Response(detail(title), 200);
    });
    final source = PreorderSource(client: client);
    addTearDown(source.close);
    final first = await source.fetchPage();
    final second = await source.fetchPage(page: 2);
    expect(first.games.length, 12);
    expect(first.hasMore, isTrue);
    expect(second.games.length, 1);
    expect(second.hasMore, isFalse);
    expect(
        {
          ...first.games.map((g) => g.title),
          ...second.games.map((g) => g.title)
        }.length,
        13);
    expect(indexRequests, 1);
    final suggestions = await source.autocomplete('Game 12');
    expect(suggestions, ['Game 12']);
    expect(indexRequests, 1);
  });

  test('a date for another store does not invent an undated console release',
      () {
    final body = detail('New Adventure',
        platforms: 'PlayStation 5, Xbox Series X|S',
        dates: '<ul><li><strong>PS5</strong><br>October 2, 2026</li>'
            '<li><strong>Steam</strong><br>October 3, 2026</li></ul>');
    final games = PreorderSource.parseDetail(
        body,
        Uri.parse('https://www.dekudeals.com/items/new-adventure?country=us'),
        DateTime.utc(2026, 9, 30));
    expect(games.map((g) => g.platform), [GamePlatform.playstation]);
  });

  test('add-ons and non-US detail links are not preorders', () {
    final addon = PreorderSource.parseDetail(
        detail('New Adventure Costume Set'),
        Uri.parse('https://www.dekudeals.com/items/costumes?country=us'),
        DateTime.utc(2026, 9, 30));
    final foreign = PreorderSource.parseDetail(
        detail('New Adventure'),
        Uri.parse('https://www.dekudeals.com/items/new-adventure?country=ca'),
        DateTime.utc(2026, 9, 30));
    expect(addon, isEmpty);
    expect(foreign, isEmpty);
  });
}
