import 'package:flutter_test/flutter_test.dart';
import 'package:dinoxo_gamers/core/constants/app_constants.dart';
import 'package:dinoxo_gamers/domain/models/game.dart';
import 'package:dinoxo_gamers/domain/services/game_media_service.dart';

void main() {
  group('GameMediaService Tests', () {
    final service = GameMediaService.instance;

    test('fetchMedia returns at least 5 screenshots and 2 videos for any game', () async {
      const testGame = Game(
        id: 'test_mario_galaxy',
        title: 'Super Mario Galaxy',
        slug: 'super-mario-galaxy',
        coverUrl: 'https://images.igdb.com/igdb/image/upload/t_cover_big/co1x3d.webp',
        platform: GamePlatform.nintendo,
        consoles: ['Switch'],
        genres: ['Platformer'],
        developer: 'Nintendo',
        publisher: 'Nintendo',
        releaseDate: null,
      );

      final media = await service.fetchMedia(testGame);

      expect(media.screenshots.length, greaterThanOrEqualTo(5));
      expect(media.hasAtLeastFiveScreenshots, isTrue);

      // Verify trailer video
      expect(media.trailer.title, contains('Trailer Oficial'));
      expect(media.trailer.tag, 'Trailer Oficial');
      expect(media.trailer.videoUrl, contains('youtube.com'));
      expect(media.trailer.thumbnailUrl.isNotEmpty, isTrue);

      // Verify review video
      expect(media.reviewVideo.title, contains('Reseña y Análisis'));
      expect(media.reviewVideo.tag, 'Reseña en Video');
      expect(media.reviewVideo.videoUrl, contains('youtube.com'));
      expect(media.reviewVideo.thumbnailUrl.isNotEmpty, isTrue);
    });
  });
}
