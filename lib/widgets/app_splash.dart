import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Écran de démarrage animé, posé au-dessus de l'application au lancement.
///
/// Il prend le relais du splash natif (même fond vert, même logo) : le logo
/// grossit, le nom et le slogan apparaissent, puis l'écran s'efface en fondu.
class AppSplash extends StatefulWidget {
  const AppSplash({
    super.key,
    required this.child,
    this.minDuration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final Duration minDuration;

  @override
  State<AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<AppSplash> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final AnimationController _dots = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  bool _visible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.minDuration, () async {
      if (!mounted) return;
      await _exit.forward();
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _dots.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return widget.child;

    final logo = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final text = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 1, curve: Curves.easeOutCubic),
    );

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: FadeTransition(
            opacity: ReverseAnimation(_exit),
            child: Material(
              color: AppColors.primary,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: -120,
                    right: -140,
                    child: _circle(360, Colors.white.withValues(alpha: 0.05)),
                  ),
                  Positioned(
                    bottom: -90,
                    left: -110,
                    child: _circle(280, AppColors.accent.withValues(alpha: 0.12)),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FadeTransition(
                        opacity: logo,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.6, end: 1.0).animate(logo),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              size: 68,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      FadeTransition(
                        opacity: text,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(text),
                          child: Column(
                            children: [
                              const Text.rich(
                                TextSpan(
                                  text: 'Services ',
                                  children: [
                                    TextSpan(
                                      text: 'Immobilier',
                                      style: TextStyle(color: AppColors.accent),
                                    ),
                                  ],
                                ),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Acheter · Louer · Vendre en Tunisie',
                                style: TextStyle(
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 70,
                    child: AnimatedBuilder(
                      animation: _dots,
                      builder: (context, _) => Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(
                                  alpha: _dotOpacity(_dots.value, i),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Chaque point s'allume à son tour.
  double _dotOpacity(double t, int i) {
    final center = (i + 0.5) / 3;
    final d = (t - center).abs();
    return (1 - d * 2.1).clamp(0.3, 1.0);
  }

  Widget _circle(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}
