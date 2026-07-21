import 'dart:math';

import 'package:flutter/material.dart';

/// Idle life for any tile or card (feel rule F9): a gentle layered-sine
/// breathing pulse. Give each sibling a different [phase] — lockstep
/// wiggling reads as mechanical, offset phases read as alive.
class IdleBreath extends StatefulWidget {
  final Widget child;

  /// Per-item phase offset in radians (e.g. `index * 1.3`).
  final double phase;
  final double amplitude;
  final int periodMs;

  const IdleBreath({
    super.key,
    required this.child,
    this.phase = 0,
    this.amplitude = 0.05,
    this.periodMs = 3000,
  });

  @override
  State<IdleBreath> createState() => _IdleBreathState();
}

class _IdleBreathState extends State<IdleBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        duration: Duration(milliseconds: widget.periodMs), vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1.0 +
            widget.amplitude * sin(_c.value * 2 * pi + widget.phase),
        child: child,
      ),
      child: RepaintBoundary(child: widget.child),
    );
  }
}
