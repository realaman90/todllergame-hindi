import 'dart:math';

import 'package:flutter/material.dart';

/// A talking Mithu avatar.
///
/// Mithu always has a slow, gentle idle bob + occasional small wing-tilt.
/// While [isPlaying] is true, the beak alternates between open and closed
/// frames at ~120 ms on top of the idle motion.
class MithuTalking extends StatefulWidget {
  final bool isPlaying;
  final double size;

  const MithuTalking({
    super.key,
    required this.isPlaying,
    this.size = 120,
  });

  @override
  State<MithuTalking> createState() => _MithuTalkingState();
}

class _MithuTalkingState extends State<MithuTalking>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _talkController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      duration: const Duration(milliseconds: 3400),
      vsync: this,
    )..repeat();

    _talkController = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );

    if (widget.isPlaying) _talkController.repeat();
  }

  @override
  void didUpdateWidget(covariant MithuTalking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _talkController.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _talkController.stop();
      _talkController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _talkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, child) {
        final bob = 5.0 * sin(_idleController.value * 2 * pi);
        final tilt = 0.05 * sin(_idleController.value * 2 * pi + 1.2);
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(angle: tilt, child: child),
        );
      },
      child: AnimatedBuilder(
        animation: _talkController,
        builder: (context, child) {
          final isTalkFrame = widget.isPlaying && _talkController.value < 0.5;
          return ClipOval(
            child: Image.asset(
              isTalkFrame
                  ? 'assets/art/characters/mithu_hero_talk.png'
                  : 'assets/art/characters/mithu_hero.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
