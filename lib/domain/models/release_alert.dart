import '../../core/constants/app_constants.dart';

/// A date reminder, deliberately independent of a price-target alert.
class ReleaseAlert {
  const ReleaseAlert({
    required this.id,
    required this.gameTitle,
    required this.platform,
    required this.coverUrl,
    required this.sourceUrl,
    required this.releaseDate,
    required this.createdAt,
    this.isActive = true,
  });

  final String id;
  final String gameTitle;
  final GamePlatform platform;
  final String coverUrl;
  final String sourceUrl;
  final DateTime releaseDate;
  final DateTime createdAt;
  final bool isActive;

  int daysRemaining(DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final day =
        DateTime.utc(releaseDate.year, releaseDate.month, releaseDate.day);
    return day.difference(today).inDays;
  }

  ReleaseAlert copyWith({bool? isActive}) => ReleaseAlert(
      id: id,
      gameTitle: gameTitle,
      platform: platform,
      coverUrl: coverUrl,
      sourceUrl: sourceUrl,
      releaseDate: releaseDate,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive);
}
