import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/services/game_media_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('unavailable media never falls back to pictures from another game',
      () async {
    const game = Game(
        id: 'identity_unknown',
        title: 'An Unreleased Console Exclusive',
        slug: 'unknown',
        coverUrl: '',
        platform: GamePlatform.nintendo,
        consoles: ['Nintendo Switch'],
        genres: [],
        developer: '',
        publisher: '',
        releaseDate: null);
    final media = await GameMediaService.instance.fetchMedia(game);
    expect(media.screenshots, isEmpty);
    expect(media.trailer.tag, 'Buscar tráiler');
  });
}
