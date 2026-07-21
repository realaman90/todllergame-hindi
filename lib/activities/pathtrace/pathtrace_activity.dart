import 'dart:math';

import 'package:flutter/material.dart';

import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../activity.dart';

/// रास्ता दिखाओ (Path trace, format #31): guide the puppy home along a
/// wiggly dotted road with a finger. Progress only moves forward, dots
/// light up as they're passed, and reaching the house earns the win.
/// Pre-writing motor skill dressed as a walk home.
class PathTraceActivity extends Activity {
  const PathTraceActivity();

  @override
  String get id => 'pathtrace';

  @override
  String get titleHi => 'रास्ता दिखाओ';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return PathBody(session: session, key: UniqueKey());
  }
}

class PathBody extends StatefulWidget {
  final ActivitySession session;

  const PathBody({super.key, required this.session});

  @override
  State<PathBody> createState() => _PathBodyState();
}

class _PathBodyState extends State<PathBody>
    with SingleTickerProviderStateMixin {
  static const _samplesN = 90;
  static const _grabRadius = 70.0;

  double _progress = 0.0; // 0..1 along the path, monotonic
  bool _done = false;
  int _lastNoteDecile = 0;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;

  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    widget.session.audio.playHost('mithu_game_path');
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  /// A gentle two-hump wave from left-center to the house on the right.
  Offset _pointAt(Size size, double t) {
    final x = size.width * (0.12 + 0.70 * t);
    final y = size.height *
        (0.52 + 0.20 * sin(t * pi * 2) * (1 - t * 0.4) - 0.06 * t);
    return Offset(x, y);
  }

  void _onPan(Size size, Offset p) {
    if (_done) return;
    // Nearest sample at-or-ahead of current progress within grab range.
    var best = -1;
    var bestD = _grabRadius;
    final from = (_progress * _samplesN).floor();
    final to = min(_samplesN, from + 14); // can't skip ahead over the wave
    for (var i = from; i <= to; i++) {
      final d = (p - _pointAt(size, i / _samplesN)).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best < 0) return;
    final newProgress = best / _samplesN;
    if (newProgress <= _progress) return;
    setState(() => _progress = newProgress);
    // A rising note every 10% — walking home plays a little tune.
    final decile = (newProgress * 10).floor();
    if (decile > _lastNoteDecile) {
      _lastNoteDecile = decile;
      widget.session.audio.playTapNote();
    }
    if (newProgress >= 0.97) _arrive(size);
  }

  Future<void> _arrive(Size size) async {
    if (_done) return;
    setState(() {
      _done = true;
      _progress = 1.0;
      _burstTrigger++;
      _burstAt = _pointAt(size, 1.0);
    });
    widget.session.audio.playSfx('ding_sticker');
    await widget.session.audio.playWord('farm', 'kutta', language: 'hi');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) widget.session.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(widget.session.scene.theme);

    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final dogAt = _pointAt(size, _progress);

      return GestureDetector(
        onPanDown: (d) => _onPan(size, d.localPosition),
        onPanUpdate: (d) => _onPan(size, d.localPosition),
        behavior: HitTestBehavior.opaque,
        child: Stack(children: [
          // Dotted road; passed dots light up in the scene color.
          CustomPaint(
            size: size,
            painter: _RoadPainter(
              pointAt: (t) => _pointAt(size, t),
              progress: _progress,
              color: themeColor,
            ),
          ),
          // Home, waiting at the end of the road.
          Positioned(
            left: _pointAt(size, 1.0).dx - 8,
            top: _pointAt(size, 1.0).dy - 56,
            child: AnimatedBuilder(
              animation: _idle,
              builder: (context, child) => Transform.scale(
                scale: _done
                    ? 1.0 + 0.10 * sin(_idle.value * 2 * pi * 3)
                    : 1.0 + 0.03 * sin(_idle.value * 2 * pi),
                child: child,
              ),
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: const DecorationImage(
                    image: AssetImage('assets/art/scenes/house_thumb.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // The puppy walks the road under the finger.
          Positioned(
            left: dogAt.dx - 40,
            top: dogAt.dy - 40,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _idle,
                builder: (context, child) => Transform.rotate(
                  angle: 0.06 * sin(_idle.value * 2 * pi * 4),
                  child: child,
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: const DecorationImage(
                      image:
                          AssetImage('assets/art/objects/farm_kutta.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ParticleBurst(trigger: _burstTrigger, at: _burstAt),
        ]),
      );
    });
  }
}

class _RoadPainter extends CustomPainter {
  final Offset Function(double t) pointAt;
  final double progress;
  final Color color;

  _RoadPainter({
    required this.pointAt,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dots = 26;
    for (var i = 0; i <= dots; i++) {
      final t = i / dots;
      final passed = t <= progress;
      canvas.drawCircle(
        pointAt(t),
        passed ? 8.0 : 6.0,
        Paint()
          ..color = passed
              ? color
              : AppColors.ink.withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) =>
      old.progress != progress || old.color != color;
}
