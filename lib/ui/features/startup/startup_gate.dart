import 'package:flutter/material.dart';
import '../../../data/repositories/game_repository.dart';
import '../../navigation/main_shell.dart';

/// Keeps the introduction in this app session, never in the resume lifecycle.
class StartupGate extends StatefulWidget {
  final GameRepository repository;
  const StartupGate({super.key, required this.repository});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> with WidgetsBindingObserver {
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _finish() {
    if (mounted && _showIntro) setState(() => _showIntro = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        // Start real requests while the logo plays, preserving the app's state.
        AbsorbPointer(
          absorbing: _showIntro,
          child: ExcludeSemantics(
            excluding: _showIntro,
            child: MainShell(repository: widget.repository),
          ),
        ),
        if (_showIntro) _BrandIntro(onFinished: _finish),
      ]);
}

class _BrandIntro extends StatefulWidget {
  final VoidCallback onFinished;
  const _BrandIntro({required this.onFinished});
  @override
  State<_BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<_BrandIntro>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFF030B10);
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onFinished();
        });
      }
    });
  late final Animation<double> _logoOpacity = _controller.drive(
    CurveTween(curve: const Interval(0, .24, curve: Curves.easeOut)),
  );
  late final Animation<double> _logoScale = _controller
      .drive(
        CurveTween(curve: const Interval(0, .42, curve: Curves.easeOutCubic)),
      )
      .drive(Tween(begin: .82, end: 1.0));
  late final Animation<double> _nameOpacity = _controller.drive(
    CurveTween(curve: const Interval(.40, .66, curve: Curves.easeOut)),
  );
  late final Animation<Offset> _nameSlide = _nameOpacity.drive(
    Tween(begin: const Offset(0, .35), end: Offset.zero),
  );
  late final Animation<double> _exitOpacity = _controller
      .drive(
        CurveTween(curve: const Interval(.86, 1, curve: Curves.easeInOut)),
      )
      .drive(Tween(begin: 1.0, end: 0.0));
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) _controller.duration = const Duration(milliseconds: 500);
    precacheImage(
            const AssetImage('assets/images/dinoxo_store_badge.png'), context)
        .then((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: const Key('brand-intro'),
        child: FadeTransition(
          opacity:
              _reduceMotion ? const AlwaysStoppedAnimation(1.0) : _exitOpacity,
          child: Scaffold(
            backgroundColor: _background,
            body: SafeArea(
              child: LayoutBuilder(builder: (context, constraints) {
                final size = (constraints.maxWidth * .64)
                    .clamp(120.0, 260.0)
                    .clamp(0.0, constraints.maxHeight * .48);
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FadeTransition(
                      opacity: _reduceMotion
                          ? const AlwaysStoppedAnimation(1.0)
                          : _logoOpacity,
                      child: ScaleTransition(
                        scale: _reduceMotion
                            ? const AlwaysStoppedAnimation(1.0)
                            : _logoScale,
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(shape: BoxShape.circle, boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF16BDF4).withAlpha(32),
                                blurRadius: 42,
                                spreadRadius: 3),
                          ]),
                          child: Image.asset(
                            'assets/images/dinoxo_store_badge.png',
                            key: const Key('brand-logo'),
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeTransition(
                      key: const Key('brand-name-reveal'),
                      opacity: _reduceMotion
                          ? const AlwaysStoppedAnimation(1.0)
                          : _nameOpacity,
                      child: SlideTransition(
                        position: _reduceMotion
                            ? const AlwaysStoppedAnimation(Offset.zero)
                            : _nameSlide,
                        child: const Text(
                          'dinoxo.Store',
                          style: TextStyle(
                              fontSize: 31,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Color(0xFFE4EDF3)),
                        ),
                      ),
                    ),
                  ]),
                );
              }),
            ),
          ),
        ),
      );
}
