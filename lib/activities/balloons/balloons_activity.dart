import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import '../activity.dart';

/// गुब्बारे — counting balloons (founder upgrade 2026-07-21).
///
/// Five balloons drift up, each carrying a numeral 1-5. Mithu asks for a
/// number ("तीन!"); popping the right one counts it aloud. Popping any
/// other balloon still pops satisfyingly (joy is never punished) — Mithu
/// just asks again. Three correct answers and the carousel moves on.
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
  final int number; // 1..5 numeral shown on the body
  double x; // 0..1
  double phase;
  double speed;
  final Color color;
  bool popped = false;

  _Balloon(this.id, this.number, this.x, this.phase, this.speed, this.color);
}

class BalloonsBody extends StatefulWidget {
  final ActivitySession session;

  const BalloonsBody({super.key, required this.session});

  @override
  State<BalloonsBody> createState() => _BalloonsBodyState();
}

class _BalloonsBodyState extends State<BalloonsBody>
    with SingleTickerProviderStateMixin {
  static const _asksToFinish = 3;
  static const _numberWords = ['ek', 'do', 'teen', 'chaar', 'paanch'];
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
  int _nextId = 0;
  int _ask = 0; // number Mithu currently wants (1..5)
  int _asksDone = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..addListener(_tick)
      ..repeat();
    for (var n = 1; n <= 5; n++) {
      _spawn(n, initial: true);
    }
    _nextAsk();
  }

  void _spawn(int number, {bool initial = false}) {
    _balloons.add(_Balloon(
      _nextId++,
      number,
      0.12 + _rng.nextDouble() * 0.76,
      initial ? _rng.nextDouble() * 0.6 : 0.0,
      0.35 + _rng.nextDouble() * 0.35,
      _colors[number % _colors.length],
    ));
  }

  void _nextAsk() {
    var next = 1 + _rng.nextInt(5);
    while (next == _ask) {
      next = 1 + _rng.nextInt(5);
    }
    _ask = next;
    widget.session.audio
        .playWord('family', _numberWords[_ask - 1], language: 'hi');
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      for (final b in _balloons) {
        b.phase += b.speed / (60 * 12); // rise per frame at 12s clock
      }
      final escaped = _balloons
          .where((b) => b.phase > 1.15 && !b.popped)
          .map((b) => b.number)
          .toList();
      _balloons.removeWhere((b) => b.phase > 1.15 || b.popped);
      // Every numeral is always in the air: escaped/popped ones respawn.
      final present = _balloons.map((b) => b.number).toSet();
      for (var n = 1; n <= 5; n++) {
        if (!present.contains(n) && !_finishing) _spawn(n);
      }
      escaped.clear();
    });
  }

  void _pop(_Balloon b, Size size) {
    if (b.popped || _finishing) return;
    b.popped = true;
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

    if (b.number == _ask) {
      _asksDone++;
      // Count it aloud — the number IS the reward.
      widget.session.audio
          .playWord('family', _numberWords[b.number - 1], language: 'hi');
      if (_asksDone >= _asksToFinish) {
        _finishing = true;
        Future.delayed(const Duration(milliseconds: 900), () async {
          await widget.session.audio.playPraise();
          if (mounted) widget.session.onSkip();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted && !_finishing) _nextAsk();
        });
      }
    } else {
      // Wrong balloon still pops joyfully; Mithu simply asks again.
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted && !_finishing) {
          widget.session.audio
              .playWord('family', _numberWords[_ask - 1], language: 'hi');
        }
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
                  number: b.number,
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
  final int number;

  _BalloonPainter({
    required this.color,
    required this.sway,
    required this.number,
  });

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
    // The numeral, big and friendly.
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, 44 - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter old) =>
      old.sway != sway || old.color != color || old.number != number;
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
