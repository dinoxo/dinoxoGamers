import 'dart:convert';
import 'dart:io';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';

Future<void> main() async {
  final ca = File('build/live-probe/host-ca.pem');
  if (ca.existsSync()) {
    SecurityContext.defaultContext.setTrustedCertificates(ca.path);
  }
  final source = LiveWebScraperService();
  final result = <String, List<Map<String, Object?>>>{};
  try {
    for (final entry in {
      'Ghost of Tsushima': GamePlatform.playstation,
      'The Legend of Zelda Breath of the Wild': GamePlatform.nintendo
    }.entries) {
      final page =
          await source.searchWebGames(entry.key, platform: entry.value);
      if (page.games.isEmpty) {
        throw StateError('No live result for ${entry.key}');
      }
      result[entry.key] = page.games
          .map((g) => {
                'title': g.title,
                'platform': g.platform.name,
                'cover': g.coverUrl,
                'source': g.review?.sourceUrl,
                'price': g.primaryEdition?.currentPrice,
              })
          .toList();
    }
    final ghost = result.values.first
        .map((g) => g['cover'])
        .where((url) => url != '')
        .toSet();
    final zelda = result.values.last
        .map((g) => g['cover'])
        .where((url) => url != '')
        .toSet();
    if (ghost.isEmpty ||
        zelda.isEmpty ||
        ghost.intersection(zelda).isNotEmpty) {
      throw StateError(
          'Artwork must be available and distinct between Ghost and Zelda');
    }
    await Directory('build/live-probe').create(recursive: true);
    await File('build/live-probe/artwork-identity.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(result));
    stdout.writeln(jsonEncode({
      'verified': true,
      'results': {
        for (final entry in result.entries) entry.key: entry.value.length
      },
      'sharedCovers': 0
    }));
  } finally {
    source.close();
  }
}
