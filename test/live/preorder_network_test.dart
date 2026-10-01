import 'package:dinoxo_gamers/data/datasources/preorder_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public US upcoming list yields verified console releases', () async {
    final source = PreorderSource();
    addTearDown(source.close);
    final page = await source.fetchPage();
    expect(page.games, isNotEmpty);
    expect(
        page.games.every((game) =>
            game.title.isNotEmpty &&
            game.sourceUri.host == 'www.dekudeals.com' &&
            game.sourceUri.queryParameters['country'] == 'us'),
        isTrue);
  },
      skip: !const bool.fromEnvironment('LIVE_PREORDER_PROBE'),
      timeout: const Timeout(Duration(minutes: 2)));
}
