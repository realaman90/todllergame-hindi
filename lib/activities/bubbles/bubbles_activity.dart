import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../activity.dart';

/// बुलबुले — soap-bubble popping, the second breather type.
///
/// Nothing to learn, nothing to get wrong: iridescent bubbles wobble
/// upward, a tap bursts them into droplets. Eight pops and the carousel
/// drifts on. Pure fidget joy.
class BubblesActivity extends Activity {
  const BubblesActivity();

  @override
  String get id => 'bubbles';

  @override
  String get titleHi => 'बुलबुले!';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return BubblesBody(session: session, key: UniqueKey());
  }
}

class _Bubble {
  final int id;
  double x;
  double phase;
  double speed;
  double size;
  bool popped = false;

  _Bubble(this.id, this.x, this.phase, this.speed, this.size);
}

class BubblesBody extends StatefulWidget {
  final ActivitySession session;

  const BubblesBody({super.key, required this.session});

  @override
  State<BubblesBody> createState() => _BubblesBodyState();
}

class _BubblesBodyState extends State<BubblesBody>
    with SingleTickerProviderStateMixin {
  static const _popsToFinish = 8;

  late final AnimationController _clock;
  final _rng = Random();
  final List<_Bubble> _bubbles = [];
  final List<(Offset, double, AnimationController)> _bursts = [];
  int _pops = 0;
  int _nextId = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..addListener(_tick)
      ..repeat();
    for (var i = 0; i < 6; i++) {
      _spawn(initial: true);
    }
  }

  void _spawn({bool initial = false}) {
    _bubbles.add(_Bubble(
      _nextId++,
      0.08 + _rng.nextDouble() * 0.84,
      initial ? _rng.nextDouble() * 0.8 : 0.0,
      0.4 + _rng.nextDouble() * 0.5,
      52.0 + _rng.nextDouble() * 46.0,
    ));
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final b in _bubbles) {
        b.phase += b.speed / (60 * 12);
        b.x += sin(b.phase * 18 + b.id) * 0.0007;
      }
      _bubbles.removeWhere((b) => b.phase > 1.15 || b.popped);
      while (_bubbles.length < 6 && !_finishing) {
        _spawn();
      }
    });
  }

  void _pop(_Bubble b, Size size) {
    if (b.popped || _finishing) return;
    b.popped = true;
    _pops++;
    widget.session.audio.playTapNote();

    final at = Offset(
      b.x * size.width,
      size.height * (1.08 - b.phase * 1.15),
    );
    final c = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _bursts.add((at, b.size, c));
    c.forward().whenCompleteOrCancel(() {
      if (mounted) {
        setState(() => _bursts.removeWhere((e) => e.$3 == c));
        c.dispose();
      }
    });

    if (_pops >= _popsToFinish && !_finishing) {
      _finishing = true;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) widget.session.onSkip();
      });
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    for (final e in _bursts) {
      e.$3.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return Stack(children: [
        for (final b in _bubbles.where((b) => !b.popped))
          Positioned(
            left: b.x * size.width - b.size / 2,
            top: size.height * (1.08 - b.phase * 1.15) - b.size / 2,
            child: GestureDetector(
              onTapDown: (_) => _pop(b, size),
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                size: Size(b.size, b.size),
                painter: _BubblePainter(
                    wobble: sin(b.phase * 22 + b.id)),
              ),
            ),
          ),
        for (final (at, bsize, c) in _bursts)
          Positioned(
            left: at.dx - bsize,
            top: at.dy - bsize,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: c,
                builder: (context, _) => CustomPaint(
                  size: Size(bsize * 2, bsize * 2),
                  painter:
                      _DropletPainter(progress: c.value, radius: bsize / 2),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}

class _BubblePainter extends CustomPainter {
  final double wobble;

  _BubblePainter({required this.wobble});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    // Soap film: translucent peacock with a faint rainbow rim.
    canvas.drawCircle(
      c,
      r * (1 + wobble * 0.03),
      Paint()..color = AppColors.peacock.withValues(alpha: 0.12),
    );
    canvas.drawCircle(
      c,
      r * (1 + wobble * 0.03),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = SweepGradient(colors: [
          AppColors.peacock.withValues(alpha: 0.55),
          AppColors.kumkum.withValues(alpha: 0.45),
          AppColors.marigold.withValues(alpha: 0.45),
          AppColors.peacock.withValues(alpha: 0.55),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    // Highlight crescent.
    canvas.drawCircle(
      c.translate(-r * 0.35, -r * 0.4),
      r * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.wobble != wobble;
}

class _DropletPainter extends CustomPainter {
  final double progress;
  final double radius;

  _DropletPainter({required this.progress, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final alpha = (1 - progress).clamp(0.0, 1.0);
    for (var i = 0; i < 7; i++) {
      final angle = i * 2 * pi / 7;
      final d = radius * (0.4 + 1.1 * progress);
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * d + Offset(0, 26 * progress * progress),
        4.5 * (1 - progress * 0.5),
        Paint()..color = AppColors.peacock.withValues(alpha: alpha * 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DropletPainter old) =>
      old.progress != progress;
}
