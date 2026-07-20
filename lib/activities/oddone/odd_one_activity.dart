import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// अलग कौन? — three of one thing and one different; tap the odd one out.
class OddOneActivity extends Activity {
  const OddOneActivity();

  @override
  String get id => 'oddone';

  @override
  String get titleHi => 'अलग कौन?';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return OddOneBody(session: session, key: ValueKey(session.scene.id));
  }
}

class OddOneBody extends StatefulWidget {
  final ActivitySession session;

  const OddOneBody({super.key, required this.session});

  @override
  State<OddOneBody> createState() => _OddOneBodyState();
}

class _OddOneBodyState extends State<OddOneBody> with TickerProviderStateMixin {
  static const _tileSize = 112.0;

  late final SceneObject _common;
  late final SceneObject _odd;
  late final int _oddIndex;
  bool _solved = false;
  int? _wobbling;

  late final AnimationController _idle;
  late final AnimationController _wobble;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    final vocab = List.of(widget.session.vocab);
    final rng = Random(widget.session.scene.id.hashCode ^ 0x0dd1);
    vocab.shuffle(rng);
    _common = vocab[0];
    _odd = vocab.length > 1 ? vocab[1] : vocab[0];
    _oddIndex = rng.nextInt(4);

    _idle = AnimationController(
        duration: const Duration(milliseconds: 3200), vsync: this)
      ..repeat();
    _wobble = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    _glow = AnimationController(
        duration: const Duration(milliseconds: 450), vsync: this);

    widget.session.audio.playHost('mithu_alag_kaun');
  }

  @override
  void dispose() {
    _idle.dispose();
    _wobble.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _onTap(int i) {
    if (_solved) return;
    if (i == _oddIndex) {
      setState(() => _solved = true);
      _glow.forward(from: 0.0);
      widget.session.audio
          .playWord(widget.session.scene.id, _odd.slug, language: 'hi');
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) widget.session.onComplete();
      });
    } else {
      setState(() => _wobbling = i);
      _wobble.forward(from: 0.0).whenCompleteOrCancel(() {
        if (mounted) setState(() => _wobbling = null);
      });
      // Warm and informative: name what they touched, then invite retry.
      widget.session.audio
          .playWord(widget.session.scene.id, _common.slug, language: 'hi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.session.scene;
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);

    return Center(
      child: Wrap(
        spacing: 28,
        runSpacing: 28,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            PopIn(delayMs: 110 * i, child: _tile(i, themeColor, deepColor)),
        ],
      ),
    );
  }

  Widget _tile(int i, Color themeColor, Color deepColor) {
    final object = i == _oddIndex ? _odd : _common;
    Widget tile = ArtTile(
      imagePath: 'assets/art/${object.art}',
      wordHi: object.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: _tileSize,
      showLabel: false,
    );
    tile = AnimatedBuilder(
      animation: Listenable.merge([_idle, _wobble, _glow]),
      builder: (context, child) {
        if (_wobbling == i) {
          return Transform.rotate(
              angle: sin(_wobble.value * pi * 3) * 0.08, child: child);
        }
        if (_solved && i == _oddIndex) {
          return Transform.scale(
              scale: 1.0 + 0.18 * sin(_glow.value * pi), child: child);
        }
        final t = _idle.value * 2 * pi + i * 1.3;
        return Transform.scale(scale: 1.0 + 0.05 * sin(t), child: child);
      },
      child: tile,
    );
    return GestureDetector(
      onTap: () => _onTap(i),
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}
