import '../../core/constants/app_constants.dart';
import 'game.dart';

/// A platform-specific upcoming release verified against a US source page.
class PreorderGame {
  const PreorderGame({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.publisher,
    required this.developer,
    required this.platform,
    required this.consoles,
    required this.releaseDate,
    required this.sourceUri,
    required this.isPreorder,
    required this.game,
  });

  final String id;
  final String title;
  final String coverUrl;
  final String publisher;
  final String developer;
  final GamePlatform platform;
  final List<String> consoles;
  final DateTime? releaseDate;
  final Uri sourceUri;
  final bool isPreorder;
  final Game game;

  int? daysRemaining(DateTime now) {
    final date = releaseDate;
    if (date == null) return null;
    return DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(now.year, now.month, now.day))
        .inDays;
  }

  Game toGame() => Game(
        id: id,
        title: title,
        slug: game.slug,
        coverUrl: coverUrl,
        platform: platform,
        consoles: consoles,
        genres: game.genres,
        developer: developer,
        publisher: publisher,
        releaseDate: releaseDate,
        review: game.review,
        editions: game.editions,
      );
}
