import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/subscription_source.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:flutter_test/flutter_test.dart';
import '../fixtures/subscriptions.dart';

void main() {
  test(
      'Xbox announcements exclude game updates, trials and perk packs from additions',
      () {
    const feed =
        '''<rss><channel><item><title>Coming to Xbox Game Pass: Games</title>
      <link>https://news.xbox.com/en-us/2026/09/15/example/</link>
      <content:encoded><![CDATA[
      <h2>Available Today</h2><p><strong>New Console Game (Console and PC) – September 15</strong><br>Game Pass Ultimate</p>
      <h2>Coming Soon to Game Pass Essential</h2><p><strong>Next Console Game (Console) – October 2</strong><br>Game Pass Essential</p>
      <h2>Game Updates</h2><p><strong>Existing Game 1.0 (Console) – September 20</strong></p>
      <p><strong>Hockey: Early Access Trial (Console) – September 21</strong></p>
      <h2>In-Game Benefits</h2><p><strong>Brawlhalla (Cloud, Console and PC) – September 17</strong></p>
      <h2>Leaving September 30</h2><ul><li>Leaving Game (Console)</li></ul>
      ]]></content:encoded></item></channel></rss>''';
    final items = SubscriptionSource.parseAnnouncements(
        feed, GamePlatform.xbox, DateTime(2026, 9, 28));
    expect(items.where((i) => i.addedAt != null).map((i) => i.title),
        ['New Console Game', 'Next Console Game']);
    expect(
        items
            .where((i) => i.status == SubscriptionStatus.leavingSoon)
            .single
            .title,
        'Leaving Game');
  });
  test(
      'a departure keeps the verified cover and tier and preserves its addition date',
      () {
    final now = DateTime(2026, 9, 28);
    final current = subscription(
        title: 'Example Game',
        platform: GamePlatform.xbox,
        tier: SubscriptionTier.xboxCore,
        start: DateTime(2026, 9, 1),
        checked: now);
    const feed =
        '''<rss><channel><item><title>Coming to Xbox Game Pass: Games</title>
    <link>https://news.xbox.com/en-us/2026/09/15/example/</link>
    <content:encoded><![CDATA[<h2>Leaving September 30</h2><ul><li>Example Game (Console)</li></ul>]]></content:encoded></item></channel></rss>''';
    final items = SubscriptionSource.mergeAnnouncements(
        [current],
        SubscriptionSource.parseAnnouncements(feed, GamePlatform.xbox, now),
        now);
    expect(items.single.status, SubscriptionStatus.leavingSoon);
    expect(items.single.tier, SubscriptionTier.xboxCore);
    expect(items.single.addedAt, DateTime(2026, 9, 1));
    expect(items.single.availableAt(now), true);
    expect(items.single.availableAt(DateTime(2026, 10, 1)), false);
  });
  test('Xbox removals carry the published end date, not an activation date',
      () {
    const feed =
        '''<rss><channel><item><title>Coming to Xbox Game Pass: Games</title>
    <link>https://news.xbox.com/en-us/2026/09/15/example/</link>
    <content:encoded><![CDATA[<h2>Leaving September 30</h2><ul><li>Example Game (Cloud, Console and PC)</li><li>PC Only Game (PC)</li></ul><h2>Other news</h2><ul><li>Unrelated content</li></ul>]]></content:encoded></item></channel></rss>''';
    final leaving = SubscriptionSource.parseAnnouncements(
            feed, GamePlatform.xbox, DateTime(2026, 9, 28))
        .where((item) => item.status == SubscriptionStatus.leavingSoon)
        .toList();
    expect(leaving, hasLength(1));
    expect(leaving.single.title, 'Example Game');
    expect(leaving.single.availableUntil, DateTime(2026, 10, 1));
    expect(leaving.single.addedAt, isNull);
  });
}
