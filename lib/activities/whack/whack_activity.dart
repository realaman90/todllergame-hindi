import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// झटपट बोलो (Whack-a-word, format #18): objects peek up from behind
/// paper pots; tap the one Mithu asked for. Nothing "escapes" and no
/// timer punishes — wrong peekers just say their own name (F5: every
/// touch teaches). Three catches and the round is won.
class WhackActivity extends Activity {
  const WhackActivity();

  @override
  String get id => 'whack';

  @override
  String get titleHi => 'झटपट बोलो';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return WhackBody(session: session, key: UniqueKey());
  }
}

class WhackBody extends StatefulWidget {
  final ActivitySession session;

  const WhackBody({super.key, required this.session});

  @override
  State<WhackBody> createState() => _WhackBodyState();
}

class _WhackBodyState extends State<WhackBody> with TickerProviderStateMixin {
  static const _pots = 3;
  static const _needed = 3;

  late final List<SceneObject> _pool;
  late SceneObject _ask;
  final List<SceneObject?> _peeking = List.filled(_pots, null);
  late final List<AnimationController> _rise;
  final _rng = Random();
  Timer? _spawner;
  int _caught = 0;
  int _sinceAskSeen = 0; // rig: the asked object peeks often
  bool _finishing = false;
  late final NudgeTimer _nudge;

  @override
  void initState() {
    super.initState();
    _pool = widget.session.vocab.take(4).toList();
    _ask = _pool[_rng.nextInt(_pool.length)];
    _rise = List.generate(
      _pots,
      (_) => AnimationController(
          duration: const Duration(milliseconds: 420), vsync: this),
    );
    _prompt(withTitle: true);
    _spawner = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (mounted && !_finishing) _spawnPeek();
    });
    _nudge = NudgeTimer(onNudge: _onNudge)..arm();
  }

  Future<void> _prompt({bool withTitle = false}) async {
    final audio = widget.session.audio;
    if (withTitle) await audio.playHost('mithu_game_whack');
    if (!mounted) return;
    await audio.playPromptSequence(
      widget.session.scene.id,
      _ask.slug,
      language: 'hi',
    );
  }

  void _onNudge() {
    if (_finishing || !mounted) return;
    _prompt();
    _nudge.arm();
  }

  void _spawnPeek() {
    final freePots = [
      for (var i = 0; i < _pots; i++)
        if (_peeking[i] == null) i
    ];
    if (freePots.isEmpty) return;
    final pot = freePots[_rng.nextInt(freePots.length)];
    // Every second rise is guaranteed to be the asked object — the game
    // must feel generous, not sneaky.
    SceneObject obj;
    if (_sinceAskSeen >= 1) {
      obj = _ask;
      _sinceAskSeen = 0;
    } else {
      obj = _pool[_rng.nextInt(_pool.length)];
      if (obj.slug == _ask.slug) {
        _sinceAskSeen = 0;
      } else {
        _sinceAskSeen++;
      }
    }
    setState(() => _peeking[pot] = obj);
    _rise[pot].forward(from: 0.0);
    // Bob for a moment, then sink back down.
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted || _peeking[pot] == null) return;
      await _rise[pot].reverse();
      if (mounted) setState(() => _peeking[pot] = null);
    });
  }

  Future<void> _onPotTap(int pot) async {
    final obj = _peeking[pot];
    widget.session.audio.playTapNote();
    _nudge.arm();
    if (obj == null || _finishing) return;
    if (obj.slug == _ask.slug) {
      _caught++;
      widget.session.audio.playSfx('ding_sticker');
      widget.session.audio
          .playWord(widget.session.scene.id, obj.slug, language: 'hi');
      await _rise[pot].reverse();
      if (!mounted) return;
      setState(() => _peeking[pot] = null);
      if (_caught >= _needed) {
        _finishing = true;
        _nudge.cancel();
        _spawner?.cancel();
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) widget.session.onComplete();
        });
      } else {
        var next = _pool[_rng.nextInt(_pool.length)];
        while (next.slug == _ask.slug) {
          next = _pool[_rng.nextInt(_pool.length)];
        }
        _ask = next;
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && !_finishing) _prompt();
        });
      }
    } else {
      // A friendly wrong: the peeker introduces itself and ducks away.
      widget.session.audio
          .playWord(widget.session.scene.id, obj.slug, language: 'hi');
    }
  }

  @override
  void dispose() {
    _spawner?.cancel();
    _nudge.dispose();
    for (final c in _rise) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.session.scene;
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);
    final s = uiScale(context);
    final potW = 150.0 * s;
    final potH = 96.0 * s;
    final tile = 96.0 * s;

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _pots; i++) ...[
            TapBounce(
              haptic: false,
              onDown: () => _onPotTap(i),
              child: SizedBox(
                width: potW,
                height: potH + tile + 8,
                child: ClipRect(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // The peeker rises from behind the pot rim.
                      AnimatedBuilder(
                        animation: _rise[i],
                        builder: (context, child) {
                          final t =
                              Curves.easeOutBack.transform(_rise[i].value);
                          // NOT Positioned (must be a direct Stack child):
                          // translate up from the bottomCenter alignment.
                          return Transform.translate(
                            offset: Offset(
                                0, -(potH * 0.55 + (tile * 0.85) * (t - 1))),
                            child: child,
                          );
                        },
                        child: _peeking[i] == null
                            ? const SizedBox.shrink()
                            : ArtTile(
                                imagePath:
                                    'assets/art/${_peeking[i]!.art}',
                                color: themeColor,
                                deepColor: deepColor,
                                size: 96,
                                showLabel: false,
                              ),
                      ),
                      // Paper pot in front.
                      CustomPaint(
                        size: Size(potW, potH),
                        painter: _PotPainter(
                            color: themeColor, deep: deepColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < _pots - 1) SizedBox(width: 26 * s),
          ],
        ],
      ),
    );
  }
}

class _PotPainter extends CustomPainter {
  final Color color;
  final Color deep;

  _PotPainter({required this.color, required this.deep});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(w * 0.08, h * 0.22)
      ..lineTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.80, h * 0.96)
      ..lineTo(w * 0.20, h * 0.96)
      ..close();
    canvas.drawShadow(body, deep.withValues(alpha: 0.6), 5, false);
    canvas.drawPath(body, Paint()..color = color);
    // Rim.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h * 0.26),
        Radius.circular(h * 0.13),
      ),
      Paint()..color = deep,
    );
    // Paper shine stripe.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.32)
        ..lineTo(w * 0.3, h * 0.32)
        ..lineTo(w * 0.26, h * 0.88)
        ..lineTo(w * 0.18, h * 0.88)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _PotPainter old) =>
      old.color != color || old.deep != deep;
}
