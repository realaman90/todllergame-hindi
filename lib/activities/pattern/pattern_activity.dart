import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../juice/juice.dart';
import '../activity.dart';

/// पैटर्न पूरा करो — complete the A-B-A-B-? sequence.
///
/// The sequence speaks itself on entry (A, B, A, B…), the empty slot
/// pulses, and two big choices sit below. The right choice fills the
/// slot and completes the round; a wrong tap gets a gentle wobble and
/// Mithu's warm "फिर से!".
class PatternActivity extends Activity {
  const PatternActivity();

  @override
  String get id => 'pattern';

  @override
  String get titleHi => 'पैटर्न पूरा करो';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return PatternBody(session: session, key: ValueKey(session.scene.id));
  }
}

class PatternBody extends StatefulWidget {
  final ActivitySession session;

  const PatternBody({super.key, required this.session});

  @override
  State<PatternBody> createState() => _PatternBodyState();
}

class _PatternBodyState extends State<PatternBody>
    with TickerProviderStateMixin {
  static const _seqTile = 88.0;
  static const _choiceTile = 116.0;

  late final SceneObject _a;
  late final SceneObject _b;
  late final SceneObject _answer; // pattern is A B A B ? -> answer = A
  late final List<SceneObject> _choices;

  bool _solved = false;
  int? _wobbling; // choice index doing the gentle wobble
  late final NudgeTimer _nudge;
  bool _hinting = false; // F17 nudge / F16 level-3 highlight
  int _wrongs = 0;

  late final AnimationController _idle;
  late final AnimationController _wobble;
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    final vocab = List.of(widget.session.vocab);
    final rng = Random(); // fresh every replay (seeded RNG let her memorize positions)
    vocab.shuffle(rng);
    _a = vocab[0];
    _b = vocab.length > 1 ? vocab[1] : vocab[0];
    _answer = _a;
    _choices = [_a, _b]..shuffle(rng);

    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    _wobble = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _fill = AnimationController(
        duration: const Duration(milliseconds: 450), vsync: this);

    _speakSequence();
    _nudge = NudgeTimer(onNudge: _onNudge)..arm();
  }

  void _onNudge() {
    if (_solved || !mounted) return;
    setState(() => _hinting = true);
    _speakSequence();
    _nudge.arm();
  }

  Future<void> _speakSequence() async {
    // Title first, then "A… B… A… B…" — the audio IS the instruction.
    final audio = widget.session.audio;
    final sceneId = widget.session.scene.id;
    await audio.playHost('mithu_game_pattern');
    await Future.delayed(const Duration(milliseconds: 200));
    for (final o in [_a, _b, _a, _b]) {
      if (!mounted) return;
      await audio.playWord(sceneId, o.slug, language: 'hi');
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  @override
  void dispose() {
    _nudge.dispose();
    _idle.dispose();
    _wobble.dispose();
    _fill.dispose();
    super.dispose();
  }

  void _onChoice(int index) {
    widget.session.audio.playTapNote();
    if (_solved) return;
    final chosen = _choices[index];
    _nudge.arm();
    if (chosen.slug == _answer.slug) {
      _nudge.cancel();
      setState(() {
        _solved = true;
        _hinting = false;
      });
      _fill.forward(from: 0.0);
      widget.session.audio.playWord(
          widget.session.scene.id, chosen.slug,
          language: 'hi');
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) widget.session.onComplete();
      });
    } else {
      _wrongs++;
      setState(() {
        _wobbling = index;
        // F16 level 3: after two misses, highlight the answer until tapped.
        if (_wrongs >= 2) _hinting = true;
      });
      _wobble.forward(from: 0.0).whenCompleteOrCancel(() {
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
    final sequence = [_a, _b, _a, _b];

    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < sequence.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: PopIn(
                    delayMs: 120 * i,
                    child: _seqSlot(sequence[i], i, themeColor, deepColor),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _answerSlot(themeColor, deepColor),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _choices.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: PopIn(
                    delayMs: 600 + 150 * i,
                    child: _choice(i, themeColor, deepColor),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }

  Widget _seqSlot(
      SceneObject o, int i, Color themeColor, Color deepColor) {
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, child) {
        final t = _idle.value * 2 * pi + i * 0.9;
        return Transform.scale(scale: 1.0 + 0.03 * sin(t), child: child);
      },
      child: ArtTile(
        imagePath: 'assets/art/${o.art}',
        wordHi: o.wordHi,
        color: themeColor,
        deepColor: deepColor,
        size: _seqTile,
        showLabel: false,
      ),
    );
  }

  Widget _answerSlot(Color themeColor, Color deepColor) {
    if (_solved) {
      return AnimatedBuilder(
        animation: _fill,
        builder: (context, child) {
          final v = _fill.value;
          return Transform.scale(scale: 0.6 + 0.4 * v, child: child);
        },
        child: ArtTile(
          imagePath: 'assets/art/${_answer.art}',
          wordHi: _answer.wordHi,
          color: themeColor,
          deepColor: deepColor,
          size: _seqTile,
          showLabel: false,
        ),
      );
    }
    // Pulsing empty slot: the question mark a toddler can read.
    return AnimatedBuilder(
      animation: _idle,
      builder: (context, _) {
        final t = _idle.value * 2 * pi;
        return Transform.scale(
          scale: 1.0 + 0.08 * sin(t * 2),
          child: Container(
            width: _seqTile,
            height: _seqTile,
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor, width: 3.5),
            ),
          ),
        );
      },
    );
  }

  Widget _choice(int i, Color themeColor, Color deepColor) {
    Widget tile = ArtTile(
      imagePath: 'assets/art/${_choices[i].art}',
      wordHi: _choices[i].wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: _choiceTile,
      showLabel: false,
    );
    tile = AnimatedBuilder(
      animation: Listenable.merge([_idle, _wobble]),
      builder: (context, child) {
        if (_wobbling == i) {
          final w = sin(_wobble.value * pi * 3) * 0.08;
          return Transform.rotate(angle: w, child: child);
        }
        if (_hinting && !_solved && _choices[i].slug == _answer.slug) {
          // Nudge pulse: unmistakably bigger and faster than idle breath.
          final h = _idle.value * 2 * pi * 3;
          return Transform.scale(scale: 1.0 + 0.12 * sin(h), child: child);
        }
        final t = _idle.value * 2 * pi + i * 1.7;
        return Transform.scale(scale: 1.0 + 0.05 * sin(t), child: child);
      },
      child: tile,
    );
    return TapBounce(
      onDown: () => _onChoice(i),
      child: tile,
    );
  }
}
