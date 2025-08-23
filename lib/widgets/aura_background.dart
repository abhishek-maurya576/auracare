import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Animated background with liquid blob morphing effect
class AuraBackground extends StatefulWidget {
  const AuraBackground({super.key});

  @override
  State<AuraBackground> createState() => _AuraBackgroundState();
}

class _AuraBackgroundState extends State<AuraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: BlobPainter(_animation.value),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for liquid blob effects
class BlobPainter extends CustomPainter {
  final double animationValue;

  BlobPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    _paintBlob1(canvas, size);
    _paintBlob2(canvas, size);
    _paintBlob3(canvas, size);
  }

  void _paintBlob1(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.auraGradient1.createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.3, size.height * 0.2),
          radius: size.width * 0.4,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final path = Path();
    final centerX = size.width * 0.2;
    final centerY = size.height * 0.25 + (20 * animationValue);

    path.moveTo(centerX, centerY);
    path.cubicTo(
      size.width * 0.5,
      size.height * 0.10,
      size.width * 0.6,
      size.height * 0.35 + (10 * animationValue),
      size.width * 0.35,
      size.height * 0.40,
    );
    path.cubicTo(
      size.width * 0.10,
      size.height * 0.45,
      size.width * 0.05,
      size.height * 0.20,
      centerX,
      centerY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  void _paintBlob2(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppColors.auraGradient2.createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.7),
          radius: size.width * 0.4,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    final path = Path();
    final centerX = size.width * 0.85;
    final centerY = size.height * 0.75 - (18 * animationValue);

    path.moveTo(centerX, centerY);
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.55,
      size.width * 0.95,
      size.height * 0.45,
      size.width * 0.88,
      size.height * 0.70,
    );
    path.cubicTo(
      size.width * 0.80,
      size.height * 0.92,
      size.width * 0.98,
      size.height * 0.90,
      centerX,
      centerY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  void _paintBlob3(Canvas canvas, Size size) {
    // Additional smaller blob for more depth
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [AppColors.accentTeal, AppColors.accentBlue],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.8),
          radius: size.width * 0.2,
        ),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    final path = Path();
    final centerX = size.width * 0.1 + (15 * animationValue);
    final centerY = size.height * 0.8;

    path.moveTo(centerX, centerY);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.3,
      size.height * 0.7,
      size.width * 0.15,
      size.height * 0.75,
    );
    path.cubicTo(
      size.width * 0.05,
      size.height * 0.85,
      size.width * 0.0,
      size.height * 0.9,
      centerX,
      centerY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// Breathing dots animation for calm now button
class BreathingDots extends StatefulWidget {
  final Color color;
  final double size;

  const BreathingDots({
    super.key,
    this.color = AppColors.accentTeal,
    this.size = 8,
  });

  @override
  State<BreathingDots> createState() => _BreathingDotsState();
}

class _BreathingDotsState extends State<BreathingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // 4s expand → 7s hold → 8s contract (breathing pattern)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19), // 4 + 7 + 8
    )..repeat();

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 4.0, // 4 seconds expand
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 7.0, // 7 seconds hold
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 8.0, // 8 seconds contract
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.size * 0.2),
              child: Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withAlpha((255 * 0.7).toInt()),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

