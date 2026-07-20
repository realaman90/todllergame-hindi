import 'dart:math';

import 'package:flutter/material.dart';

/// A talking Mithu avatar.
///
/// While [isPlaying] is true, the beak alternates between open and closed
/// frames at ~120 ms and a tiny bob plays. When silent, the still frame is
/// shown.
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 240),
      vsync: this,
    );
    if (widget.isPlaying) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MithuTalking oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bob = widget.isPlaying ? 3.0 * sin(_controller.value * 2 * pi) : 0.0;
        final isTalkFrame = widget.isPlaying && _controller.value < 0.5;
        return Transform.translate(
          offset: Offset(0, bob),
          child: ClipOval(
            child: Image.asset(
              isTalkFrame
                  ? 'assets/art/characters/mithu_hero_talk.png'
                  : 'assets/art/characters/mithu_hero.png',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
