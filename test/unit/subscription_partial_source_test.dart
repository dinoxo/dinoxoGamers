import 'dart:convert';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/data/datasources/subscription_source.dart';
import 'package:dinoxo_gamers/data/datasources/membership_benefits_source.dart';
import 'package:dinoxo_gamers/domain/models/subscription_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final now = DateTime(2026, 9, 28);
  Future<void> checkFeed(String feed, {required bool warned}) async {
    final source = SubscriptionSource(client: MockClient((request) async {
      if (request.url.path.endsWith('/feed/')) return http.Response(feed, 200);
      if (request.url.path == '/bin/imagic/gameslist') {
        return http.Response(
            jsonEncode([
              {
                'games': [
                  {
                    'name': 'Verified Game',
                    'productId': 'real',
                    'device': ['PS5'],
                    'conceptUrl':
                        'https://store.playstation.com/en-us/concept/real'
                  }
                ]
              }
            ]),
            200);
      }
      return http.Response(
          '''<div class="comparison-panel__tier-tab"><h3>Essential</h3>
        <ul class="feature-descriptors"><li><span class="feature-descriptors__text">Monthly games</span></li></ul></div>''',
          200);
    }));
    addTearDown(source.close);
    final catalog = await source.fetchCatalog(GamePlatform.playstation, now);
    expect(catalog.items, isNotEmpty);
    expect(catalog.benefits, isNotEmpty);
    expect(
        catalog.notices
            .any((n) => n.contains('no se pudieron consultar los anuncios')),
        warned);
  }

  test(
      'HTTP 200 maintenance HTML keeps current games but warns about unreadable announcements',
      () async {
    await checkFeed('<html><h1>Maintenance</h1></html>', warned: true);
  });
  test(
      'a relevant RSS item missing its article body cannot mean no announcements',
      () async {
    await checkFeed(
        '''<rss><channel><item><title>PlayStation Plus Monthly Games for October</title>
      <link>https://blog.playstation.com/2026/09/25/games/</link></item></channel></rss>''',
        warned: true);
  });
  test('truncated RSS is reported while preserving the verified games',
      () async {
    await checkFeed(
        '<rss><channel><item><title>PlayStation Plus Game Catalog</title>',
        warned: true);
  });
  test('a valid empty feed is absence of announcements, not a source error',
      () async {
    await checkFeed('<rss><channel></channel></rss>', warned: false);
  });
  test('a Nintendo benefits page failure preserves the other verified plan',
      () async {
    final source = SubscriptionSource(client: MockClient((request) async {
      if (request.url.toString() == MembershipBenefitsSource.expansionUrl) {
        return http.Response('Unavailable', 503);
      }
      if (request.url.toString() == MembershipBenefitsSource.nintendoUrl) {
        return http.Response(
            '<main><h2>Play with friends online</h2></main>', 200);
      }
      if (request.url.toString() == SubscriptionSource.genesisPage) {
        return http.Response(
            '<h2>Included games:</h2><ul><li>Sonic</li></ul>', 200);
      }
      final data = request.url.toString() == SubscriptionSource.nintendoPage
          ? {
              'props': {
                'pageProps': {
                  'page': {
                    'classicGamesData': {
                      'NES': [
                        {'__entryId': 'mario', 'caption': 'Super Mario Bros.'}
                      ]
                    }
                  }
                }
              }
            }
          : {
              'props': {
                'pageProps': {'initialApolloState': {}}
              }
            };
      return http.Response(
          '<script id="__NEXT_DATA__">${jsonEncode(data)}</script>', 200);
    }));
    addTearDown(source.close);
    final catalog = await source.fetchCatalog(GamePlatform.nintendo, now);
    expect(catalog.items, isNotEmpty);
    expect(catalog.benefits.single.tier, SubscriptionTier.nsoStandard);
    expect(catalog.notices.any((n) => n.contains('beneficios')), true);
  });
}
