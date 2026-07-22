import 'dart:math';

import 'package:flutter/material.dart';

import '../../content/content.dart';
import '../../juice/juice.dart';
import '../../theme/theme.dart';
import '../../widgets/widgets.dart';
import '../activity.dart';

/// चिपकाओ! (Sticker free-play, format #36): a creative breather with a
/// purpose she chooses herself — drag stickers anywhere on the canvas.
/// Every placed sticker speaks its word and stays put. Four placements
/// earn the round (skip is always there); no wrong exists at all.
class StickerPlayActivity extends Activity {
  const StickerPlayActivity();

  @override
  String get id => 'stickerplay';

  @override
  String get titleHi => 'चिपकाओ!';

  @override
  Widget build(BuildContext context, ActivitySession session) {
    return StickerPlayBody(session: session, key: UniqueKey());
  }
}

class _Placed {
  final SceneObject object;
  final Offset at;
  final double tilt;

  const _Placed(this.object, this.at, this.tilt);
}

class StickerPlayBody extends StatefulWidget {
  final ActivitySession session;

  const StickerPlayBody({super.key, required this.session});

  @override
  State<StickerPlayBody> createState() => _StickerPlayBodyState();
}

class _StickerPlayBodyState extends State<StickerPlayBody> {
  static const _toEarn = 4;

  late final List<SceneObject> _tray;
  final List<_Placed> _placed = [];
  final _rng = Random();
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    // Her earned stickers lead the tray; session vocab fills the rest.
    final earned = <SceneObject>[];
    final stickers = widget.session.stickers;
    if (stickers != null) {
      for (final o in widget.session.scene.objects) {
        if (stickers.has(o.slug)) earned.add(o);
      }
    }
    final rest = widget.session.vocab
        .where((o) => !earned.any((e) => e.slug == o.slug))
        .toList();
    _tray = [...earned, ...rest].take(6).toList();
    widget.session.audio.playHost('mithu_game_stickerplay');
  }

  void _place(SceneObject o, Offset globalPos) {
    final box = context.findRenderObject();
    if (box is! RenderBox || _finishing) return;
    final local = box.globalToLocal(globalPos);
    setState(() {
      _placed.add(_Placed(
        o,
        local,
        (_rng.nextDouble() - 0.5) * 0.24,
      ));
    });
    widget.session.audio.playTapNote();
    widget.session.audio
        .playWord(widget.session.scene.id, o.slug, language: 'hi');
    if (_placed.length >= _toEarn && !_finishing) {
      _finishing = true;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) widget.session.onComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = widget.session.scene;
    final themeColor = AppColors.forTheme(scene.theme);
    final deepColor = AppColors.deepFor(scene.theme);
    final s = uiScale(context);

    return DragTarget<SceneObject>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _place(d.data, d.offset),
      builder: (context, candidates, rejected) => Stack(children: [
        // Placed stickers live on the canvas, tappable to hear again.
        for (final p in _placed)
          Positioned(
            left: p.at.dx - 40 * s,
            top: p.at.dy - 40 * s,
            child: Transform.rotate(
              angle: p.tilt,
              child: PopIn(
                child: ArtTile(
                  imagePath: 'assets/art/${p.object.art}',
                  color: themeColor,
                  deepColor: deepColor,
                  size: 80,
                  showLabel: false,
                  onTap: () => widget.session.audio.playWord(
                      scene.id, p.object.slug,
                      language: 'hi'),
                ),
              ),
            ),
          ),
        // Sticker tray along the bottom.
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 10 * s),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 14 * s, vertical: 8 * s),
              decoration: BoxDecoration(
                color: AppColors.paper2.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _tray.length; i++) ...[
                    _trayTile(_tray[i], i, themeColor, deepColor),
                    if (i < _tray.length - 1) SizedBox(width: 14 * s),
                  ],
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _trayTile(
      SceneObject o, int i, Color themeColor, Color deepColor) {
    final tile = ArtTile(
      imagePath: 'assets/art/${o.art}',
      color: themeColor,
      deepColor: deepColor,
      size: 66,
      showLabel: false,
    );
    return PopIn(
      delayMs: 80 * i,
      child: IdleBreath(
        phase: i * 1.2,
        amplitude: 0.04,
        child: Draggable<SceneObject>(
          data: o,
          onDragStarted: () => widget.session.audio
              .playWord(widget.session.scene.id, o.slug, language: 'hi'),
          feedback: Transform.scale(scale: 1.25, child: tile),
          childWhenDragging: Opacity(opacity: 0.35, child: tile),
          child: tile,
        ),
      ),
    );
  }
}
