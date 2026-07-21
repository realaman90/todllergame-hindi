import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../../juice/juice.dart';
import '../activity.dart';

/// बड़ा-छोटा — the same object twice, one big and one small; Mithu asks
/// for one of them. Opposites, the toddler-right version of "antonyms".
class BigSmallActivity extends Activity {
  const BigSmallActivity();

  @override
  String get id => 'bigsmall';

  @override
  String get titleHi => 'बड़ा-छोटा';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return BigSmallBody(session: session, key: ValueKey(session.scene.id));
  }
}

class BigSmallBody extends StatefulWidget {
  final ActivitySession session;

  const BigSmallBody({super.key, required this.session});

  @override
  State<BigSmallBody> createState() => _BigSmallBodyState();
}

class _BigSmallBodyState extends State<BigSmallBody>
    with TickerProviderStateMixin {
  static const _big = 156.0;
  static const _small = 88.0;

  late final SceneObject _object;
  late final bool _askBig; // which one Mithu asks for
  late final bool _bigOnLeft;
  bool _solved = false;
  bool _wobblingWrong = false;

  late final AnimationController _idle;
  late final AnimationController _wobble;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.session.scene.id.hashCode ^ 0xb165);
    final vocab = List.of(widget.session.vocab)..shuffle(rng);
    _object = vocab.first;
    _askBig = rng.nextBool();
    _bigOnLeft = rng.nextBool();

    _idle = AnimationController(
        duration: const Duration(milliseconds: 3200), vsync: this)
      ..repeat();
    _wobble = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _glow = AnimationController(
        duration: const Duration(milliseconds: 450), vsync: this);

    widget.session.audio
        .playHost(_askBig ? 'mithu_konsa_bada' : 'mithu_konsa_chota');
  }

  @override
  void dispose() {
    _idle.dispose();
    _wobble.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _onTap({required bool tappedBig}) {
    widget.session.audio.playTapNote();
    if (_solved) return;
    if (tappedBig == _askBig) {
      setState(() => _solved = true);
      _glow.forward(from: 0.0);
      widget.session.audio.playHost(_askBig ? 'mithu_bada' : 'mithu_chota');
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) widget.session.onComplete();
      });
    } else {
      setState(() => _wobblingWrong = true);
      _wobble.forward(from: 0.0).whenCompleteOrCancel(() {
        if (mounted) setState(() => _wobblingWrong = false);
      });
      // Name what they DID touch — informative, not punitive.
      widget.session.audio.playSfx('boop_curious');
      widget.session.audio.playHost(tappedBig ? 'mithu_bada' : 'mithu_chota');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.session.scene;
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);

    final bigTile = PopIn(delayMs: 80, child: _tile(true, themeColor, deepColor));
    final smallTile =
        PopIn(delayMs: 260, child: _tile(false, themeColor, deepColor));

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _bigOnLeft
            ? [bigTile, const SizedBox(width: 80), smallTile]
            : [smallTile, const SizedBox(width: 80), bigTile],
      ),
    );
  }

  Widget _tile(bool isBig, Color themeColor, Color deepColor) {
    final size = isBig ? _big : _small;
    final correct = isBig == _askBig;
    Widget tile = ArtTile(
      imagePath: 'assets/art/${_object.art}',
      wordHi: _object.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: size,
      showLabel: false,
    );
    tile = AnimatedBuilder(
      animation: Listenable.merge([_idle, _wobble, _glow]),
      builder: (context, child) {
        if (_wobblingWrong && !correct) {
          return Transform.rotate(
              angle: sin(_wobble.value * pi * 3) * 0.08, child: child);
        }
        if (_solved && correct) {
          return Transform.scale(
              scale: 1.0 + 0.15 * sin(_glow.value * pi), child: child);
        }
        final t = _idle.value * 2 * pi + (isBig ? 0.0 : 1.9);
        return Transform.scale(scale: 1.0 + 0.04 * sin(t), child: child);
      },
      child: tile,
    );
    return TapBounce(
      onDown: () => _onTap(tappedBig: isBig),
      child: tile,
    );
  }
}
