import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// क्या ग़ायब? (What's missing, format #17): three objects appear and are
/// named; a paper cloth slides over one; the child picks which friend is
/// hiding from two big choices. First memory game — warm scaffold, no
/// fail states.
class WhatsMissingActivity extends Activity {
  const WhatsMissingActivity();

  @override
  String get id => 'missing';

  @override
  String get titleHi => 'क्या ग़ायब?';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return MissingBody(session: session, key: UniqueKey());
  }
}

enum _MissingPhase { showing, covered, solved }

class MissingBody extends StatefulWidget {
  final ActivitySession session;

  const MissingBody({super.key, required this.session});

  @override
  State<MissingBody> createState() => _MissingBodyState();
}

class _MissingBodyState extends State<MissingBody>
    with SingleTickerProviderStateMixin {
  static const _tile = 108.0;

  late final List<SceneObject> _shown;
  late final int _hiddenIndex;
  late final List<SceneObject> _choices; // hidden + one visible decoy
  var _phase = _MissingPhase.showing;
  late final NudgeTimer _nudge;
  bool _hinting = false;
  int _wrongs = 0;
  int? _wobbling;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;
  final GlobalKey _hiddenKey = GlobalKey();

  late final AnimationController _idle;

  SceneObject get _hidden => _shown[_hiddenIndex];

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.session.scene.id.hashCode ^ 0x6a1b);
    final vocab = List.of(widget.session.vocab)..shuffle(rng);
    _shown = vocab.take(3).toList();
    _hiddenIndex = rng.nextInt(3);
    final decoy =
        _shown[(_hiddenIndex + 1 + rng.nextInt(2)) % 3]; // a visible one
    _choices = [_hidden, decoy]..shuffle(rng);

    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    _nudge = NudgeTimer(onNudge: _onNudge);
    _intro();
  }

  Future<void> _intro() async {
    final audio = widget.session.audio;
    await audio.playHost('mithu_game_missing');
    for (final o in _shown) {
      if (!mounted) return;
      await audio.playWord(widget.session.scene.id, o.slug, language: 'hi');
      await Future.delayed(const Duration(milliseconds: 120));
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _phase = _MissingPhase.covered);
    await audio.playHost('mithu_kya_gayab');
    _nudge.arm();
  }

  void _onNudge() {
    if (_phase != _MissingPhase.covered || !mounted) return;
    setState(() => _hinting = true);
    widget.session.audio.playHost('mithu_kya_gayab');
    _nudge.arm();
  }

  @override
  void dispose() {
    _nudge.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _onChoice(int i) {
    if (_phase != _MissingPhase.covered) return;
    widget.session.audio.playTapNote();
    _nudge.arm();
    if (_choices[i].slug == _hidden.slug) {
      _nudge.cancel();
      setState(() {
        _phase = _MissingPhase.solved;
        _hinting = false;
      });
      widget.session.audio.playSfx('ding_sticker');
      final box = _hiddenKey.currentContext?.findRenderObject();
      final stackBox = context.findRenderObject();
      if (box is RenderBox && stackBox is RenderBox) {
        setState(() {
          _burstTrigger++;
          _burstAt = stackBox.globalToLocal(
              box.localToGlobal(box.size.center(Offset.zero)));
        });
      }
      widget.session.audio
          .playWord(widget.session.scene.id, _hidden.slug, language: 'hi');
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) widget.session.onComplete();
      });
    } else {
      _wrongs++;
      setState(() {
        _wobbling = i;
        if (_wrongs >= 2) _hinting = true;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wobbling = null);
      });
      widget.session.audio.playSfx('boop_curious');
      widget.session.audio.playHost('mithu_phir_se');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.session.scene;
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);

    return Stack(children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The three friends; one gets covered by the paper cloth.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _shown.length; i++) ...[
                _shownTile(i, themeColor, deepColor),
                if (i < _shown.length - 1) const SizedBox(width: 28),
              ],
            ],
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: _tile * 0.9 + 34,
            child: _phase == _MissingPhase.showing
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _choices.length; i++) ...[
                        _choiceTile(i, themeColor, deepColor),
                        if (i < _choices.length - 1)
                          const SizedBox(width: 34),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      ParticleBurst(trigger: _burstTrigger, at: _burstAt),
    ]);
  }

  Widget _shownTile(int i, Color themeColor, Color deepColor) {
    final o = _shown[i];
    final covered = _phase == _MissingPhase.covered && i == _hiddenIndex;
    final revealed = _phase == _MissingPhase.solved && i == _hiddenIndex;

    return PopIn(
      delayMs: 120 * i,
      child: SizedBox(
        key: i == _hiddenIndex ? _hiddenKey : null,
        width: _tile,
        height: _tile,
        child: Stack(children: [
          if (revealed)
            PopIn(
              child: ArtTile(
                imagePath: 'assets/art/${o.art}',
                color: themeColor,
                deepColor: deepColor,
                size: _tile,
                showLabel: false,
              ),
            )
          else
            ArtTile(
              imagePath: 'assets/art/${o.art}',
              color: themeColor,
              deepColor: deepColor,
              size: _tile,
              showLabel: false,
            ),
          // The cloth slides down over the hiding friend.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            top: covered ? 0 : -_tile - 30,
            left: 0,
            child: _cloth(deepColor),
          ),
        ]),
      ),
    );
  }

  Widget _cloth(Color deepColor) {
    return Container(
      width: _tile,
      height: _tile,
      decoration: BoxDecoration(
        color: AppColors.kumkum,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(painter: _ClothDotsPainter()),
    );
  }

  Widget _choiceTile(int i, Color themeColor, Color deepColor) {
    final o = _choices[i];
    Widget tile = ArtTile(
      imagePath: 'assets/art/${o.art}',
      wordHi: o.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: _tile * 0.9,
      showLabel: true,
    );

    tile = AnimatedBuilder(
      animation: _idle,
      builder: (context, child) {
        if (_wobbling == i) {
          final w = sin(_idle.value * 2 * pi * 14) * 0.07;
          return Transform.rotate(angle: w, child: child);
        }
        if (_hinting &&
            _phase == _MissingPhase.covered &&
            o.slug == _hidden.slug) {
          final h = _idle.value * 2 * pi * 3;
          return Transform.scale(scale: 1.0 + 0.12 * sin(h), child: child);
        }
        final t = _idle.value * 2 * pi + i * 1.7;
        return Transform.scale(scale: 1.0 + 0.05 * sin(t), child: child);
      },
      child: tile,
    );

    return PopIn(
      delayMs: 100 + 130 * i,
      child: TapBounce(onDown: () => _onChoice(i), child: tile),
    );
  }
}

class _ClothDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    for (var i = 0; i < 9; i++) {
      final fx = 0.2 + (i % 3) * 0.3;
      final fy = 0.2 + (i ~/ 3) * 0.3;
      canvas.drawCircle(
          Offset(fx * size.width, fy * size.height), 5.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClothDotsPainter old) => false;
}
