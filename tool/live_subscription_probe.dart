import 'dart:io';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/subscription_source.dart';

Future<void> main() async {
  final ca = File('build/live-probe/host-ca.pem');
  if (ca.existsSync()) {
    SecurityContext.defaultContext.setTrustedCertificates(ca.path);
  }
  final source = SubscriptionSource();
  for (final platform in GamePlatform.values) {
    final now = DateTime.now();
    final items = await source.fetch(platform, now);
    final current = items.where((item) => item.availableAt(now)).length;
    final month = items
        .where((item) =>
            item.addedAt?.year == now.year && item.addedAt?.month == now.month)
        .length;
    final next = DateTime(now.year, now.month + 1);
    final nextCount = items
        .where((item) =>
            item.addedAt?.year == next.year &&
            item.addedAt?.month == next.month)
        .length;
    stdout.writeln(
        '${platform.name}: verified=$current, additions=$month, next-month=$nextCount');
    if (current == 0) throw StateError('No verified current catalog');
  }
  exit(0);
}
