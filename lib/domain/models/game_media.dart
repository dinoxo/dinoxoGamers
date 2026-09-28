class GameVideo {
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String channelOrSource;
  final String tag;

  const GameVideo({
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.channelOrSource,
    required this.tag,
  });
}

class GameMedia {
  final List<String> screenshots;
  final GameVideo trailer;
  final GameVideo reviewVideo;

  const GameMedia({
    required this.screenshots,
    required this.trailer,
    required this.reviewVideo,
  });

  bool get hasAtLeastFiveScreenshots => screenshots.length >= 5;
}
