import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// A container with a smooth, flowing AI gradient animation.
/// Multiple gradient layers drift at different speeds for an organic look.
class AnimatedAiGradient extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const AnimatedAiGradient({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  @override
  State<AnimatedAiGradient> createState() => _AnimatedAiGradientState();
}

class _AnimatedAiGradientState extends State<AnimatedAiGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.isCircle ? BoxShape.circle : BoxShape.rectangle;
    final radius = widget.isCircle ? null : widget.borderRadius;

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Three layers drifting at different speeds & angles for organic flow
        final a1 = t * 2 * math.pi;
        final a2 = t * 2 * math.pi * 0.7 + 1.2;
        final a3 = t * 2 * math.pi * 1.3 + 2.8;

        // Smooth drifting focal points (Lissajous-like paths)
        final p1 = Alignment(
          math.sin(a1) * 0.8,
          math.cos(a1 * 0.6 + 0.5) * 0.8,
        );
        final p2 = Alignment(
          math.cos(a2) * 0.9,
          math.sin(a2 * 0.8 - 0.3) * 0.9,
        );
        final p3 = Alignment(
          math.sin(a3 * 0.5 + 1.0) * 0.7,
          math.cos(a3 * 0.9) * 0.7,
        );

        // Gently shifting stops for extra fluidity
        final shift = math.sin(a1 * 0.4) * 0.15;

        return Container(
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: radius,
          ),
          child: Stack(
            children: [
              // Base layer — purple to blue
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: p1,
                      radius: 1.2,
                      colors: const [
                        AppColors.aiPurple,
                        Color(0xFF6D28D9),
                      ],
                      stops: [0.0, 0.7 + shift],
                    ),
                  ),
                ),
              ),
              // Mid layer — red/magenta blob
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: p2,
                      radius: 0.9,
                      colors: [
                        AppColors.aiRed.withOpacity(0.85),
                        AppColors.aiRed.withOpacity(0.0),
                      ],
                      stops: [0.0, 0.65 - shift * 0.5],
                    ),
                  ),
                ),
              ),
              // Top layer — blue accent blob
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: p3,
                      radius: 0.85,
                      colors: [
                        AppColors.aiBlue.withOpacity(0.8),
                        AppColors.aiBlue.withOpacity(0.0),
                      ],
                      stops: [0.0, 0.6 + shift * 0.3],
                    ),
                  ),
                ),
              ),
              // Child on top
              if (child != null) child,
            ],
          ),
        );
      },
      child: Positioned.fill(child: Center(child: widget.child)),
    );
  }
}
