import 'dart:math';

import 'package:flutter/material.dart';

import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// कौन बोला? (Sound match, format #6): hear an animal call, tap who made
/// it. Wrong taps play THAT animal's voice — every touch teaches the
/// sound-to-animal link. Three right answers win the round.
///
/// Content is fixed to the farm animals (they're the ones with voices);
/// the session scene only themes the backdrop.
class SoundMatchActivity extends Activity {
  const SoundMatchActivity();

  @override
  String get id => 'soundmatch';

  @override
  String get titleHi => 'कौन बोला?';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return SoundMatchBody(session: session, key: UniqueKey());
  }
}

class _Animal {
  final String slug;
  final String wordHi;
  final String sfx;

  const _Animal(this.slug, this.wordHi, this.sfx);
}

class SoundMatchBody extends StatefulWidget {
  final ActivitySession session;

  const SoundMatchBody({super.key, required this.session});

  @override
  State<SoundMatchBody> createState() => _SoundMatchBodyState();
}

class _SoundMatchBodyState extends State<SoundMatchBody>
    with SingleTickerProviderStateMixin {
  static const _animals = [
    _Animal('gaay', 'गाय', 'animal_gaay'),
    _Animal('kutta', 'कुत्ता', 'animal_kutta'),
    _Animal('bakri', 'बकरी', 'animal_bakri'),
    _Animal('batakh', 'बत्तख', 'animal_batakh'),
  ];
  static const _needed = 3;

  late final List<_Animal> _choices;
  late _Animal _ask;
  final _rng = Random();
  int _correct = 0;
  int _wrongs = 0;
  bool _hinting = false;
  bool _finishing = false;
  int? _wobbling;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;
  late final NudgeTimer _nudge;
  late final AnimationController _idle;
  final List<GlobalKey> _tileKeys = [];

  @override
  void initState() {
    super.initState();
    _choices = List.of(_animals)..shuffle(_rng);
    _choices.length = 3;
    for (var i = 0; i < _choices.length; i++) {
      _tileKeys.add(GlobalKey());
    }
    _ask = _choices[_rng.nextInt(_choices.length)];
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    _intro();
    _nudge = NudgeTimer(onNudge: _onNudge)..arm();
  }

  Future<void> _intro() async {
    await widget.session.audio.playHost('mithu_game_sounds');
    if (mounted) widget.session.audio.playSfx(_ask.sfx);
  }

  void _onNudge() {
    if (_finishing || !mounted) return;
    setState(() => _hinting = true);
    widget.session.audio.playSfx(_ask.sfx);
    _nudge.arm();
  }

  @override
  void dispose() {
    _nudge.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (_finishing) return;
    widget.session.audio.playTapNote();
    _nudge.arm();
    final tapped = _choices[i];
    if (tapped.slug == _ask.slug) {
      _correct++;
      widget.session.audio.playSfx('ding_sticker');
      widget.session.audio.playWord('farm', tapped.slug, language: 'hi');
      final box = _tileKeys[i].currentContext?.findRenderObject();
      final stackBox = context.findRenderObject();
      if (box is RenderBox && stackBox is RenderBox) {
        setState(() {
          _burstTrigger++;
          _burstAt = stackBox.globalToLocal(
              box.localToGlobal(box.size.center(Offset.zero)));
          _hinting = false;
          _wrongs = 0;
        });
      }
      if (_correct >= _needed) {
        _finishing = true;
        _nudge.cancel();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) widget.session.onComplete();
        });
      } else {
        var next = _choices[_rng.nextInt(_choices.length)];
        while (next.slug == _ask.slug) {
          next = _choices[_rng.nextInt(_choices.length)];
        }
        _ask = next;
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted && !_finishing) {
            widget.session.audio.playSfx(_ask.sfx);
          }
        });
      }
    } else {
      // The wrong animal answers with its own voice — that IS the lesson.
      _wrongs++;
      setState(() {
        _wobbling = i;
        if (_wrongs >= 2) _hinting = true;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wobbling = null);
      });
      widget.session.audio.playSfx(tapped.sfx);
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = AppColors.mehndi;
    const deepColor = AppColors.mehndiDeep;

    return Stack(children: [
      Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _choices.length; i++) ...[
              _tile(i, themeColor, deepColor),
              if (i < _choices.length - 1) const SizedBox(width: 34),
            ],
          ],
        ),
      ),
      ParticleBurst(trigger: _burstTrigger, at: _burstAt),
    ]);
  }

  Widget _tile(int i, Color themeColor, Color deepColor) {
    final a = _choices[i];
    Widget tile = ArtTile(
      key: _tileKeys[i],
      imagePath: 'assets/art/objects/farm_${a.slug}.png',
      wordHi: a.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: 116,
      showLabel: true,
    );

    tile = AnimatedBuilder(
      animation: _idle,
      builder: (context, child) {
        if (_wobbling == i) {
          final w = sin(_idle.value * 2 * pi * 14) * 0.07;
          return Transform.rotate(angle: w, child: child);
        }
        if (_hinting && !_finishing && a.slug == _ask.slug) {
          final h = _idle.value * 2 * pi * 3;
          return Transform.scale(scale: 1.0 + 0.12 * sin(h), child: child);
        }
        final t = _idle.value * 2 * pi + i * 1.7;
        return Transform.scale(scale: 1.0 + 0.05 * sin(t), child: child);
      },
      child: tile,
    );

    return PopIn(
      delayMs: 110 * i,
      child: TapBounce(onDown: () => _onTap(i), child: tile),
    );
  }
}
