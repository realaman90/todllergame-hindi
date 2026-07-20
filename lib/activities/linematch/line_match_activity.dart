import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// रेखा मिलाओ — draw a line from a picture to its match.
///
/// Three pairs on screen (left column ↔ shuffled right column). The child
/// drags a finger from a left tile toward the matching right tile; the
/// line follows the finger. A correct connection locks with a glow and
/// speaks the word; a miss just fades away — no fail states, ever.
class LineMatchActivity extends Activity {
  const LineMatchActivity();

  @override
  String get id => 'linematch';

  @override
  String get titleHi => 'रेखा मिलाओ';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return LineMatchBody(session: session, key: ValueKey(session.scene.id));
  }
}

class LineMatchBody extends StatefulWidget {
  final ActivitySession session;

  const LineMatchBody({super.key, required this.session});

  @override
  State<LineMatchBody> createState() => _LineMatchBodyState();
}

class _FadingLine {
  final Offset from;
  final Offset to;
  final AnimationController controller;

  _FadingLine(this.from, this.to, this.controller);
}

class _LineMatchBodyState extends State<LineMatchBody>
    with TickerProviderStateMixin {
  static const _pairCount = 3;
  static const _tileSize = 104.0;
  // A toddler's release point can be well off the tile — accept anything
  // within this inflation of the target rect.
  static const _hitSlop = 44.0;

  late final List<SceneObject> _pairs;
  late final List<int> _rightOrder; // rightRow -> pair index
  final Set<int> _matched = {};

  int? _dragPair; // pair index being dragged from the left column
  final ValueNotifier<Offset?> _fingerPoint = ValueNotifier(null);
  final List<_FadingLine> _fadingLines = [];

  late final AnimationController _idleController;
  late final AnimationController _glowController;
  int? _lastMatched; // pair index for the glow pop

  @override
  void initState() {
    super.initState();
    final vocab = widget.session.vocab;
    _pairs = vocab.take(min(_pairCount, vocab.length)).toList();

    final rng = Random(widget.session.scene.id.hashCode ^ _pairs.length);
    _rightOrder = List.generate(_pairs.length, (i) => i);
    if (_pairs.length > 1) {
      do {
        _rightOrder.shuffle(rng);
      } while (_identityOrder(_rightOrder));
    }

    _idleController = AnimationController(
      duration: const Duration(milliseconds: 3400),
      vsync: this,
    )..repeat();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    widget.session.audio.playHost('mithu_game_linematch');
  }

  bool _identityOrder(List<int> order) {
    for (var i = 0; i < order.length; i++) {
      if (order[i] != i) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _idleController.dispose();
    _glowController.dispose();
    for (final line in _fadingLines) {
      line.controller.dispose();
    }
    _fingerPoint.dispose();
    super.dispose();
  }

  // ----- layout math (no keys, no render-object walks) -----

  Offset _leftCenter(Size size, int row) =>
      Offset(size.width * 0.24, _rowY(size, row));

  Offset _rightCenter(Size size, int row) =>
      Offset(size.width * 0.76, _rowY(size, row));

  double _rowY(Size size, int row) =>
      size.height * (0.22 + 0.28 * row);

  int? _hitLeft(Size size, Offset p) {
    int? best;
    double bestDist = double.infinity;
    const maxDist = _tileSize / 2 + _hitSlop;
    for (var row = 0; row < _pairs.length; row++) {
      if (_matched.contains(row)) continue;
      final d = (p - _leftCenter(size, row)).distance;
      if (d < bestDist && d <= maxDist) {
        bestDist = d;
        best = row;
      }
    }
    return best;
  }

  /// Nearest-center hit test: with generous slop the inflated rects of
  /// adjacent rows can overlap, and first-rect-wins could snap a release
  /// NEAR a wrong tile onto its neighbour. The nearest unmatched tile
  /// within range is the only honest answer.
  int? _hitRight(Size size, Offset p) {
    int? best;
    double bestDist = double.infinity;
    const maxDist = _tileSize / 2 + _hitSlop;
    for (var row = 0; row < _rightOrder.length; row++) {
      final pair = _rightOrder[row];
      if (_matched.contains(pair)) continue;
      final d = (p - _rightCenter(size, row)).distance;
      if (d < bestDist && d <= maxDist) {
        bestDist = d;
        best = pair;
      }
    }
    return best;
  }

  int _rightRowOf(int pair) => _rightOrder.indexOf(pair);

  // ----- gestures -----

  void _onPanStart(Size size, DragStartDetails d) {
    final hit = _hitLeft(size, d.localPosition);
    if (hit == null) return;
    setState(() => _dragPair = hit);
    _fingerPoint.value = d.localPosition;
    // Speaking on grab is the audio affordance: she hears what she holds.
    widget.session.audio.playWord(
      widget.session.scene.id,
      _pairs[hit].slug,
      language: 'hi',
    );
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_dragPair == null) return;
    _fingerPoint.value = d.localPosition;
  }

  void _onPanEnd(Size size) {
    final pair = _dragPair;
    final at = _fingerPoint.value;
    if (pair == null) return;

    final target = at == null ? null : _hitRight(size, at);
    if (target != null && target == pair) {
      // Correct: lock the line, glow, speak again.
      setState(() {
        _matched.add(pair);
        _lastMatched = pair;
        _dragPair = null;
      });
      _glowController.forward(from: 0.0);
      widget.session.audio.playWord(
        widget.session.scene.id,
        _pairs[pair].slug,
        language: 'hi',
      );
      if (_matched.length == _pairs.length) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) widget.session.onComplete();
        });
      }
    } else {
      // Miss: the line melts away, and if the child clearly chose a wrong
      // tile, Mithu explains warmly — "यह [that word] नहीं है!" (founder
      // request 2026-07-20: informative correction, never a buzzer).
      if (target != null) {
        widget.session.audio.playWrongMatch(
          widget.session.scene.id,
          _pairs[target].slug,
          language: 'hi',
        );
      }
      final from = _leftCenter(size, pair);
      final to = at ?? from;
      final controller = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      );
      final line = _FadingLine(from, to, controller);
      setState(() {
        _fadingLines.add(line);
        _dragPair = null;
      });
      controller.forward().whenCompleteOrCancel(() {
        if (!mounted) return;
        setState(() => _fadingLines.remove(line));
        controller.dispose();
      });
    }
    _fingerPoint.value = null;
  }

  // ----- build -----

  @override
  Widget build(BuildContext context) {
    final scene = widget.session.scene;
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onPanStart: (d) => _onPanStart(size, d),
          onPanUpdate: _onPanUpdate,
          onPanEnd: (_) => _onPanEnd(size),
          onPanCancel: () => _onPanEnd(size),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Locked + fading lines live UNDER the tiles.
              AnimatedBuilder(
                animation: Listenable.merge(
                    [_glowController, ..._fadingLines.map((l) => l.controller)]),
                builder: (context, _) => CustomPaint(
                  size: size,
                  painter: _LockedLinesPainter(
                    lines: [
                      for (final pair in _matched)
                        (
                          _leftCenter(size, pair),
                          _rightCenter(size, _rightRowOf(pair)),
                        ),
                    ],
                    fading: [
                      for (final l in _fadingLines)
                        (l.from, l.to, 1.0 - l.controller.value),
                    ],
                    color: deepColor,
                  ),
                ),
              ),
              // The live finger line repaints on its own notifier only.
              ValueListenableBuilder<Offset?>(
                valueListenable: _fingerPoint,
                builder: (context, finger, _) {
                  if (_dragPair == null || finger == null) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    size: size,
                    painter: _ActiveLinePainter(
                      from: _leftCenter(size, _dragPair!),
                      to: finger,
                      color: themeColor,
                    ),
                  );
                },
              ),
              for (var row = 0; row < _pairs.length; row++) ...[
                _tile(size, _pairs[row], _leftCenter(size, row),
                    matched: _matched.contains(row),
                    phase: row * 1.1,
                    themeColor: themeColor,
                    deepColor: deepColor,
                    glowing: _lastMatched == row),
                _tile(
                    size,
                    _pairs[_rightOrder[row]],
                    _rightCenter(size, row),
                    matched: _matched.contains(_rightOrder[row]),
                    phase: row * 1.1 + 0.5,
                    themeColor: themeColor,
                    deepColor: deepColor,
                    glowing: _lastMatched == _rightOrder[row]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tile(Size size, SceneObject object, Offset center,
      {required bool matched,
      required double phase,
      required Color themeColor,
      required Color deepColor,
      required bool glowing}) {
    Widget tile = ArtTile(
      imagePath: 'assets/art/${object.art}',
      wordHi: object.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: _tileSize,
      showLabel: false,
    );

    tile = AnimatedBuilder(
      animation: Listenable.merge([_idleController, _glowController]),
      builder: (context, child) {
        var scale = 1.0;
        if (!matched) {
          final t = _idleController.value * 2 * pi + phase;
          scale = 1.0 + 0.05 * sin(t);
        } else if (glowing) {
          // Small bounded pop when just matched.
          final g = _glowController.value;
          scale = 1.0 + 0.18 * sin(g * pi);
        }
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: matched && !glowing ? 0.85 : 1.0,
            child: child,
          ),
        );
      },
      child: tile,
    );

    return Positioned(
      left: center.dx - _tileSize / 2,
      top: center.dy - _tileSize / 2,
      child: IgnorePointer(
        child: PopIn(delayMs: 100 + (phase * 120).round(), child: tile),
      ),
    );
  }
}

class _LockedLinesPainter extends CustomPainter {
  final List<(Offset, Offset)> lines;
  final List<(Offset, Offset, double)> fading;
  final Color color;

  _LockedLinesPainter({
    required this.lines,
    required this.fading,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in lines) {
      canvas.drawLine(from, to, paint);
    }
    for (final (from, to, opacity) in fading) {
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = color.withValues(alpha: 0.6 * opacity.clamp(0.0, 1.0))
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LockedLinesPainter old) =>
      old.lines.length != lines.length || old.fading.length != fading.length ||
      old.fading.toString() != fading.toString();
}

class _ActiveLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;

  _ActiveLinePainter({
    required this.from,
    required this.to,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color.withValues(alpha: 0.85)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    // A friendly dot under the finger.
    canvas.drawCircle(to, 13, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _ActiveLinePainter old) =>
      old.from != from || old.to != to;
}
