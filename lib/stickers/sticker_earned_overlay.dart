import 'dart:math';
import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

class _ConfettiPiece {
  final double x; // 0..1 across the screen
  final double fallSpeed; // relative
  final double size;
  final double spin;
  final Color color;

  const _ConfettiPiece({
    required this.x,
    required this.fallSpeed,
    required this.size,
    required this.spin,
    required this.color,
  });
}

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
  late final List<_ConfettiPiece> _confetti;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _controller.addStatusListener(_onStatusChanged);

    final random = Random(); // varied every time — fixed seed made all celebrations identical
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
    _confetti = List.generate(26, (index) {
      return _ConfettiPiece(
        x: random.nextDouble(),
        fallSpeed: 0.65 + random.nextDouble() * 0.6,
        size: 7 + random.nextDouble() * 7,
        spin: (random.nextDouble() - 0.5) * 9,
        color: colors[index % colors.length],
      );
    });

    widget.audio.playStickerEarned();
    _controller.forward();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Arrival beat: the sticker lands somewhere real, audibly.
      widget.audio.playSfx('ding_sticker');
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
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _ConfettiPainter(
                    progress: _controller.value,
                    pieces: _confetti,
                  ),
                );
              },
            ),
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
            // Mithu appears and celebrates every win, bottom-left.
            Positioned(
              left: 30,
              bottom: 24,
              child: ListenableBuilder(
                listenable: widget.audio,
                builder: (context, _) => MithuTalking(
                  isPlaying: widget.audio.isPlaying,
                  voicePath: widget.audio.currentVoicePath,
                  size: 150,
                ),
              ),
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

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter({required this.progress, required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    for (final piece in pieces) {
      final y = (-0.08 + progress * 1.25 * piece.fallSpeed) * size.height;
      if (y > size.height + 20) continue;
      final x = piece.x * size.width +
          18 * sin(progress * 6 * pi * piece.fallSpeed + piece.x * 10);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * progress * pi);
      final paint = Paint()
        ..color = piece.color.withValues(
            alpha: (1.4 - progress).clamp(0.0, 1.0) * 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: piece.size, height: piece.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
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
