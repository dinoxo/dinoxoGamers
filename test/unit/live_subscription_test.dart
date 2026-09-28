import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/subscription_source.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:dinoxo_gamers/domain/services/subscription_service.dart';
import '../fixtures/subscriptions.dart';

void main() {
  final now = DateTime(2026, 9, 27);
  test('loaded memberships do not match sequels, remakes, DLC or wrong brands',
      () async {
    final service = SubscriptionService(
        source: TestSubscriptionSource([
          subscription(),
          subscription(
              title: 'Mario Kart 8 Deluxe Booster Course Pass',
              platform: GamePlatform.nintendo,
              tier: SubscriptionTier.nsoExpansion),
        ]),
        clock: () => now);
    await service.refresh();
    expect(
        service.checkGame('Resident Evil 20',
            platform: GamePlatform.playstation),
        isNull);
    expect(
        service.checkGame('Resident Evil 2 Remastered',
            platform: GamePlatform.playstation),
        isNull);
    expect(service.checkGame('Resident Evil 2', platform: GamePlatform.xbox),
        isNull);
    expect(
        service.checkGame('Mario Kart 8 Deluxe',
            platform: GamePlatform.nintendo),
        isNull);
    expect(
        service.checkGame('Resident Evil 2 Standard Edition',
            platform: GamePlatform.playstation),
        isNotNull);
  });
  test(
      'monthly and next-month filters use activation dates and expire membership claims',
      () async {
    final source = TestSubscriptionSource([
      subscription(title: 'New', start: DateTime(2026, 9, 2)),
      subscription(title: 'Old', start: DateTime(2026, 8, 3)),
      subscription(
          title: 'Expired',
          start: DateTime(2026, 9, 2),
          end: DateTime(2026, 9, 20)),
      subscription(
          title: 'Next', start: DateTime(2026, 10, 6), confirmed: false),
    ]);
    final service = SubscriptionService(source: source, clock: () => now);
    await service.refresh();
    expect(service.getItems().map((i) => i.title), ['New', 'Old']);
    expect(
        service
            .getItems(category: SubscriptionCategory.monthly)
            .map((i) => i.title),
        ['Expired', 'New']);
    expect(
        service
            .getItems(category: SubscriptionCategory.comingSoon)
            .single
            .title,
        'Next');
    expect(service.checkGame('Expired'), isNull);
  });
  test(
      'failed refresh clears previous proof instead of keeping a false included badge',
      () async {
    final source = TestSubscriptionSource([subscription()]);
    final service = SubscriptionService(source: source, clock: () => now);
    await service.refresh();
    expect(service.checkGame('Resident Evil 2'), isNotNull);
    source.failingPlatform = GamePlatform.playstation;
    await service.refresh();
    expect(service.checkGame('Resident Evil 2'), isNull);
    expect(service.errors[GamePlatform.playstation], isNotNull);
  });
  test('PS parser rejects non-US links and benefits without console versions',
      () {
    final body = jsonEncode([
      {
        'games': [
          {
            'name': 'Real',
            'conceptUrl': 'https://store.playstation.com/en-us/concept/1',
            'device': ['PS5'],
            'productId': 'a'
          },
          {
            'name': 'Other region',
            'conceptUrl': 'https://store.playstation.com/en-gb/concept/2',
            'device': ['PS5']
          },
          {
            'name': 'Jump Start Bundle',
            'conceptUrl': 'https://store.playstation.com/en-us/concept/3',
            'device': []
          },
        ]
      }
    ]);
    final items = SubscriptionSource.parsePlaystation(
        body, SubscriptionTier.psExtra, now);
    expect(items.single.title, 'Real');
    expect(items.single.addedAt,
        isNull); // Store release date is not a membership activation.
  });
  test(
      'announcements parse actual membership windows and exclude PC-only Game Pass',
      () {
    const ps =
        '''<rss><channel><item><title>PlayStation Plus Monthly Games for October</title>
      <link>https://blog.playstation.com/2026/09/30/monthly-games/</link>
      <content:encoded><![CDATA[<p>Available from October 6 until November 2.</p>
      <p><strong>Example Game | PS5</strong></p>]]></content:encoded></item></channel></rss>''';
    final games = SubscriptionSource.parseAnnouncements(
        ps, GamePlatform.playstation, now);
    expect(games.single.addedAt, DateTime(2026, 10, 6));
    expect(games.single.availableUntil, DateTime(2026, 11, 3));
    expect(games.single.availableAt(now), false);
    const xbox =
        '''<rss><channel><item><title>Coming to Xbox Game Pass: Examples</title>
      <link>https://news.xbox.com/en-us/2026/09/15/example/</link>
      <content:encoded><![CDATA[<h2>Coming Soon</h2><strong>Console Game (Console and PC) – October 2</strong>
      <strong>PC Game (PC) – October 3</strong>]]></content:encoded></item></channel></rss>''';
    expect(
        SubscriptionSource.parseAnnouncements(xbox, GamePlatform.xbox, now)
            .single
            .title,
        'Console Game');
  });
  test(
      'Nintendo news adds a new title before the overview catches up and dates future announcements',
      () {
    const body =
        '<main><h1>News</h1><h1>New update for Nintendo Switch Online members!</h1><h2>Nintendo Entertainment System – Nintendo Classics</h2><h3>New Ninja Game</h3></main>';
    final news = SubscriptionSource.parseNintendoNews(
        body,
        'https://www.nintendo.com/us/whatsnew/update/',
        DateTime(2026, 9, 1),
        now);
    expect(news.single.availableAt(now), true);
    const future =
        '<main><h1>Nintendo Classics update</h1><p>Available October 10.</p><h2>Game Boy Advance</h2><h3>Next Classic</h3></main>';
    expect(
        SubscriptionSource.parseNintendoNews(
                future,
                'https://www.nintendo.com/us/whatsnew/upcoming/',
                DateTime(2026, 9, 25),
                now)
            .single
            .addedAt,
        DateTime(2026, 10, 10));
  });
  test('Genesis reads only the official included-games list', () {
    const body =
        '<h2>Other heading</h2><ul><li>Hardware</li></ul><h2>Included games:</h2><ul><li>Sonic the Hedgehog 2</li><li>Golden Axe</li></ul><h2>Other section</h2>';
    expect(SubscriptionSource.parseGenesis(body, now).map((item) => item.title),
        ['Sonic the Hedgehog 2', 'Golden Axe']);
  });
  test('purchase advice selects the lowest currently available PS tier',
      () async {
    final service = SubscriptionService(
        source: TestSubscriptionSource([
          subscription(tier: SubscriptionTier.psExtra),
          subscription(tier: SubscriptionTier.psEssential),
        ]),
        clock: () => now);
    await service.refresh();
    expect(service.checkGame('Resident Evil 2')!.item.tier,
        SubscriptionTier.psEssential);
  });
  test('a future addition to another tier preserves current membership access',
      () {
    final current = subscription(tier: SubscriptionTier.psExtra);
    final announcement = subscription(
        tier: SubscriptionTier.psEssential,
        start: DateTime(2026, 10, 6),
        confirmed: false);
    final merged =
        SubscriptionSource.mergeAnnouncements([current], [announcement], now);
    expect(merged.where((item) => item.availableAt(now)), hasLength(1));
    expect(merged.where((item) => item.addedAt?.month == 10), hasLength(1));
  });
  test('Game Pass announcements use their published tier and wrap January', () {
    const feed =
        '''<rss><channel><item><title>Coming to Xbox Game Pass: Games</title>
    <link>https://news.xbox.com/en-us/2026/12/15/example/</link>
    <content:encoded><![CDATA[<h2>Coming Soon</h2><p><strong>Console Game (Console and PC) – January 2</strong><br>Now with Game Pass Premium; joining Game Pass Ultimate.</p>]]></content:encoded></item></channel></rss>''';
    final item = SubscriptionSource.parseAnnouncements(
            feed, GamePlatform.xbox, DateTime(2026, 12, 27))
        .single;
    expect(item.tier, SubscriptionTier.xboxStandard);
    expect(item.addedAt, DateTime(2027, 1, 2));
  });
  test('Nintendo next-month announcement wraps into January', () {
    const body =
        '<main><h1>Nintendo Classics update</h1><p>Available January 10.</p><h2>Game Boy Advance</h2><h3>Next Classic</h3></main>';
    final item = SubscriptionSource.parseNintendoNews(
            body,
            'https://www.nintendo.com/us/whatsnew/update/',
            DateTime(2026, 12, 20),
            DateTime(2026, 12, 27))
        .single;
    expect(item.addedAt, DateTime(2027, 1, 10));
  });
}
