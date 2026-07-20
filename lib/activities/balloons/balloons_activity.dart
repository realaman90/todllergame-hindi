import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../activity.dart';

/// गुब्बारे — a satisfying balloon-popping breather between games.
///
/// No goal, no instruction, no fail: balloons drift up, tapping one pops
/// it with a burst and a pop sound. After enough pops the carousel moves
/// on by itself. Pure joy as a palate cleanser.
class BalloonsActivity extends Activity {
  const BalloonsActivity();

  @override
  String get id => 'balloons';

  @override
  String get titleHi => 'गुब्बारे!';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return BalloonsBody(session: session, key: UniqueKey());
  }
}

class _Balloon {
  final int id;
  double x; // 0..1
  double phase;
  double speed;
  final Color color;
  bool popped = false;

  _Balloon(this.id, this.x, this.phase, this.speed, this.color);
}

class BalloonsBody extends StatefulWidget {
  final ActivitySession session;

  const BalloonsBody({super.key, required this.session});

  @override
  State<BalloonsBody> createState() => _BalloonsBodyState();
}

class _BalloonsBodyState extends State<BalloonsBody>
    with SingleTickerProviderStateMixin {
  static const _popsToFinish = 6;
  static const _colors = [
    AppColors.marigold,
    AppColors.peacock,
    AppColors.kumkum,
    AppColors.mehndi,
    AppColors.marigoldDeep,
  ];

  late final AnimationController _clock;
  final _rng = Random();
  final List<_Balloon> _balloons = [];
  final List<(Offset, Color, AnimationController)> _bursts = [];
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
    for (var i = 0; i < 5; i++) {
      _spawn(initial: true);
    }
  }

  void _spawn({bool initial = false}) {
    _balloons.add(_Balloon(
      _nextId++,
      0.12 + _rng.nextDouble() * 0.76,
      initial ? _rng.nextDouble() : 0.0,
      0.55 + _rng.nextDouble() * 0.6,
      _colors[_nextId % _colors.length],
    ));
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final b in _balloons) {
        b.phase += b.speed / (60 * 12); // rise per frame at 12s clock
      }
      _balloons.removeWhere((b) {
        if (b.phase > 1.15 && !b.popped) {
          // Floated away: it just comes back as a new balloon.
          return true;
        }
        return b.popped;
      });
      while (_balloons.length < 5 && !_finishing) {
        _spawn();
      }
    });
  }

  void _pop(_Balloon b, Size size) {
    if (b.popped || _finishing) return;
    b.popped = true;
    _pops++;
    widget.session.audio.playSfx('tap_pop');

    final at = Offset(
      b.x * size.width,
      size.height * (1.05 - b.phase * 1.1),
    );
    final c = AnimationController(
        duration: const Duration(milliseconds: 450), vsync: this);
    _bursts.add((at, b.color, c));
    c.forward().whenCompleteOrCancel(() {
      if (mounted) {
        setState(() => _bursts.removeWhere((e) => e.$3 == c));
        c.dispose();
      }
    });

    if (_pops >= _popsToFinish && !_finishing) {
      _finishing = true;
      Future.delayed(const Duration(milliseconds: 700), () {
        // A breather earns no sticker fuss — just gently move on.
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
        for (final b in _balloons.where((b) => !b.popped))
          Positioned(
            left: b.x * size.width - 44,
            top: size.height * (1.05 - b.phase * 1.1) - 55,
            child: GestureDetector(
              onTap: () => _pop(b, size),
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                size: const Size(88, 120),
                painter: _BalloonPainter(
                  color: b.color,
                  sway: sin(b.phase * 14 + b.id),
                ),
              ),
            ),
          ),
        for (final (at, color, c) in _bursts)
          Positioned(
            left: at.dx - 60,
            top: at.dy - 60,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: c,
                builder: (context, _) => CustomPaint(
                  size: const Size(120, 120),
                  painter: _BurstPainter(progress: c.value, color: color),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}

class _BalloonPainter extends CustomPainter {
  final Color color;
  final double sway;

  _BalloonPainter({required this.color, required this.sway});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + sway * 4;
    final body = Rect.fromCenter(
        center: Offset(cx, 44), width: 74, height: 88);
    // String first (behind).
    final string = Path()..moveTo(cx, 88);
    string.quadraticBezierTo(cx + 8 * sway, 100, cx, 118);
    canvas.drawPath(
        string,
        Paint()
          ..color = AppColors.ink.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Body.
    canvas.drawOval(body, Paint()..color = color);
    // Knot.
    canvas.drawCircle(Offset(cx, 89), 5, Paint()..color = color);
    // Highlight.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 16, 26), width: 20, height: 30),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter old) =>
      old.sway != sway || old.color != color;
}

class _BurstPainter extends CustomPainter {
  final double progress;
  final Color color;

  _BurstPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final alpha = (1 - progress).clamp(0.0, 1.0);
    for (var i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final d = 14 + 44 * progress;
      canvas.drawCircle(
        center + Offset(cos(angle), sin(angle)) * d,
        6 * (1 - progress * 0.6),
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) =>
      old.progress != progress;
}
