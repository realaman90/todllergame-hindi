import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// पोंछो और देखो (Wipe & reveal, format #34): a steamed-up window hides
/// an object; rubbing with a finger clears the frost. At ~55% clear the
/// frost melts away, the object pops, and Mithu names it. Hugely
/// satisfying, zero fail states.
class WipeRevealActivity extends Activity {
  const WipeRevealActivity();

  @override
  String get id => 'wipereveal';

  @override
  String get titleHi => 'पोंछो और देखो';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return WipeBody(session: session, key: UniqueKey());
  }
}

class WipeBody extends StatefulWidget {
  final ActivitySession session;

  const WipeBody({super.key, required this.session});

  @override
  State<WipeBody> createState() => _WipeBodyState();
}

class _WipeBodyState extends State<WipeBody>
    with SingleTickerProviderStateMixin {
  static const _windowSize = 300.0;
  static const _wipeRadius = 36.0;
  static const _revealAt = 0.55;
  static const _gridN = 10;

  late final SceneObject _object;
  final List<Offset> _wipes = [];
  final Set<int> _cells = {};
  bool _revealed = false;
  int _sfxCounter = 0;
  late final AnimationController _melt;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.session.scene.id.hashCode ^ 0x71be);
    final vocab = List.of(widget.session.vocab)..shuffle(rng);
    _object = vocab.first;
    _melt = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    widget.session.audio.playHost('mithu_game_wipe');
  }

  @override
  void dispose() {
    _melt.dispose();
    super.dispose();
  }

  void _wipeAt(Offset local) {
    if (_revealed) return;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > _windowSize ||
        local.dy > _windowSize) {
      return;
    }
    if (_wipes.isNotEmpty && (local - _wipes.last).distance < 14) return;
    setState(() => _wipes.add(local));
    // Soft squeaky wipes, pitch-wandering so rubbing sounds alive.
    if (_sfxCounter++ % 5 == 0) {
      widget.session.audio
          .playSfx('tap_soft', rate: 0.9 + (_sfxCounter % 4) * 0.08);
    }
    // Coverage bookkeeping: a wipe clears its cell + close neighbours.
    final cx = (local.dx / _windowSize * _gridN).floor().clamp(0, _gridN - 1);
    final cy = (local.dy / _windowSize * _gridN).floor().clamp(0, _gridN - 1);
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final x = cx + dx, y = cy + dy;
        if (x >= 0 && x < _gridN && y >= 0 && y < _gridN) {
          _cells.add(y * _gridN + x);
        }
      }
    }
    if (_cells.length / (_gridN * _gridN) >= _revealAt) {
      _reveal();
    }
  }

  Future<void> _reveal() async {
    if (_revealed) return;
    setState(() => _revealed = true);
    _melt.forward();
    widget.session.audio.playSfx('ding_sticker');
    await widget.session.audio
        .playWord(widget.session.scene.id, _object.slug, language: 'hi');
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.session.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.session.scene;
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);

    return Center(
      child: GestureDetector(
        onPanDown: (d) => _wipeAt(d.localPosition),
        onPanUpdate: (d) => _wipeAt(d.localPosition),
        child: SizedBox(
          width: _windowSize,
          height: _windowSize,
          child: Stack(children: [
            // The hidden object, framed like a window.
            Center(
              child: _revealed
                  ? PopIn(
                      child: ArtTile(
                        imagePath: 'assets/art/${_object.art}',
                        wordHi: _object.wordHi,
                        color: themeColor,
                        deepColor: deepColor,
                        size: 220,
                        showLabel: true,
                      ),
                    )
                  : ArtTile(
                      imagePath: 'assets/art/${_object.art}',
                      color: themeColor,
                      deepColor: deepColor,
                      size: 220,
                      showLabel: false,
                    ),
            ),
            // Frost on top; wiped circles punch through; melts on reveal.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _melt,
                builder: (context, _) => Opacity(
                  opacity: 1.0 - _melt.value,
                  child: CustomPaint(
                    size: const Size(_windowSize, _windowSize),
                    painter: _FrostPainter(
                        wipes: List.of(_wipes), themeColor: themeColor),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FrostPainter extends CustomPainter {
  final List<Offset> wipes;
  final Color themeColor;

  _FrostPainter({required this.wipes, required this.themeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.saveLayer(rect, Paint());
    // Steamy pane: milky white with a whisper of the scene color.
    canvas.clipRRect(rrect);
    canvas.drawRect(
        rect,
        Paint()
          ..color =
              Color.lerp(Colors.white, themeColor, 0.10)!.withValues(alpha: 0.96));
    // Fixed soft blobs read as condensation texture.
    for (var i = 0; i < 12; i++) {
      final fx = (i * 41 % 97) / 97;
      final fy = (i * 61 % 89) / 89;
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        20 + (i * 13 % 22).toDouble(),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
    // Finger wipes punch clear holes with soft edges.
    for (final w in wipes) {
      canvas.drawCircle(
        w,
        _WipeBodyState._wipeRadius,
        Paint()
          ..blendMode = BlendMode.clear
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FrostPainter old) =>
      old.wipes.length != wipes.length;
}
