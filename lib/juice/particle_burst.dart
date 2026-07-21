import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One shared mid-round celebration burst (feel rule F18): few, BIG,
/// slow pieces a 3-year-old can visually track — never a screenful of
/// fast sparks.
///
/// Place inside a Stack; it fills its parent and ignores pointers.
/// Increment [trigger] to replay a burst centered on [at] (parent-local
/// pixels). `trigger == 0` paints nothing.
class ParticleBurst extends StatefulWidget {
  final int trigger;
  final Offset at;
  final List<Color> colors;
  final int pieces;

  const ParticleBurst({
    super.key,
    required this.trigger,
    required this.at,
    this.colors = const [
      AppColors.marigold,
      AppColors.kumkum,
      AppColors.peacock,
      AppColors.mehndi,
    ],
    this.pieces = 14,
  });

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _Piece {
  final Offset velocity; // px/s
  final double size;
  final double spin;
  final Color color;

  const _Piece(this.velocity, this.size, this.spin, this.color);
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  List<_Piece> _pieces = const [];

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        duration: const Duration(milliseconds: 1300), vsync: this);
  }

  @override
  void didUpdateWidget(covariant ParticleBurst old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger > 0) {
      final rng = Random(widget.trigger);
      _pieces = List.generate(widget.pieces, (i) {
        // Mostly upward fan; gravity brings them down slowly.
        final angle = -pi / 2 + (rng.nextDouble() - 0.5) * pi * 1.2;
        final speed = 140 + rng.nextDouble() * 160;
        return _Piece(
          Offset(cos(angle), sin(angle)) * speed,
          9.0 + rng.nextDouble() * 7.0,
          (rng.nextDouble() - 0.5) * 6,
          widget.colors[i % widget.colors.length],
        );
      });
      _c.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => CustomPaint(
              painter: _c.isAnimating
                  ? _BurstPainter(
                      t: _c.value, origin: widget.at, pieces: _pieces)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  static const _gravity = 260.0; // px/s^2 — gentle fall
  final double t;
  final Offset origin;
  final List<_Piece> pieces;

  _BurstPainter({required this.t, required this.origin, required this.pieces});

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = t * 1.3;
    final alpha = (1.3 - t * 1.3).clamp(0.0, 1.0);
    for (final p in pieces) {
      final pos = origin +
          p.velocity * seconds +
          Offset(0, 0.5 * _gravity * seconds * seconds);
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(p.spin * t * pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.65),
          const Radius.circular(2),
        ),
        Paint()..color = p.color.withValues(alpha: alpha * 0.9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}
