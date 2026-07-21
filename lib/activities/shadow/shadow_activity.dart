import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// परछाईं मिलाओ (Shadow match, format #23): drag each object onto its
/// silhouette. The shadow "fills in" with the real art on a correct
/// drop; a wrong drop snaps back gently with a curious boop — no fail.
class ShadowMatchActivity extends Activity {
  const ShadowMatchActivity();

  @override
  String get id => 'shadow';

  @override
  String get titleHi => 'परछाईं मिलाओ';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return ShadowBody(session: session, key: UniqueKey());
  }
}

class ShadowBody extends StatefulWidget {
  final ActivitySession session;

  const ShadowBody({super.key, required this.session});

  @override
  State<ShadowBody> createState() => _ShadowBodyState();
}

class _ShadowBodyState extends State<ShadowBody>
    with SingleTickerProviderStateMixin {
  static const _tile = 110.0;

  late final List<SceneObject> _objects;
  late final List<SceneObject> _slots; // shuffled order of the same 3
  final Set<String> _filled = {};
  late final NudgeTimer _nudge;
  bool _hinting = false;
  int _burstTrigger = 0;
  Offset _burstAt = Offset.zero;
  final Map<String, GlobalKey> _slotKeys = {};

  late final AnimationController _idle;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.session.scene.id.hashCode ^ 0x5ad0);
    _objects = widget.session.vocab.take(3).toList();
    _slots = List.of(_objects)..shuffle(rng);
    for (final o in _objects) {
      _slotKeys[o.slug] = GlobalKey();
    }
    _idle = AnimationController(
        duration: const Duration(milliseconds: 3000), vsync: this)
      ..repeat();
    widget.session.audio.playHost('mithu_game_shadow');
    _nudge = NudgeTimer(onNudge: _onNudge)..arm();
  }

  void _onNudge() {
    if (_filled.length == _objects.length || !mounted) return;
    setState(() => _hinting = true);
    widget.session.audio.playHost('mithu_game_shadow');
    _nudge.arm();
  }

  @override
  void dispose() {
    _nudge.dispose();
    _idle.dispose();
    super.dispose();
  }

  SceneObject? get _firstUnfilled {
    for (final s in _slots) {
      if (!_filled.contains(s.slug)) return s;
    }
    return null;
  }

  void _onDrop(SceneObject slot, SceneObject dragged) {
    _nudge.arm();
    if (_filled.contains(slot.slug)) return;
    if (dragged.slug == slot.slug) {
      setState(() {
        _filled.add(slot.slug);
        _hinting = false;
      });
      widget.session.audio.playSfx('ding_sticker');
      widget.session.audio
          .playWord(widget.session.scene.id, slot.slug, language: 'hi');
      final box = _slotKeys[slot.slug]?.currentContext?.findRenderObject();
      if (box is RenderBox) {
        final stackBox = context.findRenderObject();
        if (stackBox is RenderBox) {
          setState(() {
            _burstTrigger++;
            _burstAt = stackBox.globalToLocal(
                box.localToGlobal(box.size.center(Offset.zero)));
          });
        }
      }
      if (_filled.length == _objects.length) {
        _nudge.cancel();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) widget.session.onComplete();
        });
      }
    } else {
      widget.session.audio.playSfx('boop_curious');
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
          // Silhouette slots.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _slots.length; i++) ...[
                _slot(_slots[i], i, themeColor, deepColor),
                if (i < _slots.length - 1) const SizedBox(width: 30),
              ],
            ],
          ),
          const SizedBox(height: 40),
          // Draggable objects (only unplaced ones remain).
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _objects.length; i++) ...[
                _draggableObject(_objects[i], i, themeColor, deepColor),
                if (i < _objects.length - 1) const SizedBox(width: 30),
              ],
            ],
          ),
        ],
      ),
      ParticleBurst(trigger: _burstTrigger, at: _burstAt),
    ]);
  }

  Widget _slot(SceneObject o, int i, Color themeColor, Color deepColor) {
    final filled = _filled.contains(o.slug);
    final artName = o.art.split('/').last;
    final hintThis = _hinting && !filled && _firstUnfilled?.slug == o.slug;

    Widget content = filled
        ? PopIn(
            child: ArtTile(
              imagePath: 'assets/art/${o.art}',
              color: themeColor,
              deepColor: deepColor,
              size: _tile,
              showLabel: false,
            ),
          )
        : ArtTile(
            imagePath: 'assets/art/silhouettes/$artName',
            color: themeColor,
            deepColor: deepColor,
            size: _tile,
            showLabel: false,
          );

    if (hintThis) {
      content = AnimatedBuilder(
        animation: _idle,
        builder: (context, child) => Transform.scale(
          scale: 1.0 + 0.12 * sin(_idle.value * 2 * pi * 3),
          child: child,
        ),
        child: content,
      );
    }

    return DragTarget<SceneObject>(
      key: _slotKeys[o.slug],
      onWillAcceptWithDetails: (_) => !filled,
      onAcceptWithDetails: (d) => _onDrop(o, d.data),
      builder: (context, candidates, rejected) => Transform.scale(
        scale: candidates.isNotEmpty ? 1.1 : 1.0,
        child: PopIn(delayMs: 100 + 90 * i, child: content),
      ),
    );
  }

  Widget _draggableObject(
      SceneObject o, int i, Color themeColor, Color deepColor) {
    if (_filled.contains(o.slug)) {
      return const SizedBox(width: _tile, height: _tile);
    }
    final tile = ArtTile(
      imagePath: 'assets/art/${o.art}',
      wordHi: o.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: _tile * 0.85,
      showLabel: true,
    );
    return PopIn(
      delayMs: 300 + 90 * i,
      child: IdleBreath(
        phase: i * 1.4,
        amplitude: 0.04,
        child: Draggable<SceneObject>(
          data: o,
          // Speak while dragging (F4): the word travels with the finger.
          onDragStarted: () {
            _nudge.arm();
            widget.session.audio
                .playWord(widget.session.scene.id, o.slug, language: 'hi');
          },
          feedback: Transform.scale(scale: 1.15, child: tile),
          childWhenDragging: Opacity(opacity: 0.25, child: tile),
          child: tile,
        ),
      ),
    );
  }
}
