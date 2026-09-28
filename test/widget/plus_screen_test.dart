import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/theme/app_theme.dart';
import 'package:dinoxo_gamers/ui/features/subscriptions/plus_screen.dart';

void main() {
  testWidgets('PlusScreen renders header, search, platform chips and items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const PlusScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify AppBar title
    expect(find.text('Plus & Suscripciones'), findsOneWidget);

    // Verify Platform Chips
    expect(find.text('Todos'), findsWidgets);
    expect(find.text('PlayStation Plus'), findsOneWidget);
    expect(find.text('Xbox Game Pass'), findsOneWidget);
    expect(find.text('Nintendo Switch Online'), findsOneWidget);

    // Verify filter by PlayStation Plus
    await tester.tap(find.text('PlayStation Plus'));
    await tester.pumpAndSettle();

    // Should find PlayStation games
    expect(find.text('Harry Potter: Quidditch Champions'), findsOneWidget);

    // Filter by Xbox
    await tester.tap(find.text('Xbox Game Pass'));
    await tester.pumpAndSettle();

    // Should find Xbox games
    expect(find.text('Starfield'), findsOneWidget);
  });
}
