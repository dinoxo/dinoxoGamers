import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Shared, code-drawn brand banner. No remote artwork is fetched at startup.
class GamingHeader extends StatelessWidget implements PreferredSizeWidget {
  const GamingHeader(
      {super.key,
      required this.title,
      required this.subtitle,
      this.accent = AppTheme.secondary,
      this.actions = const [],
      this.bottom,
      this.height = 148});
  factory GamingHeader.adaptive(
    BuildContext context, {
    Key? key,
    required String title,
    required String subtitle,
    Color accent = AppTheme.secondary,
    List<Widget> actions = const [],
    PreferredSizeWidget? bottom,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    return GamingHeader(
        key: key,
        title: title,
        subtitle: subtitle,
        accent: accent,
        actions: actions,
        bottom: bottom,
        height: math.max(148,
            58 + scaler.scale(24) * 1.04 * 2 + scaler.scale(11) * 1.3 * 2));
  }
  final String title;
  final String subtitle;
  final Color accent;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final double height;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.background,
                Color.alphaBlend(accent.withAlpha(35), AppTheme.background),
                AppTheme.background
              ]),
          border: Border(bottom: BorderSide(color: accent.withAlpha(65))),
        ),
        child: SafeArea(
            bottom: false,
            child: Column(children: [
              Expanded(child: LayoutBuilder(builder: (context, constraints) {
                final showLogo = constraints.maxWidth >= 310 &&
                    MediaQuery.textScalerOf(context).scale(24) <= 32;
                final canGoBack = Navigator.of(context).canPop();
                return Stack(children: [
                  Positioned.fill(
                      child: ClipRect(
                          child:
                              CustomPaint(painter: _CircuitPainter(accent)))),
                  if (showLogo)
                    Positioned(
                        right: 20,
                        bottom: 8,
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration:
                              BoxDecoration(shape: BoxShape.circle, boxShadow: [
                            BoxShadow(
                                color: accent.withAlpha(75),
                                blurRadius: 28,
                                spreadRadius: 5),
                          ]),
                          child: ClipOval(
                              child: Image.asset(
                                  'assets/images/dinoxo_store_badge.png',
                                  fit: BoxFit.contain,
                                  cacheWidth: 336,
                                  excludeFromSemantics: true)),
                        )),
                  Positioned(
                      top: 0,
                      left: 8,
                      right: 8,
                      child: SizedBox(
                          height: 40,
                          child: Row(children: [
                            if (canGoBack) const BackButton(),
                            if (!canGoBack) ...[
                              Icon(Icons.sports_esports_outlined,
                                  size: 16, color: accent),
                              const SizedBox(width: 6),
                              const Flexible(
                                  child: Text('DINOXO GAMERS',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.4))),
                            ],
                            const Spacer(),
                            ...actions,
                          ]))),
                  Positioned(
                      left: 20,
                      top: 44,
                      right: showLogo ? 142 : 20,
                      bottom: 8,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                                shaderCallback: (bounds) => LinearGradient(
                                            colors: [
                                          Colors.white,
                                          Color.lerp(accent, Colors.white, .55)!
                                        ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter)
                                        .createShader(bounds),
                                child: Text(title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        height: 1.04,
                                        letterSpacing: -.8))),
                            const SizedBox(height: 6),
                            Flexible(
                                child: Text(subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                        height: 1.3))),
                          ])),
                ]);
              })),
              if (bottom != null) bottom!,
            ])),
      );
}

class _CircuitPainter extends CustomPainter {
  _CircuitPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width - 76, size.height - 68);
    final ring = Paint()
      ..color = color.withAlpha(70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final radius in [69.0, 84.0, 106.0]) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), .2,
          math.pi * 1.6, false, ring);
    }
    final lines = Paint()
      ..color = color.withAlpha(30)
      ..strokeWidth = 1;
    for (var i = 0; i < 6; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(
          Offset(x, size.height), Offset(x + 58, size.height * .45), lines);
    }
    final spark = Paint()..color = color.withAlpha(150);
    for (var i = 0; i < 14; i++) {
      canvas.drawCircle(
          Offset((i * 73.0 + 11) % size.width, (i * 37.0 + 13) % size.height),
          i.isEven ? 1.2 : .7,
          spark);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter oldDelegate) => color != oldDelegate.color;
}
