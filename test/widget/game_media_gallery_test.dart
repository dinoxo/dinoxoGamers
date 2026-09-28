import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/core/theme/app_theme.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/ui/features/game_details/widgets/game_media_gallery_section.dart';

void main() {
  testWidgets('GameMediaGallerySection renders title, screenshots and video cards',
      (WidgetTester tester) async {
    const testGame = Game(
      id: 'media_test_game',
      title: 'Marvel Spider-Man Miles Morales',
      slug: 'spider-man-miles-morales',
      coverUrl: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co2822.webp',
      platform: GamePlatform.playstation,
      consoles: ['PS5'],
      genres: ['Acción', 'Aventura'],
      developer: 'Insomniac Games',
      publisher: 'Sony Interactive Entertainment',
      releaseDate: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: GameMediaGallerySection(game: testGame),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify title and subtitle
    expect(find.text('Fotos y Videos del Juego'), findsOneWidget);
    expect(find.text('Capturas de pantalla (Toca para ampliar)'), findsOneWidget);
    expect(find.text('Videos Oficiales y Reseñas'), findsOneWidget);

    // Verify video tags
    expect(find.text('Trailer Oficial'), findsOneWidget);
    expect(find.text('Reseña en Video'), findsOneWidget);
  });
}
