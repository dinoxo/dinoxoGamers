import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/game.dart';
import '../../../../domain/models/game_media.dart';
import '../../../../domain/services/game_media_service.dart';
import '../../../../domain/services/whatsapp_service.dart';

class GameMediaGallerySection extends StatefulWidget {
  final Game game;

  const GameMediaGallerySection({
    super.key,
    required this.game,
  });

  @override
  State<GameMediaGallerySection> createState() =>
      _GameMediaGallerySectionState();
}

class _GameMediaGallerySectionState extends State<GameMediaGallerySection> {
  late Future<GameMedia> _mediaFuture;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void didUpdateWidget(covariant GameMediaGallerySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id ||
        oldWidget.game.title != widget.game.title ||
        oldWidget.game.coverUrl != widget.game.coverUrl) {
      _loadMedia();
    }
  }

  void _loadMedia() {
    _mediaFuture = GameMediaService.instance.fetchMedia(widget.game);
  }

  void _showImageFullscreen(
      BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(235),
      builder: (ctx) {
        int currentIndex = initialIndex;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'Captura ${currentIndex + 1} de ${images.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              body: Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.8,
                  maxScale: 3.5,
                  child: Image.network(
                    images[currentIndex],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 60,
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: images.length > 1
                  ? Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left,
                                color: Colors.white),
                            onPressed: currentIndex > 0
                                ? () => setModalState(() => currentIndex--)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${currentIndex + 1} / ${images.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.chevron_right,
                                color: Colors.white),
                            onPressed: currentIndex < images.length - 1
                                ? () => setModalState(() => currentIndex++)
                                : null,
                          ),
                        ],
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameMedia>(
      future: _mediaFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Container(
              height: 180,
              padding: const EdgeInsets.all(16),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(height: 12),
                  Text(
                    'Buscando capturas del juego...',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final media = snapshot.data!;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.photo_library_outlined,
                        color: AppTheme.primaryLight, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      'Fotos y Videos del Juego',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        '${media.screenshots.length} fotos',
                        style: const TextStyle(
                          color: AppTheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Screenshots Horizontal Gallery
                const Text(
                  'Capturas verificadas · versión de PC en Steam',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (media.screenshots.isEmpty)
                  const Text(
                      'No hay capturas verificadas para este título y edición.',
                      style:
                          TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                if (media.screenshots.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: media.screenshots.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final url = media.screenshots[index];
                        return GestureDetector(
                          onTap: () => _showImageFullscreen(
                              context, media.screenshots, index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Container(
                                  width: 190,
                                  height: 120,
                                  color: AppTheme.surfaceElevated,
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.broken_image,
                                          color: AppTheme.textMuted),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 6,
                                  bottom: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withAlpha(160),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),

                // Videos Section
                const Text(
                  'Buscar videos y reseñas',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // 2 Videos Row
                Row(
                  children: [
                    Expanded(
                      child: _buildVideoCard(
                        video: media.trailer,
                        icon: Icons.movie_outlined,
                        badgeColor: AppTheme.primaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildVideoCard(
                        video: media.reviewVideo,
                        icon: Icons.rate_review_outlined,
                        badgeColor: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoCard({
    required GameVideo video,
    required IconData icon,
    required Color badgeColor,
  }) {
    return InkWell(
      onTap: () {
        WhatsAppService.launchExternalUrl(video.videoUrl);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Play button overlay
            Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: video.thumbnailUrl.isEmpty
                      ? const Icon(Icons.play_circle_outline,
                          color: AppTheme.textMuted)
                      : Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.surfaceSubtle,
                            child: const Icon(Icons.play_circle_fill,
                                color: AppTheme.textMuted, size: 36),
                          ),
                        ),
                ),
                Container(
                  color: Colors.black.withAlpha(90),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(220),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(100),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 22),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(180),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 10, color: badgeColor),
                        const SizedBox(width: 3),
                        Text(
                          video.tag,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.open_in_new,
                          size: 10, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          video.channelOrSource,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
