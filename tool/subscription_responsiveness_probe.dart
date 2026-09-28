import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/subscription_source.dart';

Future<void> main(List<String> args) async {
  final ca = File('build/live-probe/host-ca.pem');
  if (ca.existsSync()) {
    SecurityContext.defaultContext.setTrustedCertificates(ca.path);
  }
  final watch = Stopwatch()..start();
  var last = 0;
  var largestGap = 0;
  var ticks = 0;
  void sample() {
    final current = watch.elapsedMicroseconds;
    final gap = current - last;
    if (gap > largestGap) largestGap = gap;
    last = current;
    ticks++;
  }

  final timer =
      Timer.periodic(const Duration(milliseconds: 16), (_) => sample());
  final source = SubscriptionSource();
  final counts = <String, int>{};
  final details = <String, dynamic>{};
  try {
    for (final platform in GamePlatform.values) {
      final now = DateTime.now();
      final catalog = await source.fetchCatalog(platform, now);
      counts[platform.name] = catalog.items.length;
      details[platform.name] = {
        'gamesVerified': catalog.gamesVerified,
        'consoles': catalog.items.expand((i) => i.consoles).toSet().toList()
          ..sort(),
        'memberGames': catalog.items
            .where((i) => i.id.startsWith('nso_member_'))
            .map((i) => i.title)
            .toList(),
        'current': catalog.items.where((i) => i.availableAt(now)).length,
        'monthly': catalog.items
            .where((i) =>
                i.addedAt?.year == now.year && i.addedAt?.month == now.month)
            .map((i) => i.title)
            .toList(),
        'upcoming': catalog.items
            .where((i) => i.addedAt?.isAfter(now) == true)
            .map(
                (i) => {'title': i.title, 'date': i.addedAt!.toIso8601String()})
            .toList(),
        'leaving': catalog.items
            .where((i) =>
                i.status.name == 'leavingSoon' &&
                i.availableUntil?.isAfter(now) == true)
            .map((i) => {
                  'title': i.title,
                  'untilExclusive': i.availableUntil!.toIso8601String(),
                  'source': i.sourceUrl
                })
            .toList(),
        'benefits': catalog.benefits
            .map((p) => {
                  'tier': p.tier.name,
                  'features': p.features,
                  'source': p.sourceUrl
                })
            .toList(),
        'notices': catalog.notices,
        'ghost': catalog.items
            .where((i) => i.title.toLowerCase().contains('ghost of tsushima'))
            .map((i) =>
                {'title': i.title, 'cover': i.coverUrl, 'tier': i.tier.name})
            .toList(),
      };
    }
  } finally {
    sample();
    timer.cancel();
    source.close();
  }
  final result = {
    'label': args.isEmpty ? 'probe' : args.first,
    'elapsedMs': watch.elapsedMilliseconds,
    'largestUiGapMs': largestGap / 1000,
    'heartbeatTicks': ticks,
    'entries': counts
  };
  stdout.writeln(jsonEncode(result));
  await Directory('build/subscription-probe').create(recursive: true);
  await File(
          'build/subscription-probe/responsiveness-${args.isEmpty ? 'probe' : args.first}.json')
      .writeAsString(jsonEncode(result));
  await File('build/subscription-probe/catalog-details.json')
      .writeAsString(const JsonEncoder.withIndent('  ').convert(details));
}
