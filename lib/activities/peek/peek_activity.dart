import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// कौन छुपा है? (Peek-a-boo zoom, format #35): an extreme close-up
/// slowly zooms out — tap who it is from two big choices, any time.
/// Guessing without reading; the zoom always finishes, so the answer
/// eventually reveals itself — no fail possible.
class PeekActivity extends Activity {
  const PeekActivity();

  @override
  String get id => 'peek';

  @override
  String get titleHi => 'कौन छुपा है?';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return PeekBody(session: session, key: UniqueKey());
  }
}

class PeekBody extends StatefulWidget {
  final ActivitySession session;

  const PeekBody({super.key, required this.session});

  @override
  State<PeekBody> createState() => _PeekBodyState();
}

class _PeekBodyState extends State<PeekBody>
    with TickerProviderStateMixin {
  late final SceneObject _answer;
  late final List<SceneObject> _choices;
  late final Alignment _peekFrom;
  bool _solved = false;
  int _wrongs = 0;
  bool _hinting = false;
  int? _wobbling;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;
  late final NudgeTimer _nudge;
  late final AnimationController _zoom; // 0 = extreme close-up, 1 = full
  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.session.scene.id.hashCode ^ 0x9eeb);
    final vocab = List.of(widget.session.vocab)..shuffle(rng);
    _answer = vocab[0];
    _choices = [vocab[0], vocab[1]]..shuffle(rng);
    _peekFrom = Alignment((rng.nextDouble() - 0.5) * 1.2,
        (rng.nextDouble() - 0.5) * 1.2);
    _zoom = AnimationController(
        duration: const Duration(seconds: 9), vsync: this)
      ..forward();
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    widget.session.audio.playHost('mithu_game_peek');
    _nudge = NudgeTimer(onNudge: _onNudge)..arm();
  }

  void _onNudge() {
    if (_solved || !mounted) return;
    setState(() => _hinting = true);
    widget.session.audio.playHost('mithu_game_peek');
    _nudge.arm();
  }

  @override
  void dispose() {
    _nudge.dispose();
    _zoom.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _onChoice(int i) {
    if (_solved) return;
    widget.session.audio.playTapNote();
    _nudge.arm();
    if (_choices[i].slug == _answer.slug) {
      _nudge.cancel();
      setState(() {
        _solved = true;
        _hinting = false;
      });
      _zoom.animateTo(1.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut);
      widget.session.audio.playSfx('ding_sticker');
      widget.session.audio
          .playWord(widget.session.scene.id, _answer.slug, language: 'hi');
      final stackBox = context.findRenderObject();
      if (stackBox is RenderBox) {
        setState(() {
          _burstTrigger++;
          _burstAt = Offset(stackBox.size.width / 2,
              stackBox.size.height * 0.35);
        });
      }
      Future.delayed(const Duration(milliseconds: 1400), () {
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
    final s = uiScale(context);
    final win = 240.0 * s;

    return Stack(children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The peek window: close-up slowly zooming out.
          Container(
            width: win,
            height: win,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: deepColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: AnimatedBuilder(
                animation: _zoom,
                builder: (context, child) {
                  final t = Curves.easeOut.transform(_zoom.value);
                  return Transform.scale(
                    scale: 5.5 - 4.5 * t, // 5.5x close-up -> 1.0
                    alignment: _peekFrom,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/art/${_answer.art}',
                  fit: BoxFit.cover,
                  width: win,
                  height: win,
                ),
              ),
            ),
          ),
          SizedBox(height: 34 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _choices.length; i++) ...[
                _choiceTile(i, themeColor, deepColor),
                if (i < _choices.length - 1) SizedBox(width: 36 * s),
              ],
            ],
          ),
        ],
      ),
      ParticleBurst(trigger: _burstTrigger, at: _burstAt),
    ]);
  }

  Widget _choiceTile(int i, Color themeColor, Color deepColor) {
    final o = _choices[i];
    Widget tile = ArtTile(
      imagePath: 'assets/art/${o.art}',
      wordHi: o.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: 100,
      showLabel: true,
    );
    tile = AnimatedBuilder(
      animation: _idle,
      builder: (context, child) {
        if (_wobbling == i) {
          final w = sin(_idle.value * 2 * pi * 14) * 0.07;
          return Transform.rotate(angle: w, child: child);
        }
        if (_hinting && !_solved && o.slug == _answer.slug) {
          final h = _idle.value * 2 * pi * 3;
          return Transform.scale(scale: 1.0 + 0.12 * sin(h), child: child);
        }
        final t = _idle.value * 2 * pi + i * 1.7;
        return Transform.scale(scale: 1.0 + 0.05 * sin(t), child: child);
      },
      child: tile,
    );
    return PopIn(
      delayMs: 120 + 130 * i,
      child: TapBounce(onDown: () => _onChoice(i), child: tile),
    );
  }
}
