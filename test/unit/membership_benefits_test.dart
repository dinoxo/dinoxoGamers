import 'package:dinoxo_gamers/data/datasources/membership_benefits_source.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 28);
  test(
      'PS benefits are read from each plan, not inherited from Premium marketing',
      () {
    const body =
        '''<div class="comparison-panel__tier-tab"><h3>Premium</h3><ul class="feature-descriptors"><li><p class="feature-descriptors__text">Game trials</p></li></ul></div>
    <div class="comparison-panel__tier-tab"><h3>Essential</h3><ul class="feature-descriptors"><li><p class="feature-descriptors__text">Monthly games</p></li><li><p class="feature-descriptors__text">Online multiplayer</p></li></ul></div>''';
    final plans = MembershipBenefitsSource.parsePlaystation(body, now);
    final essential =
        plans.singleWhere((p) => p.tier == SubscriptionTier.psEssential);
    expect(essential.features, contains('Juegos mensuales para reclamar'));
    expect(essential.features, isNot(contains('Pruebas de juegos')));
    expect(essential.sourceUrl, contains('/en-us/'));
  });
  test('Xbox keeps live cloud limits and excludes the PC-only plan', () {
    const body =
        '''<li id="core"><h3>Essential</h3><div class="details"><p class="pullBullet">50+ games</p><ul class="c-list"><li>Cloud playtime (10 hours/month)<sup>4</sup></li><li>Online console multiplayer</li></ul></div></li>
    <li id="pc"><h3>PC Game Pass</h3><ul class="c-list"><li>PC benefit</li></ul></li>''';
    final plans = MembershipBenefitsSource.parseXbox(body, now);
    expect(plans, hasLength(1));
    expect(plans.single.features.join(' '), contains('10'));
    expect(plans.single.features.join(' '), isNot(contains('PC benefit')));
  });
  test('Nintendo DLC and upgrade perks explicitly require the base game', () {
    const body =
        '''<main><h1>Expansion Pack</h1><h2>Virtual Boy games now available</h2>
      <h2>The Legend of Zelda: Breath of the Wild – Nintendo Switch 2 Edition Upgrade Pack</h2>
      <h2>Access DLC at no additional charge</h2><a>Mario Kart™ 8 Deluxe – Booster Course Pass</a>
      <h2>About Nintendo</h2></main>''';
    final plans = MembershipBenefitsSource.parseNintendo(
        body, SubscriptionTier.nsoExpansion, now);
    expect(plans.single.features.join(' '), contains('Virtual Boy'));
    expect(plans.single.features.join(' '), contains('juego base'));
    expect(plans.single.features.join(' '), isNot(contains('About Nintendo')));
  });
}
