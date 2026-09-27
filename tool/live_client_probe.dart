import 'dart:io';
import 'package:dinoxo_gamers/data/datasources/web_scraper_service.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';

Future<void> main(List<String> args) async {
  final ca = File('build/live-probe/host-ca.pem');
  if (ca.existsSync()) {
    SecurityContext.defaultContext.setTrustedCertificates(ca.path);
  }
  final service = LiveWebScraperService();
  for (final query
      in args.isEmpty ? ['Wolverine', 'pokemon', 'Halo'] : <String>[]) {
    final page = await service.searchWebGames(query);
    if (page.games.isEmpty) throw StateError('No live results: $query');
    stdout.writeln(
        '$query: ${page.games.length} results; ${page.games.map((g) => g.title).join(' | ')}');
  }
  for (final platform in GamePlatform.values) {
    if (args.isNotEmpty && !args.contains(platform.name)) continue;
    final page = await service.fetchLiveDeals(platform: platform);
    if (page.games.any((g) => g.platform != platform || !g.hasDiscount)) {
      throw StateError('Invalid offer or platform');
    }
    stdout.writeln(
        '${platform.name}: ${page.games.length} digital US offers; more=${page.hasMore}; warnings=${page.warnings}');
    for (final g in page.games) {
      stdout.writeln('  ${g.title}: USD ${g.currentPrice}');
    }
  }
  service.close();
}
