import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/subscription_source.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';

void main() {
  test(
      'current official US responses parse games and membership activation dates',
      () {
    final now = DateTime.now();
    String read(String source) =>
        File('build/subscription-probe/$source.html').readAsStringSync();
    final ps = SubscriptionSource.parsePlaystation(
        read('pscatalog'), SubscriptionTier.psExtra, now);
    final classics = SubscriptionSource.parsePlaystation(
        read('psclassics'), SubscriptionTier.psPremium, now);
    final monthly = SubscriptionSource.parsePlaystation(
        read('psmonthly'), SubscriptionTier.psEssential, now);
    final announcements = SubscriptionSource.parseAnnouncements(
        read('psnews'), GamePlatform.playstation, now);
    final nso = SubscriptionSource.parseNintendo(read('nintendo'), now);
    final genesis = SubscriptionSource.parseGenesis(read('genesis'), now);
    final ids = (jsonDecode(read('xboxcatalog')) as List)
        .skip(1)
        .map((item) => item['id'] as String);
    final xbox = SubscriptionSource.parseXbox(read('xboxproducts'),
        {for (final id in ids) id: SubscriptionTier.xboxUltimate}, now);
    final xboxNews = SubscriptionSource.parseAnnouncements(
        read('xboxnews'), GamePlatform.xbox, now);
    expect(ps.length, greaterThan(100));
    expect(classics.length, greaterThan(50));
    expect(monthly, isNotEmpty);
    expect(nso.length, greaterThan(100));
    expect(genesis.length, greaterThan(30));
    expect(xbox, isNotEmpty);
    expect(announcements.where((item) => item.addedAt?.month == now.month),
        isNotEmpty);
    expect(
        xboxNews.where((item) => item.addedAt?.month == now.month), isNotEmpty);
    stdout.writeln(
        'Official parsed PS=${ps.length}, classics=${classics.length}, monthly=${monthly.length}, '
        'PS announcements=${announcements.length}, NSO=${nso.length}, Genesis=${genesis.length}, Xbox sample=${xbox.length}, Xbox announcements=${xboxNews.length}');
  }, skip: !const bool.fromEnvironment('LIVE_SUBSCRIPTION_PROBE'));
}
