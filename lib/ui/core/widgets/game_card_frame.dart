import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

/// Artwork and platform-colored surface shared by every game list.
class GameCardFrame extends StatelessWidget {
  const GameCardFrame(
      {super.key,
      required this.platform,
      required this.coverUrl,
      required this.child,
      required this.onTap,
      this.margin = const EdgeInsets.symmetric(horizontal: 14, vertical: 5)});
  final GamePlatform platform;
  final String coverUrl;
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.platformColor(platform);
    final missingCover = Semantics(
      container: true,
      image: true,
      label: 'Portada no disponible',
      child: Icon(Icons.sports_esports, size: 38, color: color),
    );
    return Container(
      margin: margin,
      decoration:
          BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(
            color: color.withAlpha(24),
            blurRadius: 12,
            offset: const Offset(0, 3)),
      ]),
      child: Material(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withAlpha(180), width: 1)),
        color: AppTheme.surface,
        child: InkWell(
            onTap: onTap,
            child: LayoutBuilder(builder: (context, constraints) {
              final enlargedText =
                  MediaQuery.textScalerOf(context).scale(14) > 18;
              final width = (constraints.maxWidth * (enlargedText ? .28 : .34))
                  .clamp(80.0, 148.0);
              return Stack(children: [
                Positioned.fill(
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                  color.withAlpha(24),
                  AppTheme.surface,
                  color.withAlpha(14)
                ], begin: Alignment.topLeft, end: Alignment.bottomRight)))),
                // Positioned art follows the content height without an expensive intrinsic layout.
                Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: width,
                    child: Stack(fit: StackFit.expand, children: [
                      ColoredBox(
                          color: Color.alphaBlend(
                              color.withAlpha(28), AppTheme.surfaceElevated),
                          child: coverUrl.isEmpty
                              ? missingCover
                              : Image.network(coverUrl,
                                  fit: BoxFit.cover,
                                  cacheWidth: (width * 3).round(),
                                  errorBuilder: (_, __, ___) => missingCover)),
                      IgnorePointer(
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                            Colors.transparent,
                            AppTheme.surface.withAlpha(35)
                          ])))),
                    ])),
                Padding(
                    padding: EdgeInsets.fromLTRB(width + 10, 10, 10, 10),
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 124),
                        child: child)),
              ]);
            })),
      ),
    );
  }
}

class GameCardArrow extends StatelessWidget {
  const GameCardArrow({super.key, required this.platform, required this.onTap});
  final GamePlatform platform;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(colors: [
              AppTheme.platformColor(platform),
              Color.lerp(
                  AppTheme.platformColor(platform), AppTheme.primary, .6)!
            ])),
        child: IconButton(
            onPressed: onTap,
            tooltip: 'Ver detalles',
            constraints: const BoxConstraints(minWidth: 40, minHeight: 44),
            padding: const EdgeInsets.all(5),
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white)),
      );
}
