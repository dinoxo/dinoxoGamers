import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/data/datasources/news_source.dart';
import 'package:dinoxo_gamers/domain/models/news_article.dart';

void main() {
  group('NewsSource RSS & JSON parsing', () {
    test('parseRss correctly parses 3DJuegos RSS items', () {
      const xml = '''
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>3DJuegos</title>
    <item>
      <title><![CDATA[Grand Theft Auto VI revela nuevos detalles]]></title>
      <link>https://www.3djuegos.com/noticias/gta-6-detalles</link>
      <description><![CDATA[<p>Rockstar Games comparte información oficial sobre el esperado título.</p>]]></description>
      <pubDate>Thu, 01 Oct 2026 15:30:00 +0200</pubDate>
      <enclosure url="https://i.3djuegos.com/gta6.jpg" type="image/jpeg" />
    </item>
  </channel>
</rss>
''';

      final articles = NewsSource.parseRss(xml, NewsPortal.tresDJuegos,
          defaultHost: 'https://www.3djuegos.com');

      expect(articles.length, 1);
      final a = articles.first;
      expect(a.title, 'Grand Theft Auto VI revela nuevos detalles');
      expect(a.url, 'https://www.3djuegos.com/noticias/gta-6-detalles');
      expect(a.description,
          'Rockstar Games comparte información oficial sobre el esperado título.');
      expect(a.imageUrl, 'https://i.3djuegos.com/gta6.jpg');
      expect(a.portal, NewsPortal.tresDJuegos);
      expect(a.portalDisplayName, '3DJuegos');
      expect(a.publishedAt, isNotNull);
    });

    test('parseRss correctly parses Vandal RSS items', () {
      const xml = '''
<?xml version="1.0" encoding="iso-8859-1"?>
<rss version="2.0">
  <channel>
    <title>Vandal</title>
    <item>
      <title>Zelda: Ocarina of Time recibe remake no oficial</title>
      <link>https://vandal.elespanol.com/noticia/12345/zelda-ocarina/</link>
      <description>Un proyecto comunitario actualiza el clásico a Unreal Engine 5.</description>
      <pubDate>Thu, 01 Oct 2026 18:00:00 +0200</pubDate>
    </item>
  </channel>
</rss>
''';

      final articles = NewsSource.parseRss(xml, NewsPortal.vandal,
          defaultHost: 'https://vandal.elespanol.com');

      expect(articles.length, 1);
      final a = articles.first;
      expect(a.title, 'Zelda: Ocarina of Time recibe remake no oficial');
      expect(a.portal, NewsPortal.vandal);
      expect(a.portalDisplayName, 'Vandal');
      expect(a.description,
          'Un proyecto comunitario actualiza el clásico a Unreal Engine 5.');
    });
  });
}
