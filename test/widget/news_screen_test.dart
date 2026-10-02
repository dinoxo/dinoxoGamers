import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dinoxo_gamers/data/datasources/news_source.dart';

import 'package:dinoxo_gamers/ui/features/news/news_screen.dart';

void main() {
  testWidgets('NewsScreen renders search, filter chips and articles',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
          '''
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>GTA 6 llegará a finales de 2026</title>
      <link>https://www.3djuegos.com/noticias/gta-6</link>
      <description>Detalles sobre el lanzamiento en PS5 y Xbox Series.</description>
      <pubDate>Thu, 01 Oct 2026 14:00:00 +0000</pubDate>
    </item>
  </channel>
</rss>
''',
          200,
          headers: {'content-type': 'application/xml; charset=utf-8'});
    });

    final source = NewsSource(client: mockClient);

    await tester.pumpWidget(MaterialApp(
      home: NewsScreen(source: source),
    ));

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Noticias'), findsOneWidget);

    // Verify Search Field
    expect(find.widgetWithText(TextField, 'Buscar en noticias...'),
        findsOneWidget);

    // Verify Filter Chips
    expect(find.widgetWithText(ChoiceChip, 'Todas'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '3DJuegos'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Vandal'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Metacritic'), findsOneWidget);

    // Verify loaded article title
    expect(find.text('GTA 6 llegará a finales de 2026'), findsWidgets);
  });
}
