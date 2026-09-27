import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';

void main() {
  test('current public responses contain correctly parsed US games', () async {
    final manifest =
        jsonDecode(await File('build/live-probe/manifest.json').readAsString())
            as List;
    expect(manifest.length, greaterThanOrEqualTo(6));
    for (final entry in manifest) {
      final source = Uri.parse(entry['url'] as String);
      final text =
          await File('build/live-probe/${entry['file']}').readAsString();
      final games =
          LiveWebScraperService.parseItem(text, source, DateTime.now().toUtc());
      expect(games, isNotEmpty, reason: source.toString());
      // ignore: avoid_print
      print(jsonEncode({
        'query': entry['query'],
        'games': games
            .map((g) => {
                  'title': g.title,
                  'platform': g.platform.name,
                  'price': g.primaryEdition?.currentPrice,
                  'store': g.primaryEdition?.officialStoreUrl,
                  'critic': g.review?.criticScore,
                })
            .toList()
      }));
    }
  }, skip: !const bool.fromEnvironment('LIVE_CATALOG_PROBE'));
}
