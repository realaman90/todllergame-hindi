import 'dart:math';
import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../theme/theme.dart';

class _Sparkle {
  final Offset direction;
  final double distance;
  final double radius;
  final Color color;

  const _Sparkle({
    required this.direction,
    required this.distance,
    required this.radius,
    required this.color,
  });
}

/// Celebration overlay: a sparkle burst and the earned sticker flying to
/// the sticker-count pill.
///
/// Auto-dismisses after the flight animation; tapping anywhere dismisses
/// early.
class StickerEarnedOverlay extends StatefulWidget {
  final Rect? sourceRect;
  final Rect? targetRect;
  final Widget sticker;
  final AudioService audio;
  final VoidCallback onDismiss;

  const StickerEarnedOverlay({
    super.key,
    this.sourceRect,
    this.targetRect,
    required this.sticker,
    required this.audio,
    required this.onDismiss,
  });

  @override
  State<StickerEarnedOverlay> createState() => _StickerEarnedOverlayState();
}

class _StickerEarnedOverlayState extends State<StickerEarnedOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Sparkle> _sparkles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _controller.addStatusListener(_onStatusChanged);

    final random = Random(widget.sticker.key?.hashCode ?? 42);
    const colors = [
      AppColors.marigold,
      AppColors.kumkum,
      AppColors.peacock,
      AppColors.mehndi,
    ];
    _sparkles = List.generate(14, (index) {
      final angle = random.nextDouble() * 2 * pi;
      return _Sparkle(
        direction: Offset(cos(angle), sin(angle)),
        distance: 60 + random.nextDouble() * 90,
        radius: 4 + random.nextDouble() * 5,
        color: colors[index % colors.length],
      );
    });

    widget.audio.playSfx('sticker_earned');
    _controller.forward();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onDismiss();
    }
  }

  void _dismissEarly() {
    _controller.stop();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  Rect _fallbackSource(Size size) => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: 80,
        height: 80,
      );

  Rect _fallbackTarget(Size size) => Rect.fromLTWH(
        size.width - 80,
        16,
        40,
        40,
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final source = widget.sourceRect ?? _fallbackSource(size);
    final target = widget.targetRect ?? _fallbackTarget(size);

    final rectAnimation = RectTween(begin: source, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    final sparkleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    return GestureDetector(
      onTap: _dismissEarly,
      behavior: HitTestBehavior.opaque,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: sparkleProgress,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _SparklePainter(
                    center: source.center,
                    progress: sparkleProgress.value,
                    sparkles: _sparkles,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: rectAnimation,
              builder: (context, child) {
                return Positioned.fromRect(
                  rect: rectAnimation.value!,
                  child: child!,
                );
              },
              child: widget.sticker,
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Offset center;
  final double progress;
  final List<_Sparkle> sparkles;

  _SparklePainter({
    required this.center,
    required this.progress,
    required this.sparkles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    for (final sparkle in sparkles) {
      final distance = sparkle.distance * progress;
      final offset = center + sparkle.direction * distance;
      final alpha = 1.0 - progress;
      final radius = sparkle.radius * (1.0 - progress * 0.4);
      final paint = Paint()
        ..color = sparkle.color.withValues(alpha: alpha.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.center != center;
  }
}
