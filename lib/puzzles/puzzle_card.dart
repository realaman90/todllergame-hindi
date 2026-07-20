import 'package:flutter/material.dart';
import '../audio/audio.dart';
import '../content/content.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// A candidate card in the find-it puzzle.
///
/// Wrong taps trigger a gentle idle wobble; correct taps trigger a small
/// celebration bounce and report their global bounds via [onSolved].
/// The celebration SFX is handled by the puzzle overlay after Mithu's praise.
class PuzzleCard extends StatefulWidget {
  final Scene scene;
  final SceneObject object;
  final bool isTarget;
  final AudioService audio;
  final ValueChanged<Rect> onSolved;
  final VoidCallback onWrong;

  const PuzzleCard({
    super.key,
    required this.scene,
    required this.object,
    required this.isTarget,
    required this.audio,
    required this.onSolved,
    required this.onWrong,
  });

  @override
  State<PuzzleCard> createState() => _PuzzleCardState();
}

class _PuzzleCardState extends State<PuzzleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<double>? _animation;
  AnimationType _type = AnimationType.wobble;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _setAnimation(AnimationType.wobble);
  }

  void _setAnimation(AnimationType type) {
    _type = type;
    _animation = switch (type) {
      AnimationType.wobble => TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween(begin: 0.0, end: -0.1),
            weight: 25,
          ),
          TweenSequenceItem(
            tween: Tween(begin: -0.1, end: 0.1),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween(begin: 0.1, end: 0.0),
            weight: 25,
          ),
        ]).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        )),
      AnimationType.celebrate => TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
        ]).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.elasticOut,
        )),
    };
  }

  void _handleTap() {
    if (_celebrating) return;
    widget.audio.playSfx('tap_pop');

    if (widget.isTarget) {
      _celebrating = true;
      _setAnimation(AnimationType.celebrate);
      _controller.forward(from: 0.0).whenCompleteOrCancel(() {
        if (!mounted) return;
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          widget.onSolved(box.localToGlobal(Offset.zero) & box.size);
        } else {
          widget.onSolved(Rect.zero);
        }
      });
    } else {
      _setAnimation(AnimationType.wobble);
      _controller.forward(from: 0.0);
      widget.onWrong();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.forTheme(widget.scene.theme);
    final deepColor = AppColors.deepFor(widget.scene.theme);

    Widget tile = ArtTile(
      imagePath: 'assets/art/${widget.object.art}',
      wordHi: widget.object.wordHi,
      color: themeColor,
      deepColor: deepColor,
      size: 88,
      showLabel: false,
    );

    if (_animation != null) {
      tile = AnimatedBuilder(
        animation: _animation!,
        builder: (context, child) {
          if (_type == AnimationType.wobble) {
            return Transform.rotate(
              angle: _animation!.value,
              child: child,
            );
          }
          return Transform.scale(
            scale: _animation!.value,
            child: child,
          );
        },
        child: tile,
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: tile,
    );
  }
}

enum AnimationType { wobble, celebrate }
