import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// छोटा, मझला, बड़ा (3-size sort, format #19): the same object at three
/// sizes; Mithu keeps asking "कौन सा बड़ा है?" — tap the biggest of what
/// remains, and it locks onto the shelf. Extends big-small to seriation
/// with only existing vocabulary.
class SizesActivity extends Activity {
  const SizesActivity();

  @override
  String get id => 'sizes';

  @override
  String get titleHi => 'छोटा, मझला, बड़ा';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return SizesBody(session: session, key: UniqueKey());
  }
}

class SizesBody extends StatefulWidget {
  final ActivitySession session;

  const SizesBody({super.key, required this.session});

  @override
  State<SizesBody> createState() => _SizesBodyState();
}

class _SizesBodyState extends State<SizesBody>
    with SingleTickerProviderStateMixin {
  static const _sizes = [64.0, 104.0, 148.0]; // chota, majhla, bada

  late final SceneObject _object;
  late final List<int> _order; // display order of size-indices, shuffled
  final Set<int> _locked = {}; // size-indices already shelved
  int _wrongs = 0;
  bool _hinting = false;
  bool _finishing = false;
  int? _wobbling;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;
  late final NudgeTimer _nudge;
  late final AnimationController _idle;

  int get _biggestRemaining {
    for (var i = 2; i >= 0; i--) {
      if (!_locked.contains(i)) return i;
    }
    return -1;
  }

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.session.scene.id.hashCode ^ 0x517e);
    final vocab = List.of(widget.session.vocab)..shuffle(rng);
    _object = vocab.first;
    _order = [0, 1, 2]..shuffle(rng);
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    _intro();
    _nudge = NudgeTimer(onNudge: _onNudge)..arm();
  }

  Future<void> _intro() async {
    await widget.session.audio.playHost('mithu_game_sizes');
    if (mounted) widget.session.audio.playHost('mithu_konsa_bada');
  }

  void _onNudge() {
    if (_finishing || !mounted) return;
    setState(() => _hinting = true);
    widget.session.audio.playHost('mithu_konsa_bada');
    _nudge.arm();
  }

  @override
  void dispose() {
    _nudge.dispose();
    _idle.dispose();
    super.dispose();
  }

  void _onTap(int sizeIndex) {
    if (_finishing || _locked.contains(sizeIndex)) return;
    widget.session.audio.playTapNote();
    _nudge.arm();
    if (sizeIndex == _biggestRemaining) {
      setState(() {
        _locked.add(sizeIndex);
        _hinting = false;
        _wrongs = 0;
      });
      widget.session.audio.playSfx('ding_sticker');
      widget.session.audio.playHost('mithu_bada');
      final stackBox = context.findRenderObject();
      if (stackBox is RenderBox) {
        setState(() {
          _burstTrigger++;
          _burstAt = Offset(
              stackBox.size.width *
                  (0.30 + 0.20 * (2 - sizeIndex)),
              stackBox.size.height * 0.75);
        });
      }
      if (_locked.length == 3) {
        _finishing = true;
        _nudge.cancel();
        Future.delayed(const Duration(milliseconds: 1100), () {
          if (mounted) widget.session.onComplete();
        });
      } else {
        Future.delayed(const Duration(milliseconds: 1300), () {
          if (mounted && !_finishing) {
            widget.session.audio.playHost('mithu_konsa_bada');
          }
        });
      }
    } else {
      _wrongs++;
      setState(() {
        _wobbling = sizeIndex;
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

    return Stack(children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // The three sizes, tappable while unlocked.
          SizedBox(
            height: _sizes.last * s + 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var d = 0; d < _order.length; d++) ...[
                  _sizeTile(_order[d], d, themeColor, deepColor),
                  if (d < _order.length - 1) SizedBox(width: 28 * s),
                ],
              ],
            ),
          ),
          SizedBox(height: 30 * s),
          // The shelf: locked ones settle small -> big, left to right.
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 20 * s, vertical: 10 * s),
            decoration: BoxDecoration(
              color: AppColors.paper2.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  _shelfSlot(i, themeColor, deepColor),
                  if (i < 2) SizedBox(width: 18 * s),
                ],
              ],
            ),
          ),
        ],
      ),
      ParticleBurst(trigger: _burstTrigger, at: _burstAt),
    ]);
  }

  Widget _sizeTile(
      int sizeIndex, int displayPos, Color themeColor, Color deepColor) {
    final s = uiScale(context);
    if (_locked.contains(sizeIndex)) {
      return SizedBox(width: _sizes[sizeIndex] * s);
    }
    Widget tile = ArtTile(
      imagePath: 'assets/art/${_object.art}',
      color: themeColor,
      deepColor: deepColor,
      size: _sizes[sizeIndex],
      showLabel: false,
    );
    tile = AnimatedBuilder(
      animation: _idle,
      builder: (context, child) {
        if (_wobbling == sizeIndex) {
          final w = sin(_idle.value * 2 * pi * 14) * 0.07;
          return Transform.rotate(angle: w, child: child);
        }
        if (_hinting && sizeIndex == _biggestRemaining) {
          final h = _idle.value * 2 * pi * 3;
          return Transform.scale(scale: 1.0 + 0.12 * sin(h), child: child);
        }
        final t = _idle.value * 2 * pi + displayPos * 1.6;
        return Transform.scale(scale: 1.0 + 0.04 * sin(t), child: child);
      },
      child: tile,
    );
    return PopIn(
      delayMs: 120 + 120 * displayPos,
      child: TapBounce(onDown: () => _onTap(sizeIndex), child: tile),
    );
  }

  Widget _shelfSlot(int sizeIndex, Color themeColor, Color deepColor) {
    final s = uiScale(context);
    final side = _sizes[sizeIndex] * 0.62 * s;
    if (_locked.contains(sizeIndex)) {
      return PopIn(
        child: ArtTile(
          imagePath: 'assets/art/${_object.art}',
          color: themeColor,
          deepColor: deepColor,
          size: _sizes[sizeIndex] * 0.62,
          showLabel: false,
        ),
      );
    }
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.ink.withValues(alpha: 0.18),
          width: 2.5,
        ),
      ),
    );
  }
}
