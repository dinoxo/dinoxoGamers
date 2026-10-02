import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class PlatformBadge extends StatelessWidget {
  final GamePlatform platform;
  final bool compact;

  const PlatformBadge({
    super.key,
    required this.platform,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.platformColor(platform);
    final name = AppConstants.platformDisplayName(platform);

    IconData iconData;
    switch (platform) {
      case GamePlatform.playstation:
        iconData = Icons.sports_esports;
        break;
      case GamePlatform.nintendo:
        iconData = Icons.gamepad;
        break;
      case GamePlatform.xbox:
        iconData = Icons.videogame_asset;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: compact ? 12 : 14, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
              child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          )),
        ],
      ),
    );
  }
}
